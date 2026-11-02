-- Port reverse-forwarded (ssh RemoteForward) to a listener on the local
-- machine, which rewrites the local alacritty's zj-theme.toml.
local ALACRITTY_TUNNEL_PORT = 7778

-- Colorscheme name -> alacritty theme name (as the laptop's listener expects).
local ALACRITTY_THEMES = {
    juliana = "Mariana",
    miasma = "miasma",
    nordfox = "nordfox",
    duskfox = "duskfox",
    terafox = "terafox",
    kanagawa = "kanagawa_wave",
    ["kanagawa-wave"] = "kanagawa_wave",
    ["kanagawa-dragon"] = "kanagawa_dragon",
    ["kanagawa-lotus"] = "kanagawa_lotus",
}

-- Send the alacritty theme name for the active colorscheme through the
-- tunnel. Silently does nothing if the tunnel isn't up.
local function send_alacritty_theme()
    local theme = ALACRITTY_THEMES[vim.g.colors_name]
    if not theme then
        return
    end

    local tcp = vim.uv.new_tcp()
    tcp:connect("127.0.0.1", ALACRITTY_TUNNEL_PORT, function(err)
        if err then
            tcp:close()
            return
        end
        tcp:write(theme .. "\n", function()
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
            -- ~/.config/zellij/themes/; both alacritty themes ship with
            -- alacritty-theme (juliana's bg is overridden to match Mariana.toml).
            mappings = { juliana = "juliana", miasma = "miasma" },
        }

        -- Only write alacritty's zj-theme.toml on machines that have alacritty
        -- (the laptop). Elsewhere the write would fail on every colorscheme change.
        if vim.fn.isdirectory(vim.fn.expand("~/.config/alacritty")) == 1 then
            opts.terminal = {
                emulator = "alacritty",
                mappings = { juliana = "Mariana", miasma = "miasma" },
            }
        end

        require("zj-theme").setup(opts)

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("zj-theme-alacritty-tunnel", { clear = true }),
            callback = send_alacritty_theme,
        })
    end,
}
