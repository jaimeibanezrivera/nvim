return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
  keys = {
    { "<leader>do", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
    { "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
    { "<leader>dh", "<cmd>DiffviewFileHistory<CR>", desc = "File History" },
  },
  config = function()
    local diffview = require("diffview")

    diffview.setup({
      -- Example options
      enhanced_diff_hl = true,
    })

    -- Keep the diff background tints from the colorscheme, but drop the
    -- red/green foreground so the text keeps its normal color.
    local diff_groups = {
      "DiffAdd",
      "DiffDelete",
      "DiffChange",
      "DiffText",
      "DiffviewDiffAdd",
      "DiffviewDiffDelete",
      "DiffviewDiffChange",
      "DiffviewDiffText",
      "DiffviewDiffAddAsDelete",
    }

    local function neutral_diff_text()
      for _, name in ipairs(diff_groups) do
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        if hl.bg then
          vim.api.nvim_set_hl(0, name, { bg = hl.bg })
        end
      end
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = neutral_diff_text,
    })
    neutral_diff_text()
  end,
}
