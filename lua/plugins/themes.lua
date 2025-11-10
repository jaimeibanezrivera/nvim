return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
     -- vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      -- Optional settings for Gruvbox Material:
      -- vim.g.gruvbox_material_background = "medium"  -- options: 'soft', 'medium', 'hard'
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_transparent_background = 0
    vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}
