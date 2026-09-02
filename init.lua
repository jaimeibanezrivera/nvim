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
vim.keymap.set("n", "n", "nzz", { desc = "Next search result and center" })
vim.keymap.set("n", "N", "Nzz", { desc = "Previous search result and center" })

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

-- Git: Open configured mergetool
  vim.keymap.set("n", "<leader>gm", function()
      vim.cmd("tabnew")
      vim.cmd("terminal git mergetool")
  end, { desc = "Git mergetool" })

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

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Recover stale swap files automatically, then remove them after a successful save.
local swap_group = vim.api.nvim_create_augroup("auto-swap-recovery", { clear = true })

vim.api.nvim_create_autocmd("SwapExists", {
    group = swap_group,
    callback = function()
        local swap = vim.v.swapname
        local info = vim.fn.swapinfo(swap)

        -- Do not recover a swap belonging to another running Neovim process.
        if not info.pid or info.pid <= 0 then
            vim.v.swapchoice = "r"

            vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = vim.api.nvim_get_current_buf(),
                once = true,
                callback = function()
                    vim.fn.delete(swap)
                end,
            })
        end
    end,
})

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

-- Keep Zellij theme in sync with the Neovim colorscheme.
-- Map Neovim colorscheme names to Zellij themes. Values may be either:
--   * a string  -> used as-is
--   * a table   -> { dark = "...", light = "..." }, resolved via vim.o.background
-- Unknown schemes fall back to `zellij_fallback_theme` so we never leave Zellij
-- pointing at a missing theme.
local nvim_to_zellij_theme = {
    -- User-installed Zellij themes (in ~/.config/zellij/themes/).
    juliana = "juliana",
    PaperColor = "pencil-light-visible-selection",

    -- Zellij built-ins with exact name matches.
    onedark = "onedark",
    ["catppuccin-latte"] = "catppuccin-latte",
    ["catppuccin-frappe"] = "catppuccin-frappe",
    ["catppuccin-macchiato"] = "catppuccin-macchiato",
    ["catppuccin-mocha"] = "catppuccin-mocha",
    nightfox = "nightfox",
    dayfox = "dayfox",
    terafox = "terafox",

    -- Kanagawa variants collapse onto the single Zellij `kanagawa` theme.
    kanagawa = "kanagawa",
    ["kanagawa-wave"] = "kanagawa",
    ["kanagawa-dragon"] = "kanagawa",

    -- Ayu variants (Neovim colorscheme names from `Shatur/neovim-ayu`).
    ["ayu-dark"] = "ayu-dark",
    ["ayu-mirage"] = "ayu-mirage",
    ["ayu-light"] = "ayu-light",

    -- Colorschemes whose light/dark flavor is driven by `vim.o.background`.
    ["gruvbox-material"] = { dark = "gruvbox-dark", light = "gruvbox-light" },
    everforest = { dark = "everforest-dark", light = "everforest-light" },
}
local zellij_fallback_theme = "onedark"

local function resolve_zellij_theme(nvim_scheme, is_dark)
    local mapping = nvim_to_zellij_theme[nvim_scheme]
    if type(mapping) == "string" then
        return mapping
    elseif type(mapping) == "table" then
        return is_dark and mapping.dark or mapping.light
    end
end

local function sync_zellij_theme()
    local zellij_config = vim.fn.expand("~/.config/zellij/config.kdl")
    local is_dark = vim.o.background == "dark"
    local mode_file = vim.fn.expand("~/.config/theme-mode")

    -- Make light/dark mode available to shell prompts.
    vim.fn.writefile({ is_dark and "dark" or "light" }, mode_file)

    local current = vim.g.colors_name or ""
    local target_theme = resolve_zellij_theme(current, is_dark) or zellij_fallback_theme

    if vim.fn.filereadable(zellij_config) ~= 1 then
        return
    end

    local lines = vim.fn.readfile(zellij_config)
    local desired_line = string.format('theme "%s"', target_theme)
    local updated = false

    for i, line in ipairs(lines) do
        if line:match('^theme%s+".+"$') then
            if line ~= desired_line then
                lines[i] = desired_line
                updated = true
            end
            break
        end
    end

    if updated then
        vim.fn.writefile(lines, zellij_config)
    end
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("sync-zellij-theme", { clear = true }),
    callback = sync_zellij_theme,
})

-- Ensure sync happens at startup for the currently loaded colorscheme.
sync_zellij_theme()
