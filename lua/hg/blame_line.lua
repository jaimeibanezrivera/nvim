-- hg.blame_line: gitsigns-style inline blame for Mercurial.
--
-- Shows author, date and commit message at the end of the current line as
-- virtual text after a short idle delay. Runs `hg blame` asynchronously,
-- caches per-buffer, and refreshes on write.

local M = {}

local ns = vim.api.nvim_create_namespace("hg_blame_line")

-- bufnr -> { [lineno] = "info string" }
local cache = {}
local enabled = true

local defaults = {
  updatetime = 300,
  toggle_keymap = "<leader>hB",
  hl_group = "Comment",
  format = function(entry)
    return string.format("%s, %s • %s (r%s)",
      entry.user, entry.date, entry.desc, entry.rev)
  end,
}

local config = vim.deepcopy(defaults)

local function fetch(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" or vim.bo[bufnr].buftype ~= "" then
    return
  end

  vim.system({
    "hg", "blame",
    "--template", "{rev}\x1f{user|user}\x1f{date|shortdate}\x1f{desc|firstline}\n",
    file,
  }, { text = true }, function(obj)
    if obj.code ~= 0 then
      cache[bufnr] = {}
      return
    end

    local lines, i = {}, 1
    for line in (obj.stdout or ""):gmatch("[^\n]+") do
      local rev, user, date, desc = line:match("^(.-)\x1f(.-)\x1f(.-)\x1f(.*)$")
      if user then
        lines[i] = config.format({
          rev = rev, user = user, date = date, desc = desc,
        })
      end
      i = i + 1
    end
    cache[bufnr] = lines
  end)
end

local function show(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not enabled or not cache[bufnr] then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local info = cache[bufnr][line]
  if not info then
    return
  end
  vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
    virt_text = { { "  " .. info, config.hl_group } },
    virt_text_pos = "eol",
    hl_mode = "combine",
  })
end

local function clear_all()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    pcall(vim.api.nvim_buf_clear_namespace, b, ns, 0, -1)
  end
end

function M.toggle()
  enabled = not enabled
  vim.notify("hg blame line: " .. (enabled and "on" or "off"))
  if not enabled then
    clear_all()
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  vim.opt.updatetime = math.min(vim.opt.updatetime:get(), config.updatetime)

  local grp = vim.api.nvim_create_augroup("HgBlameLine", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = grp,
    callback = function(a) fetch(a.buf) end,
  })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = grp,
    callback = function(a) show(a.buf) end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" }, {
    group = grp,
    callback = function(a)
      vim.api.nvim_buf_clear_namespace(a.buf, ns, 0, -1)
    end,
  })

  if config.toggle_keymap then
    vim.keymap.set("n", config.toggle_keymap, M.toggle,
      { desc = "Toggle inline hg blame" })
  end
end

return M
