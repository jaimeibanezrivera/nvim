return {
  "smithbm2316/centerpad.nvim",
  config = function()
    -- Optional keymaps
    vim.keymap.set("n", "<leader>z", ":Centerpad<CR>", { desc = "Center buffer" })
  end
}
