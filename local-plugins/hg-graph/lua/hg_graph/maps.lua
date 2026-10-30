local data = require("hg_graph.data")
local diff = require("hg_graph.diff")
local filter = require("hg_graph.filter")
local icons = require("hg_graph.icons")

local M = {}

local function revision_on_line(line)
    return line:match("(%d+):[%da-fA-F]+")
end

function M.revision_at_cursor(buf, win)
    win = win or vim.fn.bufwinid(buf)
    if win <= 0 then
        return
    end

    local header_rows = vim.b[buf].hg_graph_header_rows or 0
    local row = vim.api.nvim_win_get_cursor(win)[1]
    if row <= header_rows then
        row = header_rows + 1
    end

    for current = row, header_rows + 1, -1 do
        local line = vim.api.nvim_buf_get_lines(buf, current - 1, current, false)[1] or ""
        local revision = revision_on_line(line)
        if revision then
            return revision, tonumber(revision)
        end
    end
end

function M.open_changeset(root, buf, win, leave)
    win = win or vim.fn.bufwinid(buf)
    local revision = M.revision_at_cursor(buf, win)
    if not revision then
        vim.notify("No revision on this line", vim.log.levels.WARN)
        return
    end
    local cmd = string.format(
        "DiffviewOpen %s -C%s",
        string.format("p1(%s)::%s", revision, revision),
        vim.fn.fnameescape(root)
    )
    if leave then
        require("hg_graph").close()
        vim.schedule(function()
            vim.cmd(cmd)
        end)
    else
        vim.cmd(cmd)
    end
end

function M.pick_file_diff(root, buf)
    local revision, rev_n = M.revision_at_cursor(buf)
    if not revision then
        vim.notify("No revision on this line", vim.log.levels.WARN)
        return
    end

    vim.notify("Loading files…", vim.log.levels.INFO)
    vim.schedule(function()
        local commit = select(1, data.commit_at_rev(root, revision))
        if not commit then
            vim.notify("Could not read changeset", vim.log.levels.ERROR)
            return
        end
        local files = select(1, data.changed_files(root, revision))
        if #files == 0 then
            vim.notify("No file changes in this changeset", vim.log.levels.INFO)
            return
        end

        local labels = {}
        for _, file in ipairs(files) do
            local stats = ""
            if file.binary then
                stats = " (bin)"
            elseif file.added or file.deleted then
                stats = string.format(" (+%d/-%d)", file.added or 0, file.deleted or 0)
            end
            labels[#labels + 1] = file.status .. " " .. file.path .. stats
        end

        vim.ui.select(labels, { prompt = "Diff against parent" }, function(choice, idx)
            if not choice or not idx then
                return
            end
            local file = files[idx]
            local parent = commit.parents[1]
            diff.open_file_diff(
                root,
                rev_n,
                parent,
                file.path,
                commit.short_node,
                parent and tostring(parent) or "empty"
            )
        end)
    end)
end

function M.show_help()
    vim.notify(
        table.concat({
            "GRAPH: " .. icons.close .. " q quit",
            icons.changeset .. " Enter/o open commit",
            icons.info .. " Tab file popup",
            icons.filter .. " f filter",
            icons.more .. " + more",
            icons.refresh .. " r refresh",
            "",
            "POPUP: " .. icons.diff .. " Enter diff",
            icons.open .. " O @ commit",
            icons.worktree .. " gf on disk",
            icons.info .. " Tab back",
        }, "\n"),
        vim.log.levels.INFO
    )
end

function M.pick_topic_filter(root, commit_meta, on_apply)
    vim.schedule(function()
        local seen = {}
        local names = {}
        for _, info in pairs(commit_meta or {}) do
            local name = filter.topic_label(info)
            if name ~= "" and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
        table.sort(names)

        if #names == 0 then
            names = data.topic_names(root, 300)
        end

        local current = data.current_topic_name(root)
        local labels = { "All topics (clear filter)" }
        local label_to_name = { ["All topics (clear filter)"] = false }

        for _, name in ipairs(names) do
            local label = name
            if current and name == current then
                label = name .. "  (current)"
            end
            labels[#labels + 1] = label
            label_to_name[label] = name
        end

        vim.ui.select(labels, { prompt = "Topic filter" }, function(choice)
            if choice == nil then
                return
            end
            local picked = label_to_name[choice]
            if picked == false then
                on_apply(nil)
            else
                on_apply(picked)
            end
        end)
    end)
end

function M.setup(buf, root, opts)
    opts = opts or {}
    local map_opts = { buffer = buf, silent = true }

    vim.keymap.set("n", "q", function()
        require("hg_graph").close()
    end, vim.tbl_extend("force", map_opts, { desc = "Close hg graph", nowait = true }))

    vim.keymap.set("n", "o", function()
        M.open_changeset(root, buf, nil, true)
    end, vim.tbl_extend("force", map_opts, { desc = "Open changeset in Diffview" }))

    if opts.open_changeset_and_leave then
        vim.keymap.set("n", "<CR>", opts.open_changeset_and_leave, vim.tbl_extend("force", map_opts, { desc = "Open changeset in Diffview" }))
    end

    if opts.toggle_pane then
        vim.keymap.set("n", "<Tab>", opts.toggle_pane, vim.tbl_extend("force", map_opts, { desc = "Toggle info popup" }))
    end

    vim.keymap.set("n", "d", function()
        M.pick_file_diff(root, buf)
    end, vim.tbl_extend("force", map_opts, { desc = "Diff one file against parent" }))

    if opts.topic_filter then
        vim.keymap.set("n", "f", opts.topic_filter, vim.tbl_extend("force", map_opts, { desc = "Filter by topic" }))
    end

    if opts.load_more then
        vim.keymap.set("n", "+", opts.load_more, vim.tbl_extend("force", map_opts, { desc = "Load more commits" }))
        vim.keymap.set("n", "=", opts.load_more, vim.tbl_extend("force", map_opts, { desc = "Load more commits" }))
    end

    if opts.refresh then
        vim.keymap.set("n", "r", opts.refresh, vim.tbl_extend("force", map_opts, { desc = "Refresh log" }))
    end

    vim.keymap.set("n", "?", function()
        M.show_help()
    end, vim.tbl_extend("force", map_opts, { desc = "Show keymaps" }))
end

return M
