return{
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Ensure Telescope is properly loaded before setting up
      local status, telescope = pcall(require, "telescope")
      if not status then
        vim.notify("Telescope not found!", vim.log.levels.ERROR)
        return
      end
      
      -- Configure Telescope layout
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
      
      -- Function to find only hidden files
      local function find_hidden_files()
        builtin.find_files({
          hidden = true,
          file_ignore_patterns = { "^[^.]" }, -- Ignore files that don't start with a dot
          prompt_title = "Find Hidden Files"
        })
      end
      
      vim.keymap.set('n', '<leader>bf', builtin.find_files, {})  -- Browse for file
      vim.keymap.set('n', '<leader>bh', find_hidden_files, { desc = "Browse Hidden files" })  -- Browse Hidden only
      vim.keymap.set('n', '<leader>bt', builtin.live_grep, {})  -- Browse for Text
      vim.keymap.set('n', '<leader>be', builtin.diagnostics, { desc = "Browse Errors" }) -- Browse Errors
      vim.keymap.set('n', '<leader>br', builtin.oldfiles, { desc = "Browse Recent files" }) -- Browse Recent
      vim.keymap.set('n', '<leader>bb', builtin.buffers, { desc = "Browse Buffers" }) -- Browse Buffers
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup ({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              -- even more opts
            }
          }
        }
      })
      require("telescope").load_extension("ui-select")
    end
  }
}
