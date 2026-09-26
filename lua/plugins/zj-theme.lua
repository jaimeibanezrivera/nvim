-- Port reverse-forwarded (ssh RemoteForward) to a listener on the local
-- machine, which rewrites the local alacritty's zj-theme.toml.
local ALACRITTY_TUNNEL_PORT = 47631

-- Send the alacritty theme name for the active colorscheme through the
-- tunnel. Silently does nothing if the tunnel isn't up.
local function send_alacritty_theme()
    local terminal = require("zj-theme.terminal")
    local adapter = require("zj-theme.terminals.alacritty")
    local theme = terminal.resolve_theme(adapter, vim.g.colors_name) or terminal.default_theme(adapter)
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
        require("zj-theme").setup({
            default_dark_theme = "onedark",
            default_light_theme = "pencil-light-visible-selection",
        })

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("zj-theme-alacritty-tunnel", { clear = true }),
            callback = send_alacritty_theme,
        })
    end,
}
