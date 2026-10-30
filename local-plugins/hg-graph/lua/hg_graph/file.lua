local hg = require("hg_graph.hg")

local M = {}

local function hg_cat(root, rev, path)
    local result = hg.run_hg(root, { "cat", "-r", tostring(rev), "path:" .. path })
    if result.code ~= 0 then
        return nil, vim.trim(result.stderr or "hg cat failed")
    end
    return result.stdout or ""
end

--- Open the file as it exists in the working tree (repo root relative path).
---@param root string
---@param path string
---@return boolean
function M.open_worktree(root, path)
    local full = vim.fs.joinpath(root, path)
    if vim.fn.filereadable(full) ~= 1 then
        vim.notify("File not in working tree: " .. path, vim.log.levels.WARN)
        return false
    end
    vim.cmd("edit " .. vim.fn.fnameescape(full))
    return true
end

--- Open file contents at a Mercurial revision (read-only scratch buffer).
---@param root string
---@param rev integer|string
---@param path string
---@param label? string
function M.open_at_rev(root, rev, path, label)
    local content, err = hg_cat(root, rev, path)
    if content == nil then
        vim.notify(err or "Could not read file at revision", vim.log.levels.ERROR)
        return
    end

    local ext = vim.fn.fnamemodify(path, ":e")
    local tmp = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or "")
    local f = io.open(tmp, "w")
    if not f then
        vim.notify("Could not create temp file", vim.log.levels.ERROR)
        return
    end
    f:write(content)
    f:close()

    local title = string.format("%s @ r%s", path, label or rev)
    vim.cmd("edit " .. vim.fn.fnameescape(tmp))
    vim.cmd("setlocal buftype=nofile noswapfile nobuflisted bufhidden=wipe nomodifiable")
    vim.api.nvim_buf_set_name(0, title)
end

return M
