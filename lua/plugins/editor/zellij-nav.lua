return {
    "swaits/zellij-nav.nvim",
    event = "VeryLazy",
    keys = {
        { "<M-h>", "<cmd>ZellijNavigateLeftTab<CR>", desc = "Move left (nvim/zellij)" },
        { "<M-j>", "<cmd>ZellijNavigateDown<CR>", desc = "Move down (nvim/zellij)" },
        { "<M-k>", "<cmd>ZellijNavigateUp<CR>", desc = "Move up (nvim/zellij)" },
        { "<M-l>", "<cmd>ZellijNavigateRightTab<CR>", desc = "Move right (nvim/zellij)" },
    },
    opts = {},
}
