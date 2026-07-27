local M = {}

local signs = {
  add = { text = "│" },
  change = { text = "│" },
  delete = { text = "_" },
  topdelete = { text = "‾" },
  changedelete = { text = "~" },
}

local function get_cursor_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local bcache = require("hgsigns.cache").cache[bufnr]
  if not bcache then
    return nil, nil
  end

  return bcache, bcache:get_cursor_hunk()
end

local function warn_no_repo()
  vim.notify("Not in a Mercurial repository buffer.", vim.log.levels.WARN)
end

local function warn_no_hunk()
  vim.notify(
    "No change at the cursor. Edit the file first, then put the cursor on a changed line (look for │ in the gutter).",
    vim.log.levels.WARN
  )
end

function M.preview_hunk()
  local bcache, hunk = get_cursor_hunk()
  if not bcache then
    warn_no_repo()
    return
  end
  if not hunk then
    warn_no_hunk()
    return
  end

  require("hgsigns").preview_hunk()
end

function M.preview_hunk_inline()
  local bcache, hunk = get_cursor_hunk()
  if not bcache then
    warn_no_repo()
    return
  end
  if not hunk then
    warn_no_hunk()
    return
  end

  require("hgsigns").preview_hunk_inline()
end

function M.reset_hunk()
  local bcache, hunk = get_cursor_hunk()
  if not bcache then
    warn_no_repo()
    return
  end
  if not hunk then
    warn_no_hunk()
    return
  end

  require("hgsigns").reset_hunk()
end

function M.on_attach(bufnr)
  local hgsigns = require("hgsigns")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "]c", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      hgsigns.nav_hunk("next")
    end
  end, "Next hg hunk")

  map("n", "[c", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      hgsigns.nav_hunk("prev")
    end
  end, "Previous hg hunk")

  map("n", "<leader>gb", hgsigns.toggle_current_line_blame, "Toggle hg blame")
  map("n", "<leader>gp", M.preview_hunk, "Preview hg hunk (popup)")
  map("n", "<leader>gi", M.preview_hunk_inline, "Preview hg hunk (inline)")
  map("n", "<leader>gr", M.reset_hunk, "Reset hg hunk")
  map("n", "<leader>gd", hgsigns.diffthis, "Hg diff this file")
end

function M.setup()
  require("hgsigns").setup({
    signs = signs,
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
      ignore_whitespace = false,
    },
    current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
    on_attach = M.on_attach,
  })
end

return M
