-- ============================================================================
-- BASIC SETTINGS
-- ============================================================================
vim.g.mapleader = " " -- Set leader key first, before any mappings

-- Indentation
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true

-- UI
vim.opt.number = true
vim.opt.cursorline = true

-- System
vim.opt.clipboard:append("unnamedplus")

-- ============================================================================
-- PLUGIN MANAGER (LAZY.NVIM)
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Terminal: Open split terminal
vim.keymap.set("n", "<leader>st", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 11)
	vim.cmd("startinsert")
end, { desc = "Open split terminal" })

-- Terminal: Close terminal buffer
vim.keymap.set("t", "<C-c>", function()
	if vim.bo.buftype == "terminal" then
		vim.cmd("q")
	end
end, { noremap = true, silent = true, desc = "Close terminal buffer" })

-- Theme: Toggle between light and dark mode
vim.keymap.set("n", "<leader>lm", function()
	vim.o.background = vim.o.background == "dark" and "light" or "dark"
	vim.cmd.colorscheme("gruvbox-material")
	print("Switched to gruvbox " .. vim.o.background .. " mode")
end, { desc = "Toggle Light/Dark Mode" })

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Terminal: Disable line numbers in terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
	end,
})

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- ============================================================================
-- THEME
-- ============================================================================
vim.o.background = "dark"
vim.cmd.colorscheme("gruvbox-material")
