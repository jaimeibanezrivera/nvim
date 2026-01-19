return {
  {
      'esensar/nvim-dev-container', -- This is the correct name
    dependencies = {
      "nvim-telescope/telescope.nvim", -- Optional: for better UI integration
      "nvim-lua/plenary.nvim",         -- Required dependency
    },
    config = function()
      require("devcontainer").setup({
        -- Your configuration options here
        -- For example:
        -- default_devcontainer_path = "~/.devcontainers",
        -- default_devcontainer_config = {
        --   image = "mcr.microsoft.com/devcontainers/universal:latest",
        --   features = {
        --     "ghcr.io/devcontainers/features/node:1": {},
        --   },
        -- },
      })
    end,
    -- You can also add keybindings here if you wish
    -- keys = {
    --   { "<leader>dc", "<cmd>DevcontainerOpen<CR>", desc = "Open Devcontainer" },
    -- },
  },
}
