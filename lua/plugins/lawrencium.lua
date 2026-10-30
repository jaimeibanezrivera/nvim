local function close_win_by(predicate)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if predicate(buf, win) then
            vim.api.nvim_win_close(win, true)
            return true
        end
    end

    return false
end

local function close_preview_by(predicate)
    return close_win_by(function(buf, win)
        local is_preview = vim.api.nvim_get_option_value("previewwindow", { win = win })
        return is_preview and predicate(buf, win)
    end)
end

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

local function ensure_lawrencium_commands()
    if vim.fn.exists(":Hglog") == 2 then
        return true
    end

    pcall(vim.fn["lawrencium#setup_buffer_commands"])
    if vim.fn.exists(":Hglog") == 2 then
        return true
    end

    local root = find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return false
    end

    vim.b.mercurial_dir = root
    vim.fn["lawrencium#define_commands"]()
    if vim.fn.exists(":Hglog") == 2 then
        return true
    end

    vim.notify("Lawrencium Hglog command is not available", vim.log.levels.ERROR)
    return false
end

local function toggle_hg_log(command)
    local closed = close_preview_by(function(buf)
        return vim.api.nvim_get_option_value("filetype", { buf = buf }) == "hglog"
    end)

    if closed then
        return
    end

    if not ensure_lawrencium_commands() then
        return
    end

    vim.cmd(command)
end

local function strip_ansi(text)
    text = text:gsub("\27%[[%d;?]*[A-Za-z]", "")
    text = text:gsub("\27%]%d;.-\7", "")
    text = text:gsub("\27%[[%d;]*m", "")
    return text
end

local function crecord_relative_from_text(text, root)
    text = vim.trim(text)
    if text == "" then
        return nil
    end

    local git = text:match("^diff %-%-git a/(.+) b/")
    if git then
        return git
    end

    local diff_r = text:match("^diff %-r%s+%S+%s+(.+)$")
    if diff_r then
        diff_r = vim.trim(diff_r:gsub("^%-r%s+%S+%s+", ""))
        if diff_r ~= "" then
            return diff_r
        end
    end

    if vim.fn.filereadable(vim.fs.joinpath(root, text)) == 1 then
        return text
    end

    for token in text:gmatch("%S+") do
        if vim.fn.filereadable(vim.fs.joinpath(root, token)) == 1 then
            return token
        end
    end
end

local function crecord_file_from_line(line, root)
    local raw = line or ""
    local plain = vim.trim(strip_ansi(raw))
    if plain == "" or plain:find("%[x%]=selected", 1, true) then
        return nil
    end

    local rest = plain:match("^%[.%]%*%*[mad]?%s+(.*)$") or plain:match("^%[.%]%s+(.*)$")
    if not rest then
        rest = plain
    end

    rest = vim.trim(rest)
    if rest:find("^@@") or rest:match("^[+%-]") then
        return nil
    end

    return crecord_relative_from_text(rest, root)
end

local function line_is_crecord_selected(line)
    return (line or ""):find("\27%[[0-9;]*7m", 1) ~= nil
end

local hg_interactive_state = {
    win = nil,
    prev_win = nil,
    suppress_exit = false,
}

local open_hg_interactive

