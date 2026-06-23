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
            { out,                            "WarningMsg" },
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

-- Navigation: Center screen after half-page movements
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up and center" })
vim.keymap.set("n", "<C-o>", "<C-o>zz", { desc = "Jump back and center" })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { desc = "Jump forward and center" })

-- Diagnostics: Navigate errors
vim.keymap.set("n", "]e", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to next error" })
vim.keymap.set("n", "[e", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to previous error" })
vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1 })
end, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1 })
end, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "<leader>e", function()
    local _, win = vim.diagnostic.open_float()
    if win then
        vim.api.nvim_set_current_win(win)
    end
end, { desc = "Focus diagnostic float" })

-- Splits
vim.keymap.set("n", "<leader>s", "<cmd>vsplit<CR>", { desc = "Vertical split" })

-- Copy file path to clipboard (relative if possible, absolute otherwise)
vim.keymap.set("n", "<leader>cp", function()
    local abs = vim.fn.expand("%:p")
    local rel = vim.fn.fnamemodify(abs, ":~:.")
    local path = (rel ~= "" and rel ~= abs) and rel or abs
    vim.fn.setreg("+", path)
    print("Copied: " .. path)
end, { desc = "Copy file path to clipboard" })

-- Terminal: Toggle split terminal (opens or closes+deletes the buffer)
local term_buf = nil
local term_win = nil

vim.keymap.set("n", "<C-j>", function()
    -- If window is open, close it and delete the buffer
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, true)
        if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
            vim.api.nvim_buf_delete(term_buf, { force = true })
        end
        term_buf = nil
        term_win = nil
        return
    end
    -- Open a new terminal split
    vim.cmd.vnew()
    vim.cmd.term()
    vim.cmd.wincmd("J")
    vim.api.nvim_win_set_height(0, 11)
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
    vim.cmd("startinsert")
end, { desc = "Toggle split terminal" })

local function close_terminal()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, true)
    end
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_buf_delete(term_buf, { force = true })
    end
    term_buf = nil
    term_win = nil
end

vim.keymap.set("t", "<C-j>", close_terminal, { noremap = true, silent = true, desc = "Close terminal buffer" })

-- Theme: Toggle between light and dark mode
vim.keymap.set("n", "<leader>lm", function()
    vim.o.background = vim.o.background == "dark" and "light" or "dark"
    vim.cmd.colorscheme("gruvbox-material")
    print("Switched to gruvbox " .. vim.o.background .. " mode")
end, { desc = "Toggle Light/Dark Mode" })

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Remove trailing whitespaces
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = "%s/\\s\\+$//e",
})
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
local colorscheme_file = vim.fn.stdpath("config") .. "/.colorscheme"
local f = io.open(colorscheme_file, "r")
local saved = f and f:read("*l")
if f then
    f:close()
end
vim.cmd.colorscheme(saved or "gruvbox-material")

-- Keep Zellij theme in sync with Neovim light/dark mode.
-- Light uses the local PaperColor-compatible theme; dark uses a built-in theme.
local function sync_zellij_theme()
    local zellij_config = vim.fn.expand("~/.config/zellij/config.kdl")
    local is_dark = vim.o.background == "dark"
    local target_theme = is_dark and "onedark" or "pencil-light-visible-selection"
    local mode_file = vim.fn.expand("~/.config/theme-mode")

    -- Make light/dark mode available to shell prompts.
    vim.fn.writefile({ is_dark and "dark" or "light" }, mode_file)

    if vim.fn.filereadable(zellij_config) == 1 then
        local lines = vim.fn.readfile(zellij_config)
        local updated = false

        for i, line in ipairs(lines) do
            if line:match('^theme%s+".+"$') then
                lines[i] = string.format('theme "%s"', target_theme)
                updated = true
                break
            end
        end

        if updated then
            vim.fn.writefile(lines, zellij_config)
        end
    end
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("sync-zellij-theme", { clear = true }),
    callback = sync_zellij_theme,
})

-- Ensure sync happens at startup for the currently loaded colorscheme.
sync_zellij_theme()
