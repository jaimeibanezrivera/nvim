-- mercurial.log_graph: read-only commit graph viewer.
--
-- Runs `hg log --graph` asynchronously and displays the output in a centered
-- floating scratch buffer. Close with q or <Esc>. Nvim's native `/` search
-- and yank both work as expected.

local M = {}

local defaults = {
  keymap = "<leader>hl",
  cmd_name = "HgLog",
  limit = 200,
  -- Passed to `hg log --template`. Kept plain so the graph column stays aligned.
  template = "{rev}:{node|short} {user|user} {date|shortdate} {desc|firstline}\n",
  border = "rounded",
  width_ratio = 0.85,
  height_ratio = 0.8,
}

local config = vim.deepcopy(defaults)

local function open(opts)
  opts = opts or {}
  local limit = opts.limit or config.limit

  vim.system({
    "hg", "log", "--graph",
    "--limit", tostring(limit),
    "--template", config.template,
  }, { text = true }, vim.schedule_wrap(function(obj)
    if obj.code ~= 0 then
      local err = ((obj.stderr or ""):gsub("%s+$", ""))
      vim.notify("hg log failed: " .. (err ~= "" and err or "exit " .. obj.code),
        vim.log.levels.ERROR)
      return
    end

    local lines = vim.split(obj.stdout or "", "\n", { trimempty = true })
    if #lines == 0 then
      vim.notify("no commits", vim.log.levels.INFO)
      return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "hglog"

    local width = math.floor(vim.o.columns * config.width_ratio)
    local height = math.floor(vim.o.lines * config.height_ratio)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      border = config.border,
      title = " hg log --graph ",
      title_pos = "center",
    })

    vim.keymap.set("n", "q", "<cmd>close<cr>",
      { buffer = buf, silent = true, desc = "Close hg log" })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>",
      { buffer = buf, silent = true, desc = "Close hg log" })
  end))
end

M.open = open

function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  vim.api.nvim_create_user_command(config.cmd_name, function(args)
    open({ limit = args.args ~= "" and tonumber(args.args) or nil })
  end, { nargs = "?", desc = "Show hg log --graph in a floating window" })

  if config.keymap then
    vim.keymap.set("n", config.keymap, function() open() end,
      { desc = "hg log --graph" })
  end
end

return M
