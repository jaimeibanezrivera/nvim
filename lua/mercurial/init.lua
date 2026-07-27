--- Mercurial integration for Neovim.
--- Add new hg features as modules under lua/mercurial/ and wire them in lua/plugins/mercurial.lua.
local M = {
  hgsigns = require("mercurial.hgsigns"),
  commit = require("mercurial.commit"),
  log_graph = require("mercurial.log_graph"),
}

return M
