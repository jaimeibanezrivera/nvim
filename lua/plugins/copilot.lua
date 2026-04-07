return {
    {
        "github/copilot.vim",
        lazy = false,
        config = function()
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_hide_during_completion = 0

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
