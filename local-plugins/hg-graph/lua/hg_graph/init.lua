local colors = require("hg_graph.colors")
local filter = require("hg_graph.filter")
local float = require("hg_graph.float")
local graph = require("hg_graph.graph")
local header = require("hg_graph.header")
local maps = require("hg_graph.maps")

local M = {}

local state = {
    root = nil,
    limit = 50,
    load_generation = 0,
    meta_generation = 0,
    topic_filter = nil,
    log_body = nil,
    commit_meta = {},
    buf = nil,
    win = nil,
    float_buf = nil,
    float_win = nil,
    float_rev = nil,
    float_generation = 0,
    float_cache = {},
    float_debounce = nil,
}

local defaults = {
    limit = 50,
    limit_step = 50,
    max_limit = 300,
    revset = nil,
    preview_height = 0.88,
    float_width = 100,
    float_min_height = 14,
    float_max_height = 45,
    float_side_offset = 2,
    style = nil,
}

local config = vim.deepcopy(defaults)

local session_cache = {
    key = nil,
    root = nil,
    limit = nil,
    log_body = nil,
    commit_meta = {},
    float_cache = {},
}

local function cache_key(root, limit)
    return table.concat({ root, tostring(limit), config.revset or "" }, "\0")
end

function M.persist_session_cache()
    if not state.log_body or not state.root then
        return
    end
    session_cache.key = cache_key(state.root, state.limit)
    session_cache.root = state.root
    session_cache.limit = state.limit
    session_cache.log_body = state.log_body
    session_cache.commit_meta = state.commit_meta
    session_cache.float_cache = state.float_cache
end

local function restore_from_session_cache(root, limit)
    local key = cache_key(root, limit)
    if session_cache.key ~= key or not session_cache.log_body then
        return false
    end
    state.root = session_cache.root
    state.limit = session_cache.limit
    state.log_body = session_cache.log_body
    state.commit_meta = session_cache.commit_meta or {}
    state.float_cache = session_cache.float_cache or {}
    return true
end

local function invalidate_session_cache()
    session_cache.key = nil
    session_cache.log_body = nil
end

local function float_opts()
    return {
        width = config.float_width,
        min_height = config.float_min_height,
        max_height = config.float_max_height,
        side_offset = config.float_side_offset,
    }
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

local function log_style_path()
    if config.style then
        return config.style
    end
    local lawrencium = vim.fn.stdpath("data") .. "/lazy/vim-lawrencium/resources/hg_log.style"
    if vim.fn.filereadable(lawrencium) == 1 then
        return lawrencium
    end
    return vim.fs.joinpath(vim.fn.stdpath("config"), "local-plugins", "hg-graph", "hg", "graph.style")
end

local function is_graph_buf(buf)
    return vim.b[buf].hg_graph == true
end

function M.close_float()
    float.close(state)
    state.float_rev = nil
end

local function close_preview()
    M.persist_session_cache()
    M.close_float()

    if state.float_debounce then
        pcall(vim.fn.timer_stop, state.float_debounce)
        state.float_debounce = nil
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if is_graph_buf(buf) then
            vim.api.nvim_win_close(win, true)
            state.win = nil
            state.buf = nil
            return true
        end
    end
    return false
end

function M.close()
    return close_preview()
end

function M.focus_graph()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_set_current_win(state.win)
    end
end

function M.focus_float()
    if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
        vim.api.nvim_set_current_win(state.float_win)
        local rows = vim.b[state.float_buf].hg_graph_files
        if rows and rows[1] then
            vim.api.nvim_win_set_cursor(state.float_win, { rows[1].line, 2 })
        end
    end
end

function M.toggle_pane()
    local cur = vim.api.nvim_get_current_win()
    if state.float_win and vim.api.nvim_win_is_valid(state.float_win) and cur == state.float_win then
        M.close_float()
        M.focus_graph()
        return
    end
    state.float_wants_focus = true
    M.update_float({ open = true })
    if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
        M.focus_float()
    end
end

