return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
     -- vim.cmd.colorscheme("catppuccin-mocha") -- This remains commented out as per your original input
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      -- Initial settings for Gruvbox Material (defaulting to dark mode)
      vim.g.gruvbox_material_background = "medium"  -- options for dark: 'soft', 'medium', 'hard'
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_transparent_background = 0
      vim.cmd.colorscheme("gruvbox-material") -- Apply the initial dark theme
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        compile = false,
        transparent = false,
        theme = "wave", -- "wave", "dragon", "lotus"
      })
    end,
{ "EdenEast/nightfox.nvim" }, -- lazy
  {
    "NLKNguyen/papercolor-theme",
    lazy = false,
    priority = 1000,
    config = function()
      vim.api.nvim_create_autocmd("ColorSchemePre", {
        pattern = "PaperColor",
        callback = function()
          vim.o.background = "light"
        end,
      })
    end,
  },
  }

}
