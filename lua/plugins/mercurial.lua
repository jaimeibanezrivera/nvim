local hg = require("mercurial")
hg.log_graph.setup()

return {
  {
    "cavanaug/hgsigns.nvim",
    branch = "mercurial",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      hg.hgsigns.setup()
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    lazy = true,
    opts = {
      float = {
        border = "rounded",
      },
    },
    keys = {
      {
        "<leader>hc",
        hg.commit.toggle_interactive,
        desc = "hg commit -i (interactive)",
      },
    },
  },
}
