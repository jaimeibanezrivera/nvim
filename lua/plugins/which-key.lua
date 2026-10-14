return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        spec = {
            { "<leader>h", group = "Mercurial" },
            { "<leader>a", group = "Avante" },
            { "<leader>x", group = "Herd" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer-local keymaps",
        },
    },
}
