-- lua/plugins/ui/minimap.lua

-- Mercurial hunks (from hgsigns) shown in the minimap, same shape as the
-- built-in gitsigns integration. Returns {} outside of hg repos.
local function hgsigns_integration(hl_groups)
  return function()
    local has_hgsigns, hgsigns = pcall(require, "hgsigns")
    if not has_hgsigns then return {} end

    local source = require("mini.map").current.buf_data.source
    local has_hunks, hunks = pcall(hgsigns.get_hunks, source)
    if not has_hunks or hunks == nil then return {} end

    local res = {}
    for _, h in ipairs(hunks) do
      local n_added, n_removed = h.added.count, h.removed.count
      for i = 1, math.max(n_added, 1) do
        local hl_type = (n_added < i and "delete") or (i <= n_removed and "change" or "add")
        if hl_groups[hl_type] then
          table.insert(res, { line = h.added.start + i - 1, hl_group = hl_groups[hl_type] })
        end
      end
    end
    return res
  end
end

return {
  -- Code minimap shown on the right side of the window
  "nvim-mini/mini.map",
  event = "BufReadPost",
  config = function()
    local map = require("mini.map")
    local hl = { add = "DiffAdd", change = "DiffChange", delete = "DiffDelete" }

    -- Refresh the minimap when hgsigns finishes updating hunks
    vim.api.nvim_create_autocmd("User", {
      pattern = "HgsignsUpdate",
      callback = function() map.refresh() end,
    })

    map.setup({
      integrations = {
        map.gen_integration.diagnostic(),
        map.gen_integration.gitsigns(hl),
        hgsigns_integration(hl),
      },
      symbols = { encode = map.gen_encode_symbols.dot("4x2") },
      window = { width = 10, winblend = 25 },
    })
    vim.keymap.set("n", "<leader>mm", map.toggle, { desc = "Toggle minimap" })
  end,
}
