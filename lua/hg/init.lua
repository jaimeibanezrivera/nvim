-- hg: umbrella module composing Mercurial-related features.
--
-- Each feature lives in its own submodule and can be configured or disabled
-- individually. Pass a table of per-feature options to setup(); pass `false`
-- for a feature to skip loading it entirely.
--
-- Example:
--   require("hg").setup({
--     blame_line = { toggle_keymap = "<leader>hB" },
--     log_graph  = { keymap = "<leader>hl", limit = 500 },
--   })
--
--   require("hg").setup({ blame_line = false })  -- log_graph only

local M = {}

local features = { "blame_line", "log_graph" }

function M.setup(opts)
  opts = opts or {}
  for _, name in ipairs(features) do
    if opts[name] ~= false then
      require("hg." .. name).setup(opts[name])
    end
  end
end

return M
