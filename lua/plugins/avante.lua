local function path_under_cursor()
    local word = vim.fn.expand("<cWORD>")
    word = word:gsub("^[`'\"<(]+", ""):gsub("[`'\".,>);]+$", ""):gsub("^file://", "")

    local path, line, column = word:match("^(.-):(%d+):(%d+)$")
    if path then
        return path, tonumber(line), tonumber(column)
    end

    path, line = word:match("^(.-):(%d+)$")
    if path then
        return path, tonumber(line), 0
    end

    if vim.bo.filetype == "AvanteSelectedFiles" then
        path = vim.api.nvim_get_current_line():match("^%S+%s+(.+)$")
        if path and path ~= "" then
            return path
        end
    end

    path = vim.fn.expand("<cfile>")
    return path ~= "" and path or (word ~= "" and word or nil)
end

local function resolve_path(path)
    if not path or path == "" then
        return nil
    end

    local function exists(candidate)
        return vim.uv.fs_stat(candidate) ~= nil
    end

    if exists(path) then
        return vim.fn.fnamemodify(path, ":p")
    end

    local roots = { vim.fn.getcwd() }
    local ok, utils = pcall(require, "avante.utils")
    if ok then
        table.insert(roots, 1, utils.get_project_root())
    end

    for _, root in ipairs(roots) do
        local candidate = vim.fs.joinpath(root, path)
        if exists(candidate) then
            return vim.fn.fnamemodify(candidate, ":p")
        end
    end

    local found = vim.fn.findfile(path, ".;")
    if found ~= "" then
        return vim.fn.fnamemodify(found, ":p")
    end
end

local function code_win()
    local sidebar = require("avante").get()
    if not sidebar then
        return nil
    end
    if sidebar.code and sidebar.code.winid and vim.api.nvim_win_is_valid(sidebar.code.winid) then
        return sidebar.code.winid
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and not sidebar:is_sidebar_winid(win) then
            return win
        end
    end
end

local function open_cfile_in_code_win()
    local path, line, column = path_under_cursor()
    local absolute = resolve_path(path)
    if not absolute then
        vim.notify("No file under cursor: " .. tostring(path), vim.log.levels.WARN)
        return
    end

    local win = code_win()
    if not win then
        vim.notify("No main pane to open " .. absolute, vim.log.levels.WARN)
        return
    end

    vim.api.nvim_set_current_win(win)
    vim.cmd.edit(vim.fn.fnameescape(absolute))
    if line then
        local last_line = vim.api.nvim_buf_line_count(0)
        local target = math.min(line, last_line)
        pcall(vim.api.nvim_win_set_cursor, win, { target, column or 0 })
        vim.cmd("normal! zz")
    end
end

local mode_palettes = {
    dark = {
        agent = { accent = "#a7adb7", background = "#3f444d", badge_fg = "#1e222a", foreground = "#f4f4f5" },
        ask = { accent = "#7bd88f", background = "#244f32", badge_fg = "#1e222a", foreground = "#f4fff6" },
        plan = { accent = "#f4c95d", background = "#57451a", badge_fg = "#1e222a", foreground = "#fff9e6" },
    },
    light = {
        agent = { accent = "#5f6670", background = "#d8dce2", badge_fg = "#ffffff", foreground = "#25282d" },
        ask = { accent = "#20883a", background = "#c8efcf", badge_fg = "#ffffff", foreground = "#12351b" },
        plan = { accent = "#a86600", background = "#ffe29a", badge_fg = "#ffffff", foreground = "#4a3000" },
    },
}

local function cursor_mode(sidebar)
    local options = sidebar.acp_client and sidebar.acp_client.config_options or {}
    for _, option in ipairs(options) do
        if option.category == "mode" then
            return option.currentValue
        end
    end
end

local function set_mode_highlights(mode)
    mode = mode:lower()
    local palette = mode_palettes[vim.o.background == "light" and "light" or "dark"]
    local colors = palette[mode] or palette.agent
    local normal = vim.api.nvim_get_hl(0, { name = "NormalFloat" })

    vim.api.nvim_set_hl(0, "AvanteTitle", { fg = colors.badge_fg, bg = colors.accent })
    vim.api.nvim_set_hl(0, "AvanteReversedTitle", { fg = colors.accent, bg = normal.bg })
    vim.api.nvim_set_hl(0, "AvanteModeInput", { fg = colors.badge_fg, bg = colors.accent })
    vim.api.nvim_set_hl(0, "AvanteReversedModeInput", { fg = colors.accent, bg = normal.bg })
    vim.api.nvim_set_hl(0, "AvanteModeInputNormal", { fg = colors.foreground, bg = colors.background })
end

