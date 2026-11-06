return {
  -- Indent guides, with the current scope highlighted (needs treesitter)
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "BufReadPost",
  opts = {
    indent = { char = "│" },
    scope = { show_start = false, show_end = false },
    exclude = { filetypes = { "alpha", "neo-tree", "oil", "lazy", "mason", "trouble" } },
  },
}