function M.update_float(opts)
    opts = opts or {}
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    if not state.win or not vim.api.nvim_win_is_valid(state.win) then
        return
    end

    local visible = state.float_win and vim.api.nvim_win_is_valid(state.float_win)
    if not visible and not opts.open then
        return
    end

    local root = state.root or vim.b[state.buf].hg_root
    if not root then
        return
    end

    local revision = maps.revision_at_cursor(state.buf, state.win)
    if not revision then
        M.close_float()
        return
    end

    if revision == state.float_rev and visible then
        float.open_at(state.win, state, float_opts())
        if state.float_wants_focus then
            state.float_wants_focus = false
            M.focus_float()
        end
        return
    end

    state.float_rev = revision
    state.float_generation = state.float_generation + 1
    local generation = state.float_generation

    float.load(
        root,
        revision,
        state.win,
        state,
        float_opts(),
        generation,
        function()
            return state.float_generation
        end
    )
end

function M.on_float_ready()
    if state.float_wants_focus then
        state.float_wants_focus = false
        M.focus_float()
    end
end

local function schedule_float_update()
    if not (state.float_win and vim.api.nvim_win_is_valid(state.float_win)) then
        return
    end
    if state.float_debounce then
        pcall(vim.fn.timer_stop, state.float_debounce)
    end
    state.float_debounce = vim.fn.timer_start(80, function()
        state.float_debounce = nil
        M.update_float()
    end)
end

local function map_callbacks(root)
    return {
        refresh = function()
            invalidate_session_cache()
            M.fetch_log(root, state.limit, { quiet = true, force = true })
        end,
        load_more = function()
            local next_limit = math.min(state.limit + config.limit_step, config.max_limit)
            if next_limit == state.limit then
                vim.notify("Already at max commit limit", vim.log.levels.INFO)
                return
            end
            invalidate_session_cache()
            M.fetch_log(root, next_limit, { quiet = false, force = true })
        end,
        topic_filter = function()
            maps.pick_topic_filter(root, state.commit_meta, function(name)
                state.topic_filter = name
                M.redraw()
            end)
        end,
        toggle_pane = function()
            M.toggle_pane()
        end,
        open_changeset_and_leave = function()
            maps.open_changeset(root, state.buf, state.win, true)
        end,
    }
end

local function attach_float_autocmd(graph_buf, graph_win)
    local group = vim.api.nvim_create_augroup("hg_graph_float_" .. graph_buf, { clear = true })
    local function on_graph_activity()
        if vim.api.nvim_get_current_win() == graph_win then
            schedule_float_update()
        end
    end
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter" }, {
        group = group,
        buffer = graph_buf,
        callback = on_graph_activity,
    })
end

local function finish_buffer(buf, root, graph_win)
    vim.b[buf].hg_graph = true
    vim.b[buf].hg_root = root
    vim.b[buf].hg_graph_header_rows = header.ROW_COUNT
    maps.setup(buf, root, map_callbacks(root))
    attach_float_autocmd(buf, graph_win)
end

local function ensure_preview_window(root)
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) and state.win and vim.api.nvim_win_is_valid(state.win) then
        return state.buf, state.win
    end

    close_preview()

    local height = math.max(20, math.floor(vim.o.lines * (config.preview_height or 0.88)))

    vim.cmd("botright " .. height .. "new")
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("previewwindow", true, { win = win })
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].cursorline = false
    vim.wo[win].wrap = false
    vim.wo[win].signcolumn = "no"

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.b[buf].hg_graph = true
    vim.bo[buf].filetype = "hggraphlog"

    state.buf = buf
    state.win = win
    finish_buffer(buf, root, win)
    return buf, win
end

function M.apply_colors()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    graph.apply(state.buf, header.ROW_COUNT)
    colors.apply(state.buf, state.commit_meta, header.ROW_COUNT)
end

