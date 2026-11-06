-- Port reverse-forwarded (ssh RemoteForward) to a listener on the local
-- machine, which rewrites the local alacritty's zj-theme.toml.
local ALACRITTY_TUNNEL_PORT = 7778

-- Alacritty theme used when a colorscheme has no mapping below.
local ALACRITTY_BASE_THEME = "Mariana"

-- Colorscheme name -> alacritty theme name (as the laptop's listener expects).
-- Merged over zj-theme's built-in alacritty mappings (catppuccin, gruvbox,
-- ayu, everforest, PaperColor, ...), so only extras/overrides go here.
-- Values can be { dark = ..., light = ... } like zj-theme's own mappings.
local ALACRITTY_THEMES = {
    juliana = "Mariana",
    miasma = "miasma",
    github_dark = "github_dark",
    github_dark_dimmed = "github_dark_dimmed",
    nordfox = "nordfox",
    duskfox = "duskfox",
    terafox = "terafox",
    dawnfox = "dawnfox",
    onedark = { dark = "one_dark", light = "one_light" },
    -- kanagawa sets colors_name to "kanagawa" for every variant,
    -- so variants are matched on the name passed to :colorscheme instead.
    kanagawa = { dark = "kanagawa_wave", light = "gruvbox_light" },
    ["kanagawa-wave"] = "kanagawa_wave",
    ["kanagawa-dragon"] = "kanagawa_dragon",
    -- No kanagawa_lotus in alacritty-theme; closest warm light theme.
    ["kanagawa-lotus"] = "gruvbox_light",
}

-- Name passed to the last :colorscheme (e.g. "kanagawa-wave"), set on ColorSchemePre.
local requested_colorscheme

local function lookup(name)
    local mapped = ALACRITTY_THEMES[name]
    if mapped == nil then
        mapped = require("zj-theme.terminals.alacritty").default_mappings[name]
    end
    if type(mapped) == "table" then
        if vim.o.background == "light" then
            return mapped.light or mapped.dark
        end
        return mapped.dark or mapped.light
    end
    return mapped
end

local function resolve_alacritty_theme(colors_name)
    -- Prefer the requested variant name, but only if it belongs to the active
    -- colorscheme (guards against a stale name from an earlier switch).
    local req = requested_colorscheme
    if req and colors_name and vim.startswith(req, colors_name) then
        local theme = lookup(req)
        if theme then
            return theme
        end
    end
    return lookup(colors_name)
end

-- Send the alacritty theme for the active colorscheme through the tunnel.
-- Unmapped colorschemes fall back to the base theme. Silently does nothing
-- if the tunnel isn't up.
local function send_alacritty_theme()
    local theme = resolve_alacritty_theme(vim.g.colors_name) or ALACRITTY_BASE_THEME

    local tcp = vim.uv.new_tcp()
    tcp:connect("127.0.0.1", ALACRITTY_TUNNEL_PORT, function(err)
        if err then
            tcp:close()
            return
        end
        tcp:write("theme " .. theme .. "\n", function()
            tcp:shutdown(function()
                tcp:close()
            end)
        end)
    end)
end

return {
    "jaimeibanezrivera/zj-theme",
    lazy = false,
    config = function()
        local opts = {
            default_dark_theme = "onedark",
            default_light_theme = "pencil-light-visible-selection",
            -- juliana (Mariana) and miasma zellij themes live in
            -- ~/.config/zellij/themes/, as do the github_dark(+_dimmed) ones.
            -- Other alacritty themes ship with alacritty-theme
            -- (juliana's bg is overridden to match Mariana.toml).
            mappings = {
                juliana = "juliana",
                miasma = "miasma",
                github_dark = "github_dark",
                github_dark_dimmed = "github_dark_dimmed",
            },
        }

        -- Only write alacritty's zj-theme.toml on machines that have alacritty
        -- (the laptop). Elsewhere the write would fail on every colorscheme change.
        if vim.fn.isdirectory(vim.fn.expand("~/.config/alacritty")) == 1 then
            opts.terminal = {
                emulator = "alacritty",
                mappings = { juliana = "Mariana", miasma = "miasma", github_dark = "github_dark", github_dark_dimmed = "github_dark_dimmed" },
            }
        end

        require("zj-theme").setup(opts)

        local group = vim.api.nvim_create_augroup("zj-theme-alacritty-tunnel", { clear = true })
        vim.api.nvim_create_autocmd("ColorSchemePre", {
            group = group,
            callback = function(args)
                requested_colorscheme = args.match
            end,
        })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = group,
            callback = send_alacritty_theme,
        })
    end,
}
