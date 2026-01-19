vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.g.mapleader = " "
vim.cmd("set clipboard+=unnamedplus")
vim.cmd("set autoindent")
vim.cmd("set cursorline")

--mini terminal config
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		vim.opt.number = false
		vim.opt.relativenumber = false
	end,
})

vim.keymap.set("n", "<leader>st", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 11)
	vim.cmd("startinsert") -- Automatically enter terminal mode
end)

-- Define a global variable to track the current theme mode
vim.g.current_theme_mode = "dark" -- Initialize to dark mode

-- Function to toggle between dark and light Gruvbox Material
local function toggle_background()
    if vim.o.background == "dark" then
        vim.o.background = "light"
    else
        vim.o.background = "dark"
    end
    -- Reapply your colorscheme so it updates immediately
    vim.cmd.colorscheme("gruvbox-material") -- Apply the initial dark theme
    print("Switched to gruvbox " .. vim.o.background .. " mode")
end
-- Map the toggle function to <leader>lm
vim.keymap.set("n", "<leader>lm", toggle_background, { desc = "Toggle Light/Dark Mode" })
-- Map <leader>q to exit terminal mode
vim.keymap.set("t", "<C-c>", function()
	if vim.bo.buftype == "terminal" then
		vim.cmd("q")
	end
end, { noremap = true, silent = true })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
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

-- Highligh yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})
