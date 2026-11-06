return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  config = function()
    _G._oil_winbar = function()
      local dir = require("oil").get_current_dir()
      if not dir then return "" end
      local cwd = vim.fn.getcwd() .. "/"
      if dir:sub(1, #cwd) == cwd then
        return dir:sub(#cwd + 1)
      end
      return dir
    end

    require("oil").setup({
      win_options = {
        winbar = "%{%v:lua._G._oil_winbar()%}",
      },
      float = {
        padding = 0,
        override = function(conf)
          local win = vim.api.nvim_get_current_win()
          local pos = vim.fn.win_screenpos(win)
          conf.relative = "editor"
          conf.row = pos[1] - 1
          conf.col = pos[2] - 1
          conf.width = vim.api.nvim_win_get_width(win)
          conf.height = vim.api.nvim_win_get_height(win)
          return conf
        end,
      },
    })

    vim.keymap.set("n", "-", "<cmd>Oil --float<CR>", { desc = "Open Oil file browser" })
  end,
}
