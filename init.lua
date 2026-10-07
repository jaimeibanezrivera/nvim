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
local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
if is_ssh then
    -- Send clipboard writes through the SSH connection to the local terminal.
    vim.g.clipboard = "osc52"
else
    vim.opt.clipboard:append("unnamedplus")
end
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

-- Delete leftover swap files and keep editing in this Neovim instance.
-- Still warn if another process on this host appears to own the swap.
local swap_group = vim.api.nvim_create_augroup("auto-swap-recovery", { clear = true })

local function swap_owner_running(info)
    local pid = info.pid
    if type(pid) ~= "number" or pid <= 0 then
        return false
    end

    local hostname = info.hostname or ""
    if hostname ~= "" then
        local this_host = vim.uv.os_gethostname()
        if hostname ~= this_host and hostname ~= vim.fn.hostname() then
            return false
        end
    end

    return vim.uv.kill(pid, 0) == 0
end

vim.api.nvim_create_autocmd("SwapExists", {
    group = swap_group,
    callback = function()
        local swap = vim.v.swapname
        local info = vim.fn.swapinfo(swap)
        vim.v.swapchoice = "d"

        if swap_owner_running(info) then
            vim.notify(
                string.format(
                    "Deleted swap for %s; pid %d may still have it open",
                    vim.fn.fnamemodify(vim.v.swapname, ":t"),
                    info.pid
                ),
                vim.log.levels.WARN
            )
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

        -- Zellij 0.44 can write, but not read, the local clipboard over OSC 52.
        -- Keep normal paste using Neovim's register while copying yanks locally.
        if is_ssh and vim.v.event.operator == "y" then
            require("vim.ui.clipboard.osc52").copy("+")(vim.v.event.regcontents)
        end
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

local cwd = vim.fn.getcwd()

vim.cmd.colorscheme(saved or "gruvbox-material")
