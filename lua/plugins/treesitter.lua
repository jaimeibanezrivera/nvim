return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      local languages = {
        "python",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "c",
        "cpp",
        "rust",
        "markdown",
        "markdown_inline",
      }

      treesitter.install(languages)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = languages,
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
