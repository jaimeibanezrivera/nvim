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

      local builtin = require("telescope.builtin")
      vim.keymap.set('n', '<leader>b', builtin.find_files, {})  -- Browse for file
      vim.keymap.set('n', '<leader>bh', builtin.live_grep, {})  -- Browse Here
      vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = "View Git Commits" }) --Git commits
      vim.keymap.set('n', '<leader>gch', builtin.git_bcommits, { desc = "View Git Buffer Commits" }) -- Git Commits Here
      vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = "View Git Status" }) -- Git Status
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