function M.redraw(opts)
    opts = opts or {}
    if not state.log_body or not state.root then
        return
    end

    local body = filter.apply(state.log_body, state.topic_filter, state.commit_meta)
    local buf, win = ensure_preview_window(state.root)

    local loaded = #filter.revisions_in_body(state.log_body)
    local filtered = state.topic_filter and #filter.revisions_in_body(body) or nil

    vim.bo[buf].modifiable = true
    local lines = header.lines(loaded, state.topic_filter, filtered)
    vim.list_extend(lines, body)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    header.paint(buf)
    vim.bo[buf].modifiable = false
    graph.apply(buf, header.ROW_COUNT)
    colors.apply(buf, state.commit_meta, header.ROW_COUNT)

    if not opts.keep_float then
        M.close_float()
        state.float_rev = nil
    end

    vim.schedule(function()
        if not vim.api.nvim_win_is_valid(win) then
            return
        end
        pcall(vim.api.nvim_set_current_win, win)
        for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, header.ROW_COUNT, -1, false)) do
            if line:find("@", 1, true) or line:find("<==", 1, true) then
                pcall(vim.api.nvim_win_set_cursor, win, { row + header.ROW_COUNT, 0 })
                pcall(vim.cmd, "normal! zz")
                return
            end
        end
    end)
end

function M.fetch_log(root, limit, opts)
    opts = opts or {}
    root = root or state.root or find_hg_root()
    if not root then
        return
    end

    limit = limit or state.limit
    state.limit = limit
    state.root = root

    if opts.force then
        invalidate_session_cache()
    end

    state.load_generation = state.load_generation + 1
    state.meta_generation = state.meta_generation + 1
    local generation = state.load_generation

    local style = log_style_path()
    if vim.fn.filereadable(style) == 0 then
        vim.notify("Missing hg log style: " .. style, vim.log.levels.ERROR)
        return
    end

    if not opts.quiet then
        vim.notify("Loading hg graph…", vim.log.levels.INFO)
    end

    local argv = {
        "hg",
        "--cwd",
        root,
        "--color",
        "never",
        "--pager",
        "off",
        "log",
        "--graph",
        "-l",
        tostring(limit),
        "--style",
        style,
    }
    if config.revset then
        vim.list_extend(argv, { "-r", config.revset })
    end

    vim.system(argv, { text = true }, function(result)
        vim.schedule(function()
            if generation ~= state.load_generation then
                return
            end
            if result.code ~= 0 then
                vim.notify("hg log failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
                return
            end

            local stdout = vim.trim(result.stdout or "")
            if stdout == "" then
                vim.notify("Hg graph: no commits to show", vim.log.levels.WARN)
                return
            end

            state.log_body = vim.split(stdout, "\n", { plain = true })
            state.commit_meta = {}
            state.float_cache = {}
            M.persist_session_cache()

            local revs = filter.revisions_in_body(state.log_body)
            M.redraw()

            state.meta_generation = state.meta_generation + 1
            local meta_gen = state.meta_generation
            filter.fetch_meta_async(root, revs, function(map)
                if generation ~= state.load_generation or meta_gen ~= state.meta_generation then
                    return
                end
                state.commit_meta = map
                M.persist_session_cache()
                if state.topic_filter then
                    M.redraw({ keep_float = true })
                else
                    M.apply_colors()
                end
            end)
        end)
    end)
end

function M.load_log(root, limit, opts)
    M.fetch_log(root, limit, opts)
end

function M.toggle(opts)
    opts = vim.tbl_extend("force", {}, config, opts or {})

    if close_preview() and not opts.force then
        return
    end

    local root = find_hg_root()
    if not root then
        vim.notify("Not in a Mercurial repository", vim.log.levels.WARN)
        return
    end

    state.limit = opts.limit or config.limit
    if opts.topic_filter ~= nil then
        state.topic_filter = opts.topic_filter ~= "" and opts.topic_filter or nil
    end

    if not opts.force and restore_from_session_cache(root, state.limit) then
        M.redraw()
        return
    end

    M.fetch_log(root, state.limit, opts)
end

function M.clear_topic_filter()
    state.topic_filter = nil
    M.redraw()
end

function M.setup(user)
    config = vim.tbl_deep_extend("force", {}, defaults, user or {})
    colors.define_highlights()
    graph.define_highlights()
    float.define_highlights()
    vim.api.nvim_create_augroup("hg_graph", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = "hg_graph",
        callback = function()
            colors.define_highlights()
            graph.define_highlights()
            float.define_highlights()
        end,
    })
end

return M
