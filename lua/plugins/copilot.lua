return {
    {
        "github/copilot.vim",
        lazy = false,
        init = function()
            -- Use the language server bundled with copilot.vim. The default
            -- npx launcher can fail when its transient npm cache is corrupted.
            vim.g.copilot_npx_command = 0
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_hide_during_completion = 0
        end,
        config = function()
            vim.keymap.set("i", "<C-l>", 'copilot#Accept("")', {
                expr = true,
                replace_keycodes = false,
                desc = "Accept Copilot suggestion",
            })
            vim.keymap.set("i", "<C-]>", "<Plug>(copilot-next)", { desc = "Next Copilot suggestion" })
            vim.keymap.set("i", "<C-p>", "<Plug>(copilot-previous)", { desc = "Prev Copilot suggestion" })
            vim.keymap.set("i", "<C-\\>", "<Plug>(copilot-dismiss)", { desc = "Dismiss Copilot suggestion" })
        end,
    },
}
