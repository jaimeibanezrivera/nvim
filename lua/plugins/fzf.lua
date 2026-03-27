return {
  {
    'junegunn/fzf',
    build = ':call fzf#install()'
  },
  {
    'junegunn/fzf.vim',
    dependencies = { 'junegunn/fzf' },
    config = function()
      -- Make fzf window larger (similar to your 0.9 width/height)
      vim.g.fzf_layout = { window = { width = 0.9, height = 0.9 } }

      -- Find hidden files only
      vim.api.nvim_create_user_command('HiddenFiles', function()
        vim.fn['fzf#run'](vim.fn['fzf#wrap']({
          source = 'find . -type f -name ".*" 2>/dev/null',
          options = '--prompt "Hidden Files> "'
        }))
      end, {})

      vim.keymap.set('n', '<leader>bf', '<cmd>Files<cr>', {})
      vim.keymap.set('n', '<leader>bh', '<cmd>HiddenFiles<cr>', { desc = "Browse Hidden files" })
      vim.keymap.set('n', '<leader>bt', '<cmd>Rg<cr>', {})
      vim.keymap.set('n', '<leader>br', '<cmd>History<cr>', { desc = "Browse Recent files" })
      vim.keymap.set('n', '<leader>bb', '<cmd>Buffers<cr>', { desc = "Browse Buffers" })
    end
  }
}