local function crecord_scan_rows(root, each)
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    local selected
    for r, line in ipairs(lines) do
        if line_is_crecord_selected(line) then
            selected = r
        end
    end

    local starts = {}
    if selected then
        starts[#starts + 1] = selected
    end
    starts[#starts + 1] = row
    starts[#starts + 1] = #lines

    local seen = {}
    for _, start in ipairs(starts) do
        for r = start, 1, -1 do
            if not seen[r] then
                seen[r] = true
                local result = each(lines[r], r, start)
                if result then
                    return result
                end
            end
        end
    end
end

local function crecord_relative_under_cursor(root)
    return crecord_scan_rows(root, function(line)
        return crecord_file_from_line(line, root)
    end)
end

local function crecord_visible_text(line)
    local plain = vim.trim(strip_ansi(line or ""))
    plain = plain:gsub("^%[.%]%s*", "")
    plain = plain:gsub("^%*%*%s*", "")
    return vim.trim(plain)
end

local function crecord_hunk_header(line)
    return crecord_visible_text(line):match("^(@@ %-%d+[,%d]* %+%d+[,%d]* @@)")
end

local function hunk_key(header)
    return header and header:match("@@ (%-%d+[,%d]* %+%d+[,%d]*) @@")
end

local function parse_hunk_header(header)
    local old_s, old_c, new_s, new_c = header:match("@@ %-(%d+),(%d+) %+(%d+),(%d+) @@")
    if old_s then
        return tonumber(old_s), tonumber(old_c), tonumber(new_s), tonumber(new_c)
    end

    old_s, old_c, new_s = header:match("@@ %-(%d+),(%d+) %+(%d+) @@")
    if old_s then
        return tonumber(old_s), tonumber(old_c), tonumber(new_s), 1
    end

    old_s, new_s, new_c = header:match("@@ %-(%d+) %+(%d+),(%d+) @@")
    if old_s then
        return tonumber(old_s), 1, tonumber(new_s), tonumber(new_c)
    end

    old_s, new_s = header:match("@@ %-(%d+) %+(%d+) @@")
    if old_s then
        return tonumber(old_s), 1, tonumber(new_s), 1
    end
end

local function crecord_drop_target(root)
    local file
    local file_row
    local hunk
    local origin
    local found = crecord_scan_rows(root, function(line, row, start)
        origin = start
        if not hunk then
            hunk = crecord_hunk_header(line)
        end
        if not file then
            file = crecord_file_from_line(line, root)
            if file then
                file_row = row
            end
        end
        if file and (hunk or file_row == start) then
            return true
        end
    end)

    if not found or not file then
        return nil
    end

    if file_row == origin or not hunk then
        return { relative = file, kind = "file" }
    end

    return { relative = file, kind = "hunk", hunk = hunk }
end

local function close_hg_interactive()
    local buf = vim.api.nvim_get_current_buf()
    local prev = hg_interactive_state.prev_win
    local float = hg_interactive_state.win

    hg_interactive_state.suppress_exit = true
    if float and vim.api.nvim_win_is_valid(float) then
        vim.api.nvim_win_close(float, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end

    if prev and vim.api.nvim_win_is_valid(prev) then
        vim.api.nvim_set_current_win(prev)
    end

    return prev
end

local function open_crecord_file(root)
    local relative = crecord_relative_under_cursor(root)
    if not relative then
        vim.notify("No Mercurial file found on this line", vim.log.levels.WARN)
        return
    end

    close_hg_interactive()
    vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(root, relative)))
end

local function path_is_modified_in_nvim(path)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf)
            and vim.api.nvim_buf_get_name(buf) == path
            and vim.bo[buf].modified
        then
            return true
        end
    end
    return false
end

local function reload_path(path)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == path then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent! edit!")
            end)
        end
    end
end

