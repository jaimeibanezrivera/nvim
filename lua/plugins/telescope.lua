return {
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
    vim.keymap.set('n', '<leader>b', builtin.find_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  end
}
