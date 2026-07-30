-- For `plugins/zj-theme.lua` users.
return {
  "jaimeibanezrivera/zj-theme",
  lazy = false,
  config = function()
    require("zj-theme").setup({
      -- see Configuration below
    })
  end,
}
