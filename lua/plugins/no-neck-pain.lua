-- lua/plugins/no-neck-pain.lua

return {
  "shortcuts/no-neck-pain.nvim",
  config = function()
    require("no-neck-pain").setup({
      -- Add your configuration options here
      -- For example:
      width = 100,
      buffers = {
        right = {
          enabled = false,
        },
      },
    })
  end,
}
