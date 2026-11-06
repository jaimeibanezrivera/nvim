return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      window = {
        width = auto,
        win_options = {
          signcolumn = "auto",
        },
      },
      filesystem = {
        group_empty_dirs = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        hijack_netrw_behavior = "open_default",
      },
      event_handlers = {
        {
          event = "file_opened",
          handler = function(file_path)
            -- auto close Neo-tree once a file is opened
            require("neo-tree.command").execute({ action = "close" })
          end
        },
      },
    })

    vim.keymap.set("n", "<leader>n", function()
      require("neo-tree.command").execute({
        toggle = true,
        position = "left",  -- open inside the active split
        source = "filesystem",
      })
    end, { desc = "Toggle Neo-tree" })
  end
}
