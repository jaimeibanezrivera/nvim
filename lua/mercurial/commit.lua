local M = {}

local commit_term

function M.toggle_interactive()
  local Terminal = require("toggleterm.terminal").Terminal

  if not commit_term then
    commit_term = Terminal:new({
      cmd = "hg commit -i",
      direction = "float",
      hidden = true,
      close_on_exit = true,
    })
  end

  commit_term:toggle()
end

return M
