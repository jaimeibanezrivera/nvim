local data = require("hg_graph.data")
local diff = require("hg_graph.diff")
local file = require("hg_graph.file")
local filter = require("hg_graph.filter")
local icons = require("hg_graph.icons")

local M = {}

local NS = vim.api.nvim_create_namespace("hg_graph_float")

function M.define_highlights()
    vim.api.nvim_set_hl(0, "HgGraphFloatAdded", { fg = "#2f9e44", ctermfg = 2, default = true })
    vim.api.nvim_set_hl(0, "HgGraphFloatDeleted", { fg = "#e03131", ctermfg = 1, default = true })
    vim.api.nvim_set_hl(0, "HgGraphFloatBinary", { link = "Special", default = true })
    vim.api.nvim_set_hl(0, "HgGraphFloatLabel", { link = "Comment", default = true })
    vim.api.nvim_set_hl(0, "HgGraphFloatAction", { link = "Special", default = true })
end

local function file_stats_line(file)
    if file.binary then
        return "bin"
    end
    if file.added == nil and file.deleted == nil then
        return ""
    end
    local parts = {}
    if file.added and file.added > 0 then
        parts[#parts + 1] = "+" .. file.added
    end
    if file.deleted and file.deleted > 0 then
        parts[#parts + 1] = "-" .. file.deleted
    end
    return table.concat(parts, " ")
end

function M.ensure_buf(state)
    if state.float_buf and vim.api.nvim_buf_is_valid(state.float_buf) then
        return state.float_buf
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].filetype = "hggraphfloat"
    vim.b[buf].hg_graph_float = true
    state.float_buf = buf
    M.setup_buffer(buf)
    return buf
end

function M.close(state)
    if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
        pcall(vim.api.nvim_win_close, state.float_win, true)
    end
    state.float_win = nil
end

---@param graph_win number
---@param opts { width: integer, max_height: integer, min_height: integer, side_offset: integer }
---@return integer row, integer col, integer width, integer height
function M.layout(graph_win, opts)
    local graph_w = vim.api.nvim_win_get_width(graph_win)
    local graph_h = vim.api.nvim_win_get_height(graph_win)
    local width = math.min(opts.width, math.max(28, graph_w - 4))
    local height = math.min(opts.max_height, math.max(opts.min_height, math.floor(graph_h * 0.78)))

    local cursor_row = 0
    vim.api.nvim_win_call(graph_win, function()
        local cursor = vim.api.nvim_win_get_cursor(0)[1]
        local top = vim.fn.line("w0")
        cursor_row = math.max(0, cursor - top)
    end)

    local row = math.max(0, math.min(cursor_row, graph_h - height))
    local col = math.max(0, graph_w - width - (opts.side_offset or 1))

    return row, col, width, height
end

function M.open_at(graph_win, state, opts)
    local buf = M.ensure_buf(state)
    local row, col, width, height = M.layout(graph_win, opts)

    local win_cfg = {
        relative = "win",
        win = graph_win,
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        focusable = true,
        zindex = 250,
        title = " changeset ",
        title_pos = "center",
    }

    if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
        vim.api.nvim_win_set_config(state.float_win, win_cfg)
    else
        state.float_win = vim.api.nvim_open_win(buf, false, win_cfg)
        vim.wo[state.float_win].number = false
        vim.wo[state.float_win].relativenumber = false
        vim.wo[state.float_win].wrap = true
        vim.wo[state.float_win].cursorline = true
        vim.wo[state.float_win].signcolumn = "no"
        vim.wo[state.float_win].winblend = 0
    end

    return buf
end

function M.set_lines(buf, lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.b[buf].hg_graph_files = nil
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
end

function M.loading(buf, rev)
    M.set_lines(buf, { "Loading " .. rev .. "…" })
end

local function format_commit_date(raw)
    raw = vim.trim(raw or "")
    if raw == "" then
        return "—"
    end
    return raw
end

function M.render(buf, commit, files, root)
    local topic = filter.topic_label({ topic = commit.topic, branch = commit.branch })
    local lines = {
        string.format("Changeset  %s:%s", commit.rev, commit.short_node),
        string.format("Topic      %s     Phase  %s", topic, commit.phase or ""),
        string.format("%s  %s", icons.author, commit.author),
        string.format("%s  %s", icons.date, format_commit_date(commit.date)),
        "",
    }

    local desc = (commit.description or ""):match("^[^\n]*") or ""
    if desc ~= "" then
        lines[#lines + 1] = desc
        lines[#lines + 1] = ""
    end

    lines[#lines + 1] = icons.file .. " Changed files"
    local changed_files_row = #lines
    lines[#lines + 1] = table.concat({
        icons.diff .. " Enter  diff vs parent",
        icons.open .. " O  open @ commit",
        icons.worktree .. " gf  open on disk",
    }, "    ")
    local changed_files_legend_row = #lines
    lines[#lines + 1] = ""

    local file_rows = {}
    local parent = commit.parents[1]

    if #files == 0 then
        lines[#lines + 1] = "  (none)"
    else
        for _, file in ipairs(files) do
            local base = string.format(" %s %s", file.status, file.path)
            local suffix, stat_hls = "", {}
            if file.binary then
                suffix = "  bin"
                stat_hls[#stat_hls + 1] = { #base + 2, #base + 4, "HgGraphFloatBinary" }
            else
                local parts = {}
                if file.added and file.added > 0 then
                    parts[#parts + 1] = "+" .. file.added
                end
                if file.deleted and file.deleted > 0 then
                    parts[#parts + 1] = "-" .. file.deleted
                end
                if #parts > 0 then
                    suffix = "  " .. table.concat(parts, " ")
                    local col = #base + 2
                    for _, part in ipairs(parts) do
                        local hl = vim.startswith(part, "+") and "HgGraphFloatAdded" or "HgGraphFloatDeleted"
                        stat_hls[#stat_hls + 1] = { col, col + #part, hl }
                        col = col + #part + 1
                    end
                end
            end

            lines[#lines + 1] = base .. suffix
            file_rows[#file_rows + 1] = {
                line = #lines,
                rev = commit.rev,
                parent = parent,
                path = file.path,
                label = commit.short_node,
                parent_label = parent and tostring(parent) or nil,
                stat_hls = stat_hls,
            }
        end
    end

    M.define_highlights()

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.b[buf].hg_root = root
    vim.b[buf].hg_graph_files = file_rows
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

    for lnum = 0, 3 do
        vim.api.nvim_buf_add_highlight(buf, NS, "HgGraphFloatLabel", lnum, 0, -1)
    end
    vim.api.nvim_buf_add_highlight(buf, NS, "HgGraphFloatLabel", changed_files_row - 1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, NS, "HgGraphFloatAction", changed_files_legend_row - 1, 0, -1)

    for _, row in ipairs(file_rows) do
        local lnum = row.line - 1
        vim.api.nvim_buf_add_highlight(buf, NS, "Special", lnum, 1, 2)
        for _, span in ipairs(row.stat_hls or {}) do
            vim.api.nvim_buf_add_highlight(buf, NS, span[3], lnum, span[1], span[2])
        end
    end
end

function M.error(buf, message)
    M.set_lines(buf, { "Error:", message })
end

function M.file_at_cursor(buf)
    local rows = vim.b[buf].hg_graph_files
    if not rows then
        return
    end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    for _, row in ipairs(rows) do
        if row.line == line then
            return row
        end
    end
end

local function leave_and_run(run)
    require("hg_graph").close()
    vim.schedule(run)
end

local function file_row_at_cursor(buf)
    local row = M.file_at_cursor(buf)
    if not row then
        vim.notify("No file on this line", vim.log.levels.WARN)
        return nil
    end
    local root = vim.b[buf].hg_root
    if not root then
        return nil
    end
    return row, root
end

function M.open_file_at_cursor(buf)
    local row, root = file_row_at_cursor(buf)
    if not row then
        return
    end
    local rev, parent, path = row.rev, row.parent, row.path
    local label, parent_label = row.label, row.parent_label
    leave_and_run(function()
        diff.open_file_diff(root, rev, parent, path, label, parent_label)
    end)
end

function M.open_rev_file_at_cursor(buf)
    local row, root = file_row_at_cursor(buf)
    if not row then
        return
    end
    local rev, path, label = row.rev, row.path, row.label
    leave_and_run(function()
        file.open_at_rev(root, rev, path, label)
    end)
end

function M.open_worktree_file_at_cursor(buf)
    local row, root = file_row_at_cursor(buf)
    if not row then
        return
    end
    local path = row.path
    leave_and_run(function()
        file.open_worktree(root, path)
    end)
end

function M.load(root, rev, graph_win, state, opts, generation, get_generation)
    local buf = M.open_at(graph_win, state, opts)

    if state.float_cache[rev] then
        local cached = state.float_cache[rev]
        if cached.error then
            M.error(buf, cached.error)
        else
            M.render(buf, cached.commit, cached.files, root)
            require("hg_graph").on_float_ready()
        end
        return
    end

    M.loading(buf, rev)

    data.load_details_async(root, rev, function(result)
        if generation ~= get_generation() then
            return
        end
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end

        if result.error then
            state.float_cache[rev] = { error = result.error }
            M.error(buf, result.error)
            return
        end

        state.float_cache[rev] = { commit = result.commit, files = result.files }
        require("hg_graph").persist_session_cache()
        if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
            M.open_at(graph_win, state, opts)
        end
        M.render(buf, result.commit, result.files, root)
        require("hg_graph").on_float_ready()
    end)
end

function M.setup_buffer(buf)
    local map_opts = { buffer = buf, silent = true }

    vim.keymap.set("n", "q", function()
        require("hg_graph").close()
    end, vim.tbl_extend("force", map_opts, { desc = "Close hg graph", nowait = true }))

    vim.keymap.set("n", "<Esc>", function()
        require("hg_graph").close_float()
    end, vim.tbl_extend("force", map_opts, { desc = "Close info popup" }))

    vim.keymap.set("n", "<CR>", function()
        M.open_file_at_cursor(buf)
    end, vim.tbl_extend("force", map_opts, { desc = "Diff file against parent" }))

    vim.keymap.set("n", "O", function()
        M.open_rev_file_at_cursor(buf)
    end, vim.tbl_extend("force", map_opts, { desc = "Open file at revision" }))

    vim.keymap.set("n", "gf", function()
        M.open_worktree_file_at_cursor(buf)
    end, vim.tbl_extend("force", map_opts, { desc = "Open file in working tree" }))

    vim.keymap.set("n", "<Tab>", function()
        require("hg_graph").toggle_pane()
    end, vim.tbl_extend("force", map_opts, { desc = "Toggle graph / info popup" }))
end

return M
