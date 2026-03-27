return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local telescope = require("telescope")
      
      telescope.setup({
        defaults = {
          layout_strategy = 'vertical',
          layout_config = {
            vertical = {
              width = 0.9,
              height = 0.9,
              preview_height = 0.6,
              preview_cutoff = 20,
            },
          },
        },
      })
      
      local builtin = require("telescope.builtin")
      
      local function find_hidden_files()
        builtin.find_files({
          hidden = true,
          file_ignore_patterns = { "^[^.]" },
          prompt_title = "Find Hidden Files"
        })
      end
      
      vim.keymap.set('n', '<leader>bf', builtin.find_files, {})
      vim.keymap.set('n', '<leader>bh', find_hidden_files, { desc = "Browse Hidden files" })
      vim.keymap.set('n', '<leader>bt', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>be', builtin.diagnostics, { desc = "Browse Errors" })
      vim.keymap.set('n', '<leader>br', builtin.oldfiles, { desc = "Browse Recent files" })
      vim.keymap.set('n', '<leader>bb', builtin.buffers, { desc = "Browse Buffers" })
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          }
        }
      })
      require("telescope").load_extension("ui-select")
    end
  }
}