local function extract_hunk_lines(diff, header)
    local want = hunk_key(header)
    if not want then
        return nil
    end

    local hunk_lines = {}
    local capturing = false
    for line in vim.gsplit(diff, "\n", { plain = true }) do
        if line:find("^@@", 1) then
            if capturing then
                break
            end
            if hunk_key(line) == want then
                capturing = true
                hunk_lines[#hunk_lines + 1] = line
            end
        elseif capturing then
            if line:find("^diff ", 1) or line:find("^index ", 1) then
                break
            end
            hunk_lines[#hunk_lines + 1] = line
        end
    end

    if capturing and #hunk_lines > 0 then
        return hunk_lines
    end
end

local function reverse_apply_hunk(path, hunk_lines)
    local old_s, old_c, new_s, new_c = parse_hunk_header(hunk_lines[1] or "")
    if not old_s then
        return false, "Could not parse hunk header"
    end

    local old_body = {}
    local new_body = {}
    for i = 2, #hunk_lines do
        local line = hunk_lines[i]
        local sigil = line:sub(1, 1)
        local text = line:sub(2)
        if sigil == "\\" then
            -- "\\ No newline at end of file"
        elseif sigil == "+" then
            new_body[#new_body + 1] = text
        elseif sigil == "-" then
            old_body[#old_body + 1] = text
        else
            if sigil == " " then
                text = line:sub(2)
            else
                text = line
            end
            old_body[#old_body + 1] = text
            new_body[#new_body + 1] = text
        end
    end

    local lines = vim.fn.readfile(path)
    local start_idx = new_c == 0 and (new_s + 1) or new_s
    if start_idx < 1 then
        start_idx = 1
    end

    for i, expected in ipairs(new_body) do
        if lines[start_idx + i - 1] ~= expected then
            return false, "Working copy no longer matches this hunk"
        end
    end

    local result = {}
    for i = 1, start_idx - 1 do
        result[#result + 1] = lines[i]
    end
    vim.list_extend(result, old_body)
    for i = start_idx + #new_body, #lines do
        result[#result + 1] = lines[i]
    end

    if vim.fn.writefile(result, path) ~= 0 then
        return false, "Failed to write " .. path
    end

    return true
end

local function hg_file_status(root, relative)
    local status_result = vim.system({
        "hg",
        "--cwd",
        root,
        "status",
        "--",
        relative,
    }, { text = true }):wait()
    return vim.trim(status_result.stdout or ""):sub(1, 1)
end

local function hg_has_uncommitted(root)
    local listed = vim.system({
        "hg",
        "--cwd",
        root,
        "status",
        "-mardu",
    }, { text = true }):wait()
    return vim.trim(listed.stdout or "") ~= ""
end

local function reopen_hg_commit(root)
    if not hg_has_uncommitted(root) then
        vim.notify("No uncommitted files")
        return
    end

    open_hg_interactive({
        root = root,
        title = "hg commit -i",
        args = { "commit", "--interactive" },
        footer = " C-o open file  C-x drop ",
        allow_drop = true,
        done_message = "Mercurial commit finished",
        abort_message = "Mercurial commit aborted",
    })
end

local function drop_file_changes(root, relative, status)
    local path = vim.fs.joinpath(root, relative)
    if status == "?" then
        if vim.fn.delete(path) ~= 0 then
            return false, "Failed to delete " .. relative
        end
        return true
    end

    local revert = vim.system({
        "hg",
        "--cwd",
        root,
        "revert",
        "--",
        relative,
    }, { text = true }):wait()
    if revert.code ~= 0 then
        return false, vim.trim(revert.stderr or "Mercurial revert failed")
    end
    return true
end

local function drop_crecord_changes(root)
    local target = crecord_drop_target(root)
    if not target then
        vim.notify("No Mercurial file found on this line", vim.log.levels.WARN)
        return
    end

    local path = vim.fs.joinpath(root, target.relative)
    if path_is_modified_in_nvim(path) then
        vim.notify("Save " .. target.relative .. " before dropping changes", vim.log.levels.WARN)
        return
    end

    local status = hg_file_status(root, target.relative)
    local ok, err

    if target.kind == "hunk" and status ~= "?" then
        local diff = vim.system({
            "hg",
            "--cwd",
            root,
            "diff",
            "--git",
            "--",
            target.relative,
        }, { text = true }):wait()
        if diff.code ~= 0 then
            vim.notify(vim.trim(diff.stderr or "hg diff failed"), vim.log.levels.ERROR)
            return
        end

        local hunk_lines = extract_hunk_lines(diff.stdout or "", target.hunk)
        if not hunk_lines then
            vim.notify("Could not match the selected hunk in hg diff", vim.log.levels.WARN)
            return
        end

        ok, err = reverse_apply_hunk(path, hunk_lines)
    else
        ok, err = drop_file_changes(root, target.relative, status)
    end

    if not ok then
        vim.notify(err or "Failed to drop changes", vim.log.levels.ERROR)
        return
    end

    close_hg_interactive()
    reload_path(path)
    reopen_hg_commit(root)
end

open_hg_interactive = function(opts)
    local win = hg_interactive_state.win
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end

    local root = opts.root or find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    hg_interactive_state.prev_win = vim.api.nvim_get_current_win()
    hg_interactive_state.suppress_exit = false

    local width = math.max(40, math.floor(vim.o.columns * 0.92))
    local height = math.max(10, math.floor(vim.o.lines * 0.85))
    local buf = vim.api.nvim_create_buf(false, false)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buflisted = false
    win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = "minimal",
        border = "rounded",
        title = " " .. opts.title .. " ",
        title_pos = "center",
        footer = opts.footer or " C-o open file ",
        footer_pos = "center",
    })

    hg_interactive_state.win = win
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"

    local argv = { "hg", "--cwd", root }
    vim.list_extend(argv, opts.args)

    vim.fn.jobstart(argv, {
        cwd = root,
        term = true,
        on_exit = function(_, code)
            vim.schedule(function()
                if hg_interactive_state.suppress_exit then
                    hg_interactive_state.suppress_exit = false
                    return
                end

                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end

                if opts.on_exit then
                    opts.on_exit(code)
                elseif code == 0 then
                    vim.notify(opts.done_message or "Mercurial command finished")
                elseif code ~= 0 then
                    vim.notify(opts.abort_message or "Mercurial command aborted", vim.log.levels.WARN)
                end
            end)
        end,
    })

    vim.keymap.set({ "t", "n" }, "<C-o>", function()
        open_crecord_file(root)
    end, { buffer = buf, desc = "Open file under Mercurial cursor" })

    if opts.allow_drop then
        vim.keymap.set({ "t", "n" }, "<C-x>", function()
            drop_crecord_changes(root)
        end, { buffer = buf, desc = "Drop changes in file under Mercurial cursor" })
    end

    vim.api.nvim_create_autocmd("WinClosed", {
        once = true,
        callback = function(event)
            if tonumber(event.match) == win then
                hg_interactive_state.win = nil
            end
        end,
    })

    vim.cmd("startinsert")
end

local function open_hg_commit_interactive()
    open_hg_interactive({
        title = "hg commit -i",
        args = { "commit", "--interactive" },
        footer = " C-o open file  C-x drop ",
        allow_drop = true,
        done_message = "Mercurial commit finished",
        abort_message = "Mercurial commit aborted",
    })
end

local function open_thg_log()
    local root = find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    if vim.fn.executable("thg") == 0 then
        vim.notify("thg is not installed", vim.log.levels.ERROR)
        return
    end

    if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then
        vim.notify(
            "No display available for TortoiseHg; use the in-editor graph instead",
            vim.log.levels.WARN
        )
        return
    end

    vim.fn.jobstart({ "thg", "-R", root, "log" }, { detach = true })
end

local hg_location_cache = { root = nil, time = 0, text = "" }
local hg_location_seq = 0

local function set_hg_location(buf, root, text)
    hg_location_cache = { root = root, time = vim.uv.now(), text = text }
    if vim.api.nvim_buf_is_valid(buf) then
        vim.b[buf].hg_location = text
    end
    pcall(function()
        require("lualine").refresh({ place = { "statusline" } })
    end)
end

local function refresh_hg_location(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local file = vim.api.nvim_buf_get_name(buf)
    local root = (file ~= "" and vim.fs.root(file, ".hg")) or vim.fs.root(vim.fn.getcwd(), ".hg")
    if not root then
        vim.b[buf].hg_location = nil
        return
    end

    local now = vim.uv.now()
    if hg_location_cache.root == root and (now - hg_location_cache.time) < 2000 then
        vim.b[buf].hg_location = hg_location_cache.text
        return
    end

    hg_location_seq = hg_location_seq + 1
    local seq = hg_location_seq
    local parts = { ident = nil, topic = nil }
    local pending = 2

    local function finish()
        pending = pending - 1
        if pending > 0 then
            return
        end

        vim.schedule(function()
            if seq ~= hg_location_seq or not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            local ident = parts.ident
            if not ident then
                return
            end

            local topic = parts.topic or ""
            local text = ident.branch
            if topic ~= "" then
                text = text .. "/" .. topic
            end
            if ident.rev ~= "" then
                text = text .. " " .. ident.rev
            end

            set_hg_location(buf, root, text)
        end)
    end

    vim.system({
        "hg",
        "--cwd",
        root,
        "log",
        "-r",
        ".",
        "-T",
        "{branch}\\t{rev}",
    }, { text = true }, function(result)
        if result.code == 0 then
            local line = vim.trim(result.stdout or "")
            local branch, rev = line:match("^(.-)\t(.*)$")
            if branch then
                parts.ident = { branch = branch, rev = rev }
            elseif line ~= "" then
                parts.ident = { branch = line, rev = "" }
            end
        end
        finish()
    end)

    vim.system({
        "hg",
        "--cwd",
        root,
        "topics",
        "--current",
        "-T",
        "{topic}",
    }, { text = true }, function(result)
        if result.code == 0 then
            parts.topic = vim.trim(result.stdout or "")
        else
            parts.topic = ""
        end
        finish()
    end)
end

local hg_oil_scheme = "oil-hg://"
local hg_oil_registered = false

local function parse_openable_status(stdout, root)
    local files = {}

    for _, line in ipairs(vim.split(vim.trim(stdout), "\n", { plain = true, trimempty = true })) do
        local status, relative = line:match("^([MARC!?I ])%s+(.*)$")
        if relative and relative ~= "" and status ~= "R" and status ~= "!" and status ~= " " then
            local path = vim.fs.joinpath(root, relative)
            files[#files + 1] = {
                relative = relative,
                type = vim.fn.isdirectory(path) == 1 and "directory" or "file",
            }
        end
    end

    return files
end

local function register_hg_oil_adapter()
    if hg_oil_registered then
        return
    end
    hg_oil_registered = true

    local cache = require("oil.cache")
    local files = require("oil.adapters.files")
    local oil_config = require("oil.config")
    local util = require("oil.util")

    local function to_files_url(url)
        if url and vim.startswith(url, hg_oil_scheme) then
            return "oil://" .. url:sub(#hg_oil_scheme + 1)
        end

        return url
    end

    local function to_files_action(action)
        local mapped = vim.deepcopy(action)
        mapped.url = to_files_url(action.url)
        mapped.src_url = to_files_url(action.src_url)
        mapped.dest_url = to_files_url(action.dest_url)
        return mapped
    end

    local adapter = {
        name = "hgstatus",
        list = function(url, _, cb)
            local _, path = util.parse_url(url)
            local root = path:gsub("/+$", "")

            vim.system({ "hg", "--cwd", root, "status" }, { text = true }, function(result)
                vim.schedule(function()
                    if result.code ~= 0 then
                        cb("Mercurial status failed: " .. vim.trim(result.stderr or ""))
                        return
                    end

                    local entries = {}
                    for _, file in ipairs(parse_openable_status(result.stdout or "", root)) do
                        entries[#entries + 1] = cache.create_entry(url, file.relative, file.type)
                    end
                    cb(nil, entries)
                end)
            end)
        end,
        is_modifiable = function()
            return true
        end,
        get_column = function()
            return nil
        end,
        normalize_url = function(url, callback)
            if not vim.endswith(url, "/") then
                url = url .. "/"
            end
            callback(url)
        end,
        get_parent = function(bufname)
            return bufname
        end,
        get_entry_path = function(url, entry, cb)
            local _, path = util.parse_url(url)
            if entry.type == "directory" then
                cb("oil://" .. path .. "/")
            else
                cb(path)
            end
        end,
        render_action = function(action)
            return files.render_action(to_files_action(action))
        end,
        perform_action = function(action, cb)
            files.perform_action(to_files_action(action), cb)
        end,
    }

    oil_config.adapters[hg_oil_scheme] = "hgstatus"
    oil_config.adapter_to_scheme.hgstatus = hg_oil_scheme
    oil_config._adapter_by_scheme[hg_oil_scheme] = adapter

    vim.api.nvim_create_autocmd("BufReadCmd", {
        pattern = "oil-hg://*",
        nested = true,
        callback = function(params)
            require("oil").load_oil_buffer(params.buf)
        end,
    })
end

local function toggle_hg_uncommitted()
    local closed = close_win_by(function(buf)
        return vim.api.nvim_buf_get_name(buf):find("^oil%-hg://", 1) ~= nil
    end)

    if closed then
        return
    end

    local root = find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    local result = vim.system({ "hg", "--cwd", root, "status" }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify(
            "Mercurial status failed: " .. vim.trim(result.stderr or ""),
            vim.log.levels.ERROR
        )
        return
    end

    local files = parse_openable_status(result.stdout or "", root)
    if #files == 0 then
        vim.notify("No uncommitted files", vim.log.levels.INFO)
        return
    end

    register_hg_oil_adapter()

    local height = math.min(#files + 1, math.max(1, math.floor(vim.o.lines * 0.4)))
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.bo[scratch].bufhidden = "wipe"
    local win = vim.api.nvim_open_win(scratch, true, {
        split = "above",
        win = 0,
        height = height,
    })
    vim.wo[win].winfixheight = true

    require("oil").open(hg_oil_scheme .. root .. "/", {}, function()
        if not vim.api.nvim_win_is_valid(win) then
            return
        end

        local buf = vim.api.nvim_win_get_buf(win)
        vim.b[buf].hg_root = root

        local function cursor_uncommitted_file()
            local entry = require("oil").get_cursor_entry()
            if not entry or entry.type == "directory" or not entry.name or entry.name == "" then
                vim.notify("No Mercurial file under cursor", vim.log.levels.WARN)
                return
            end

            return {
                root = vim.b[buf].hg_root or root,
                relative = entry.name,
            }
        end

        vim.keymap.set("n", "q", function()
            vim.api.nvim_win_close(0, true)
        end, { buffer = buf, desc = "Close uncommitted files" })

        vim.keymap.set("n", "<CR>", function()
            require("oil").select({
                handle_buffer_callback = function(filebufnr)
                    local list_win = vim.api.nvim_get_current_win()
                    vim.cmd("wincmd p")
                    vim.api.nvim_set_current_buf(filebufnr)
                    if vim.api.nvim_win_is_valid(list_win) then
                        vim.api.nvim_win_close(list_win, true)
                    end
                end,
            })
        end, { buffer = buf, desc = "Open uncommitted file" })

        vim.keymap.set("n", "d", function()
            local file = cursor_uncommitted_file()
            if not file then
                return
            end

            local status_result = vim.system({
                "hg",
                "--cwd",
                file.root,
                "status",
                "--",
                file.relative,
            }, { text = true }):wait()
            local status = vim.trim(status_result.stdout or ""):sub(1, 1)

            local prompt
            if status == "?" then
                prompt = string.format("Delete untracked file %s?", file.relative)
            else
                prompt = string.format("Revert %s?", file.relative)
            end

            if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
                return
            end

            if status == "?" then
                local path = vim.fs.joinpath(file.root, file.relative)
                if vim.fn.delete(path) ~= 0 then
                    vim.notify("Failed to delete " .. file.relative, vim.log.levels.ERROR)
                    return
                end
            else
                local revert = vim.system({
                    "hg",
                    "--cwd",
                    file.root,
                    "revert",
                    "--",
                    file.relative,
                }, { text = true }):wait()
                if revert.code ~= 0 then
                    vim.notify(
                        "Mercurial revert failed: " .. vim.trim(revert.stderr or ""),
                        vim.log.levels.ERROR
                    )
                    return
                end
            end

            local listed = vim.system({ "hg", "--cwd", file.root, "status" }, { text = true }):wait()
            local remaining = parse_openable_status(listed.stdout or "", file.root)
            if #remaining == 0 then
                vim.api.nvim_win_close(0, true)
                vim.notify("No uncommitted files", vim.log.levels.INFO)
                return
            end

            require("oil.actions").refresh.callback({ force = true })
        end, { buffer = buf, nowait = true, desc = "Revert uncommitted file" })
    end)
end

local topic_namespace = vim.api.nvim_create_namespace("lawrencium_topics")
local blame_namespace = vim.api.nvim_create_namespace("lawrencium_blame")
local blame_states = {}

-- Reserved: uncommitted/secret, local drafts, public default.
-- Topics (and other named branches) get unique rainbow colors after that.
local hg_log_topic_palette = {
    { name = "HgLogTopicPurple", fg = "#af5fd7", ctermfg = 141 },
    { name = "HgLogTopicLightBlue", fg = "#87d7ff", ctermfg = 117 },
    { name = "HgLogTopicDarkBlue", fg = "#3a6ea5", ctermfg = 25 },
    { name = "HgLogTopicOrange", fg = "#ff9f1c", ctermfg = 214 },
    { name = "HgLogTopicMagenta", fg = "#d65d9a", ctermfg = 169 },
    { name = "HgLogTopicTeal", fg = "#2ec4b6", ctermfg = 43 },
    { name = "HgLogTopicGold", fg = "#e9c46a", ctermfg = 221 },
    { name = "HgLogTopicBrown", fg = "#bc6c25", ctermfg = 166 },
    { name = "HgLogTopicCyan", fg = "#4cc9f0", ctermfg = 81 },
    { name = "HgLogTopicViolet", fg = "#7b2cbf", ctermfg = 98 },
    { name = "HgLogTopicPink", fg = "#f72585", ctermfg = 205 },
    { name = "HgLogTopicIndigo", fg = "#4361ee", ctermfg = 63 },
    { name = "HgLogTopicLavender", fg = "#c77dff", ctermfg = 177 },
    { name = "HgLogTopicSky", fg = "#00b4d8", ctermfg = 38 },
    { name = "HgLogTopicCoral", fg = "#ee6c4d", ctermfg = 209 },
}

local function hsl_to_hex(h, s, l)
    h = h % 360
    local function channel(n)
        local k = (n + h / 30) % 12
        local a = s * math.min(l, 1 - l)
        local c = l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
        return math.floor(c * 255 + 0.5)
    end
    return string.format("#%02x%02x%02x", channel(0), channel(8), channel(4))
end

local function define_hg_log_highlights()
    local dark = vim.o.background ~= "light"
    vim.api.nvim_set_hl(0, "HgLogUncommitted", {
        fg = dark and "#7c6f64" or "#000000",
        ctermfg = dark and 8 or 0,
    })
    vim.api.nvim_set_hl(0, "HgLogLocal", { fg = "#e03131", ctermfg = 1 })
    vim.api.nvim_set_hl(0, "HgLogDefault", { fg = "#2f9e44", ctermfg = 2 })

    for _, color in ipairs(hg_log_topic_palette) do
        vim.api.nvim_set_hl(0, color.name, { fg = color.fg, ctermfg = color.ctermfg })
    end
end

local function hg_log_topic_highlight(index)
    local color = hg_log_topic_palette[index]
    if color then
        return color.name
    end

    local name = "HgLogTopicGen" .. index
    local hue = (270 + (index - 1) * 47) % 360
    if hue < 20 or hue > 345 then
        hue = (hue + 40) % 360
    end
    if hue > 95 and hue < 150 then
        hue = 155
    end
    vim.api.nvim_set_hl(0, name, { fg = hsl_to_hex(hue, 0.72, 0.55) })
    return name
end

local function hg_log_line_highlight(info, topic_keys)
    if info.topic ~= "" then
        return topic_keys["topic:" .. info.topic]
    end
    if info.phase == "secret" then
        return "HgLogUncommitted"
    end
    if info.phase == "draft" then
        return "HgLogLocal"
    end
    if info.branch == "default" then
        return "HgLogDefault"
    end
    return topic_keys["branch:" .. info.branch]
end

local function render_hg_blame(buf)
    vim.api.nvim_buf_clear_namespace(buf, blame_namespace, 0, -1)

    local state = blame_states[buf]
    if not state or not state.enabled or not state.annotations then
        return
    end

    if vim.api.nvim_get_current_buf() ~= buf then
        return
    end

    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local annotation = state.annotations[row + 1]
    if annotation then
        vim.api.nvim_buf_set_extmark(buf, blame_namespace, row, 0, {
            virt_text = { { "  " .. annotation, "Comment" } },
            virt_text_pos = "eol",
        })
    end
end

local function load_hg_blame(buf)
    local state = blame_states[buf]
    if not state or not state.enabled then
        return
    end

    local file = vim.api.nvim_buf_get_name(buf)
    local root = vim.fs.root(file, ".hg")
    if not root then
        state.enabled = false
        vim.notify("Current file is not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    state.generation = state.generation + 1
    local generation = state.generation
    local relative_file = vim.fs.relpath(root, file)

    vim.system({
        "hg",
        "--cwd",
        root,
        "annotate",
        "-T",
        "{lines % '{rev}\\t{author|user}\\t{date|age}\\t{desc|firstline}\\n'}",
        "--",
        relative_file,
    }, { text = true }, function(result)
        vim.schedule(function()
            state = blame_states[buf]
            if not state or not state.enabled or state.generation ~= generation then
                return
            end

            if result.code ~= 0 then
                state.enabled = false
                vim.notify(
                    "Mercurial blame failed: " .. vim.trim(result.stderr),
                    vim.log.levels.ERROR
                )
                return
            end

            local annotations = {}
            for _, line in ipairs(vim.split(result.stdout, "\n", { plain = true })) do
                local revision, author, age, summary =
                    line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")

                if revision then
                    table.insert(
                        annotations,
                        string.format("%s, %s • %s", author, age, summary)
                    )
                end
            end

            state.annotations = annotations
            render_hg_blame(buf)
        end)
    end)
end

local function toggle_hg_blame()
    local buf = vim.api.nvim_get_current_buf()
    local state = blame_states[buf]

    if state and state.enabled then
        state.enabled = false
        state.generation = state.generation + 1
        vim.api.nvim_buf_clear_namespace(buf, blame_namespace, 0, -1)
        return
    end

    blame_states[buf] = state or { generation = 0 }
    blame_states[buf].enabled = true
    load_hg_blame(buf)
end

local function colorize_hg_log(buf)
    define_hg_log_highlights()

    local rows_by_revision = {}
    local revisions = {}

    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local revision = line:match("(%d+):[%da-fA-F]+")

        if revision then
            rows_by_revision[revision] = row - 1
            table.insert(revisions, revision)
        end
    end

    if #revisions == 0 then
        return
    end

    local log_path = vim.fn["lawrencium#parse_lawrencium_path"](
        vim.api.nvim_buf_get_name(buf)
    )
    local revset = table.concat(revisions, " or ")

    vim.system({
        "hg",
        "--cwd",
        log_path.root,
        "log",
        "-r",
        revset,
        "-T",
        "{rev}\\t{phase}\\t{branch}\\t{topic}\\n",
    }, { text = true }, function(result)
        if result.code ~= 0 then
            return
        end

        local infos = {}
        for revision, phase, branch, topic in result.stdout:gmatch("(%d+)\t([^\t]*)\t([^\t]*)\t([^\n]*)") do
            infos[revision] = {
                phase = phase,
                branch = branch,
                topic = topic,
            }
        end

        local topic_keys = {}
        local next_topic = 1
        for _, revision in ipairs(revisions) do
            local info = infos[revision]
            if info then
                local key
                if info.topic ~= "" then
                    key = "topic:" .. info.topic
                elseif info.phase == "public" and info.branch ~= "default" then
                    key = "branch:" .. info.branch
                end
                if key and not topic_keys[key] then
                    topic_keys[key] = hg_log_topic_highlight(next_topic)
                    next_topic = next_topic + 1
                end
            end
        end

        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            vim.api.nvim_buf_clear_namespace(buf, topic_namespace, 0, -1)
            for revision, info in pairs(infos) do
                local row = rows_by_revision[revision]
                if row then
                    local hl = hg_log_line_highlight(info, topic_keys)
                    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
                    local opts = {
                        end_row = row,
                        end_col = #line,
                        hl_group = hl,
                        line_hl_group = hl,
                    }
                    if info.topic ~= "" then
                        opts.virt_text = { { "  [topic: " .. info.topic .. "]", hl } }
                        opts.virt_text_pos = "eol"
                    end
                    vim.api.nvim_buf_set_extmark(buf, topic_namespace, row, 0, opts)
                end
            end
        end)
    end)
end

return {
    "gyllstromk/vim-lawrencium",
    lazy = false,
    config = function()
        local group = vim.api.nvim_create_augroup("lawrencium_graph_log", { clear = true })
        define_hg_log_highlights()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = group,
            callback = define_hg_log_highlights,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
            group = group,
            callback = function(event)
                render_hg_blame(event.buf)
            end,
        })

        vim.api.nvim_create_autocmd("BufWritePost", {
            group = group,
            callback = function(event)
                if blame_states[event.buf] and blame_states[event.buf].enabled then
                    load_hg_blame(event.buf)
                end
            end,
        })

        vim.api.nvim_create_autocmd("BufDelete", {
            group = group,
            callback = function(event)
                blame_states[event.buf] = nil
            end,
        })

        vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
            group = group,
            callback = function(event)
                refresh_hg_location(event.buf)
            end,
        })

        vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "HgsignsUpdate",
            callback = function(event)
                local buf = event.data and event.data.buffer or event.buf
                if buf then
                    refresh_hg_location(buf)
                end
            end,
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "hglog",
            callback = function(event)
                -- Lawrencium installs its own mapping after setting the filetype,
                -- so defer ours until its log setup has finished.
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(event.buf) then
                        return
                    end

                    if vim.b[event.buf].hg_graph then
                        return
                    end

                    colorize_hg_log(event.buf)

                    vim.keymap.set("n", "<CR>", function()
                        local line = vim.api.nvim_get_current_line()
                        local revision = line:match("(%d+):[%da-fA-F]+")

                        if not revision then
                            vim.notify("No Mercurial revision found on this line", vim.log.levels.WARN)
                            return
                        end

                        local log_path = vim.fn["lawrencium#parse_lawrencium_path"](
                            vim.api.nvim_buf_get_name(0)
                        )
                        local rev_range = string.format("p1(%s)::%s", revision, revision)

                        vim.cmd(string.format(
                            "DiffviewOpen %s -C%s",
                            rev_range,
                            vim.fn.fnameescape(log_path.root)
                        ))
                    end, {
                        buffer = event.buf,
                        desc = "Open selected Mercurial revision in Diffview",
                    })
                end)
            end,
        })
    end,
    keys = {
        { "<leader>hs", "<cmd>Hgstatus<CR>", desc = "Mercurial status" },
        { "<leader>hu", toggle_hg_uncommitted, desc = "Toggle Mercurial uncommitted files" },
        { "<leader>hd", "<cmd>DiffviewOpen<CR>", desc = "Open Mercurial working changes in Diffview" },
        { "<leader>hb", toggle_hg_blame, desc = "Toggle Mercurial current line blame" },
        {
            "<leader>hg",
            function()
                toggle_hg_log("Hglog -l 50 -G")
            end,
            desc = "Toggle Mercurial graph log (50)",
        },
        { "<leader>hT", open_thg_log, desc = "Open TortoiseHg log workbench" },
        {
            "<leader>hf",
            function()
                toggle_hg_log("Hglogthis -l 100")
            end,
            desc = "Toggle Mercurial current file log (100)",
        },
        { "<leader>ha", "<cmd>Hgannotate<CR>", desc = "Mercurial annotate current file" },
        { "<leader>hc", open_hg_commit_interactive, desc = "Interactive Mercurial commit" },
        { "<leader>hr", "<cmd>Hgrecord<CR>", desc = "Mercurial record selected changes" },
    },
}
