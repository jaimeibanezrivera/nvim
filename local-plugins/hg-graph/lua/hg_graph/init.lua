local M = {}

local state = {
    win = nil,
    buf = nil,
    generation = 0,
}

local defaults = {
    title = "hg graph",
    revset = "wip or last(::., 150)",
}

local config = vim.deepcopy(defaults)

local function find_hg_root()
    local file = vim.api.nvim_buf_get_name(0)
    if file ~= "" then
        local root = vim.fs.root(file, ".hg")
        if root then
            return root
        end
    end

    return vim.fs.root(vim.fn.getcwd(), ".hg")
end

local function strip_ansi(text)
    text = text:gsub("\27%[[%d;?]*[A-Za-z]", "")
    text = text:gsub("\27%]%d;.-\7", "")
    text = text:gsub("\27%[[%d;]*m", "")
    return text
end

local function graph_style()
    return config.style
        or vim.fs.joinpath(vim.fn.stdpath("config"), "local-plugins", "hg-graph", "hg", "graph.style")
end

function M.close()
    local win = state.win
    local buf = state.buf
    state.win = nil
    state.buf = nil
    state.generation = state.generation + 1

    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        return true
    end

    if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return true
    end

    return false
end

local function find_here_line(output)
    local row = 0
    local at_row

    for line in vim.gsplit(output, "\n", { plain = true }) do
        row = row + 1
        local plain = strip_ansi(line)
        if plain:find("<==", 1, true) then
            return math.max(1, row - 1)
        end
        if not at_row and plain:match("^@") then
            at_row = row
        end
    end

    return at_row or 1
end

local function revision_from_line(line)
    return strip_ansi(line):match("(%d+):[%da-fA-F]+")
end

local function revision_at_cursor(buf, row)
    local last = vim.api.nvim_buf_line_count(buf)
    for current = row, math.max(1, row - 12), -1 do
        if current > last then
            break
        end
        local line = vim.api.nvim_buf_get_lines(buf, current - 1, current, false)[1]
        local revision = line and revision_from_line(line)
        if revision then
            return revision
        end
    end
end

local function open_revision(root)
    local buf = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local revision = revision_at_cursor(buf, row)

    if not revision then
        vim.notify("No Mercurial revision found on this line", vim.log.levels.WARN)
        return
    end

    vim.cmd(string.format(
        "DiffviewOpen %s -C%s",
        string.format("p1(%s)::%s", revision, revision),
        vim.fn.fnameescape(root)
    ))
end

function M.toggle(opts)
    opts = vim.tbl_deep_extend("force", {}, config, opts or {})

    if M.close() and not opts.force then
        return
    end

    local root = find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    local style = graph_style()
    if vim.fn.filereadable(style) == 0 then
        vim.notify("Missing Mercurial graph style: " .. style, vim.log.levels.ERROR)
        return
    end

    state.generation = state.generation + 1
    local generation = state.generation
    vim.notify("Loading Mercurial graph…")

    local ident = vim.system({
        "hg",
        "--cwd",
        root,
        "log",
        "-r",
        ".",
        "-T",
        "{branch}{ifeq(topic, '', '', ' / {topic}')} @ {rev}:{node|short} ({phase})",
    }, { text = true }):wait()

    local here = vim.trim(ident.stdout or "")
    if ident.code ~= 0 or here == "" then
        here = root
    end

    vim.system({
        "hg",
        "--cwd",
        root,
        "--color",
        "always",
        "--pager",
        "off",
        "log",
        "--graph",
        "-r",
        opts.revset,
        "--style",
        style,
    }, { text = true }, function(result)
        vim.schedule(function()
            if generation ~= state.generation then
                return
            end

            if result.code ~= 0 then
                vim.notify(
                    "Mercurial graph failed: " .. vim.trim(result.stderr or ""),
                    vim.log.levels.ERROR
                )
                return
            end

            local output = result.stdout or ""
            local width = math.max(40, math.floor(vim.o.columns * 0.92))
            local height = math.max(10, math.floor(vim.o.lines * 0.85))
            local buf = vim.api.nvim_create_buf(false, true)
            vim.bo[buf].bufhidden = "wipe"
            vim.b[buf].hg_root = root

            local win = vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width = width,
                height = height,
                row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
                col = math.max(0, math.floor((vim.o.columns - width) / 2)),
                style = "minimal",
                border = "rounded",
                title = " " .. opts.title .. " — " .. here .. " ",
                title_pos = "center",
            })

            state.win = win
            state.buf = buf

            vim.wo[win].wrap = false
            vim.wo[win].number = false
            vim.wo[win].relativenumber = false
            vim.wo[win].signcolumn = "no"
            vim.wo[win].cursorline = true
            vim.wo[win].scrolloff = 3

            local chan = vim.api.nvim_open_term(buf, {})
            local header = table.concat({
                "\27[1m" .. here .. "\27[0m",
                "q close   <CR> diff   / search   drafts are red   you are @ and <==",
                "",
            }, "\r\n")
            vim.api.nvim_chan_send(chan, header .. "\r\n" .. output:gsub("\n", "\r\n"))

            vim.keymap.set("n", "q", M.close, {
                buffer = buf,
                nowait = true,
                desc = "Close Mercurial graph",
            })
            vim.keymap.set("n", "<CR>", function()
                open_revision(root)
            end, {
                buffer = buf,
                desc = "Open selected Mercurial revision in Diffview",
            })

            vim.api.nvim_create_autocmd("WinClosed", {
                once = true,
                callback = function(event)
                    if tonumber(event.match) == win then
                        state.win = nil
                        state.buf = nil
                        state.generation = state.generation + 1
                    end
                end,
            })

            local target = find_here_line(output) + 3
            vim.defer_fn(function()
                if not vim.api.nvim_win_is_valid(win) then
                    return
                end
                vim.cmd("stopinsert")
                local last = vim.api.nvim_buf_line_count(buf)
                pcall(vim.api.nvim_win_set_cursor, win, { math.min(target, last), 0 })
                pcall(vim.cmd, "normal! zz")
            end, 60)
        end)
    end)
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
