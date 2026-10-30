return {
    name = "hg-graph",
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "local-plugins", "hg-graph"),
    dependencies = { "sindrets/diffview.nvim", "gyllstromk/vim-lawrencium" },
    opts = {
        limit = 50,
        limit_step = 50,
        max_limit = 300,
        preview_height = 0.88,
        float_width = 100,
        float_min_height = 14,
        float_max_height = 45,
        float_side_offset = 2,
    },
    config = function(_, opts)
        require("hg_graph").setup(opts)
    end,
    keys = {
        {
            "<leader>hG",
            function()
                require("hg_graph").toggle()
            end,
            desc = "Toggle Mercurial graph log",
        },
    },
}
