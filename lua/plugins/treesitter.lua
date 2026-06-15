return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "python", "lua", "vim", "vimdoc", "query", "c", "cpp", "rust" },
        auto_install = true,
      })
    end,
  },
}