local function color_input_header(sidebar)
    local mode = cursor_mode(sidebar)
    if not mode then
        return
    end

    local input = sidebar.containers and sidebar.containers.input
    if not input or not input.winid or not vim.api.nvim_win_is_valid(input.winid) then
        return
    end

    local winbar = vim.api.nvim_get_option_value("winbar", { win = input.winid })
    winbar = winbar:gsub("AvanteSubtitle", "AvanteModeInput")
    winbar = winbar:gsub("AvanteReversedSubtitle", "AvanteReversedModeInput")
    vim.api.nvim_set_option_value("winbar", winbar, { win = input.winid })

    local winhighlight = vim.api.nvim_get_option_value("winhighlight", { win = input.winid })
    winhighlight = winhighlight:gsub("Normal:[^,]*", "Normal:AvanteModeInputNormal")
    winhighlight = winhighlight:gsub("CursorLine:[^,]*", "CursorLine:AvanteModeInputNormal")
    winhighlight = winhighlight:gsub("CursorColumn:[^,]*", "CursorColumn:AvanteModeInputNormal")
    if not winhighlight:find("SignColumn:", 1, true) then
        winhighlight = winhighlight .. ",SignColumn:AvanteModeInputNormal"
    end
    vim.api.nvim_set_option_value("winhighlight", winhighlight, { win = input.winid })
end

local function setup_mode_colored_header()
    local Sidebar = require("avante.sidebar")
    if Sidebar._cursor_mode_colored_header then
        return
    end
    Sidebar._cursor_mode_colored_header = true

    local render_result = Sidebar.render_result
    local render_input = Sidebar.render_input
    Sidebar.render_result = function(self, ...)
        local result = render_result(self, ...)
        local mode = cursor_mode(self)
        if mode then
            set_mode_highlights(mode)
            color_input_header(self)
        end
        return result
    end
    Sidebar.render_input = function(self, ...)
        local result = render_input(self, ...)
        local mode = cursor_mode(self)
        if mode then
            set_mode_highlights(mode)
            color_input_header(self)
        end
        return result
    end

    local group = vim.api.nvim_create_augroup("avante-mode-colors", { clear = true })
    local function refresh_mode_colors()
        local sidebar = require("avante").get()
        if sidebar then
            local mode = cursor_mode(sidebar)
            if mode then
                set_mode_highlights(mode)
                color_input_header(sidebar)
            end
        end
    end
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = refresh_mode_colors })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "background",
        callback = refresh_mode_colors,
    })
end

local function setup_hidden_acp_thoughts()
    local ACPClient = require("avante.libs.acp_client")
    if ACPClient._thoughts_hidden then
        return
    end

    ACPClient._thoughts_hidden = true
    local new = ACPClient.new
    ACPClient.new = function(self, config)
        local on_session_update = config.on_session_update
        if on_session_update then
            config = vim.tbl_extend("force", {}, config)
            config.on_session_update = function(update)
                if update.sessionUpdate == "agent_thought_chunk" then
                    return
                end
                return on_session_update(update)
            end
        end
        return new(self, config)
    end
end

local function setup_acp_failure_cleanup()
    local ACPClient = require("avante.libs.acp_client")
    if ACPClient._failure_cleanup then
        return
    end

    ACPClient._failure_cleanup = true
    local connect = ACPClient.connect
    ACPClient.connect = function(self, callback)
        callback = callback or function() end
        return connect(self, function(err)
            if err then
                self:force_stop()
            end
            return callback(err)
        end)
    end
end

return {
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        build = "bash ./build.sh",
        opts = {
            provider = "cursor",
            mode = "agentic",
            acp_providers = {
                cursor = {
                    command = os.getenv("HOME") .. "/.local/bin/agent",
                    args = { "acp" },
                    auth_method = "cursor_login",
                    -- Cursor authentication on this host requires the proxy
                    -- variables from Neovim's complete environment.
                    env = vim.fn.environ(),
                },
            },
            selector = { provider = "fzf_lua" },
            behaviour = {
                auto_suggestions = false,
                acp_follow_agent_locations = true,
            },
            windows = {
                sidebar_header = {
                    include_model = true,
                },
            },
        },
        config = function(_, opts)
            require("avante").setup(opts)
            setup_hidden_acp_thoughts()
            setup_acp_failure_cleanup()
            setup_mode_colored_header()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "Avante", "AvanteSelectedFiles" },
                callback = function(event)
                    vim.keymap.set("n", "gf", open_cfile_in_code_win, {
                        buffer = event.buf,
                        desc = "Open file under cursor in main pane",
                    })
                    vim.keymap.set("n", "<CR>", open_cfile_in_code_win, {
                        buffer = event.buf,
                        desc = "Open file under cursor in main pane",
                    })
                end,
            })
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
            "hrsh7th/nvim-cmp",
            "ibhagwan/fzf-lua",
            "nvim-tree/nvim-web-devicons",
        },
    },
}
