return {
    name = "hg-graph",
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "local-plugins", "hg-graph"),
    dependencies = { "sindrets/diffview.nvim" },
    opts = {},
    keys = {
        {
            "<leader>hG",
            function()
                require("hg_graph").toggle()
            end,
            desc = "Toggle Mercurial ancestry graph",
        },
    },
}
