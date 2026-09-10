return{
  "nvim-lualine/lualine.nvim",
  config = function()
    require('lualine').setup({
      options = {
        theme = 'auto'
      },
      sections = {
        lualine_b = {
          {
            function()
              return vim.b.hg_location or vim.b.hgsigns_head or ""
            end,
            icon = "",
            cond = function()
              local location = vim.b.hg_location or vim.b.hgsigns_head
              return location ~= nil and location ~= ""
            end,
          },
          "branch",
          "diff",
          "diagnostics",
        },
      },
    })
  end
}
