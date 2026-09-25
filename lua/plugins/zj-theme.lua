return {
    "jaimeibanezrivera/zj-theme",
    lazy = false,
    config = function()
        local mode_file = vim.fn.expand("~/.config/theme-mode")
        local function write_theme_mode()
            local mode = vim.o.background == "light" and "light" or "dark"
            vim.fn.writefile({ mode }, mode_file)
        end
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("theme-mode-file", { clear = true }),
            callback = write_theme_mode,
        })

        require("zj-theme").setup({
            default_light_theme = "pencil-light-visible-selection",
            mappings = {
                juliana = "juliana",
                dawnfox = "dawnfox",
                carbonfox = "carbonfox",
                nordfox = "nordfox",
                duskfox = "duskfox",
                terafox = "terafox",
                PaperColor = "pencil-light-visible-selection",
                ["kanagawa-wave"] = "kanagawa",
                ["kanagawa-dragon"] = "kanagawa",
                ["kanagawa-lotus"] = "kanagawa-lotus",
            },
            -- Alacritty lives on the laptop. RemoteForward 7778 carries the
            -- theme name; a listener there writes zj-theme.toml.
            terminal = {
                emulator = "alacritty",
                tunnel = { host = "127.0.0.1", port = 7778 },
                mappings = {
                    juliana = "juliana",
                    ["kanagawa-wave"] = "kanagawa_wave",
                    ["kanagawa-dragon"] = "kanagawa_dragon",
                    ["kanagawa-lotus"] = "kanagawa_lotus",
                    kanagawa = "kanagawa_wave",
                    nordfox = "nordfox",
                    duskfox = "duskfox",
                    terafox = "terafox",
                },
            },
        })
    end,
}
