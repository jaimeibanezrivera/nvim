return {
  -- Popup listing available keys after pressing <leader> (or any prefix)
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>b", group = "browse (fzf)" },
      { "<leader>c", group = "code" },
      { "<leader>d", group = "diffview" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lazygit / light mode" },
      { "<leader>r", group = "rust / rename" },
      { "<leader>t", group = "toggle" },
      { "<leader>x", group = "trouble" },
    },
  },
}
