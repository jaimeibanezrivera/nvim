return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local diffview = require("diffview")

    diffview.setup({
      -- Example options
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_vertical",
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
        file_history = {
          layout = "diff2_vertical",
        },
      },
      default_args = {
        DiffviewOpen = { "--untracked-files=no" },
      },
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>do", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
    vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
    vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory<CR>", { desc = "File History" })
  end
}
