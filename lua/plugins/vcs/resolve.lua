-- Labels shown at the end of each conflict marker line (VSCode style)
local ns = vim.api.nvim_create_namespace("resolve_labels")

local function clear_labels(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function label(bufnr, line, text, hl)
  -- `line` is 1-based, extmarks are 0-based
  vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
    virt_text = { { "  " .. text, hl } },
    virt_text_pos = "eol",
  })
end

return {
  -- Highlights conflict markers and gives keymaps to pick a side (git and Mercurial)
  "spacedentist/resolve.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_conflict_detected = function(ev)
      clear_labels(ev.bufnr)
      for _, c in ipairs(ev.conflicts) do
        label(ev.bufnr, c.ours_start, "<< Current change (ours)", "ResolveOursMarker")
        if c.ancestor then
          label(ev.bufnr, c.ancestor, "Base (original, before both changes)", "ResolveAncestorMarker")
        end
        label(ev.bufnr, c.separator, "vs", "ResolveSeparatorMarker")
        label(ev.bufnr, c.theirs_end, ">> Incoming change (theirs)", "ResolveTheirsMarker")
      end
    end,
    on_conflicts_resolved = function(ev)
      clear_labels(ev.bufnr)
    end,
  },
}
