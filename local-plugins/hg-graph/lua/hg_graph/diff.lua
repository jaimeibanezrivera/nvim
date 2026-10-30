local hg = require("hg_graph.hg")

local M = {}

local function write_temp(content, suffix)
    local path = vim.fn.tempname() .. suffix
    local f = io.open(path, "w")
    if not f then
        return nil, "Could not create temp file"
    end
    f:write(content or "")
    f:close()
    return path
end

local function hg_cat(root, rev, file)
    if rev == nil then
        return ""
    end
    local result = hg.run_hg(root, { "cat", "-r", tostring(rev), "path:" .. file })
    if result.code ~= 0 then
        return ""
    end
    return result.stdout or ""
end

---@param root string
---@param rev integer
---@param parent integer?
---@param path string
---@param label string?
---@param parent_label string?
function M.open_file_diff(root, rev, parent, path, label, parent_label)
    local left = hg_cat(root, parent, path)
    local right = hg_cat(root, rev, path)

    local left_path, err = write_temp(left, ".parent")
    if not left_path then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end
    local right_path, err2 = write_temp(right, ".rev")
    if not right_path then
        vim.notify(err2, vim.log.levels.ERROR)
        return
    end

    local short = vim.fn.fnamemodify(path, ":t")
    local title = string.format(
        "%s (%s ↔ %s)",
        short,
        parent_label or "empty",
        label or tostring(rev)
    )

    vim.cmd("edit " .. vim.fn.fnameescape(right_path))
    vim.cmd("setlocal buftype=nofile noswapfile nobuflisted bufhidden=wipe")
    vim.cmd("vert diffsplit " .. vim.fn.fnameescape(left_path))
    vim.cmd("setlocal buftype=nofile noswapfile nobuflisted bufhidden=wipe")
    vim.cmd("windo diffthis")
    vim.api.nvim_buf_set_name(0, title)
end

return M
