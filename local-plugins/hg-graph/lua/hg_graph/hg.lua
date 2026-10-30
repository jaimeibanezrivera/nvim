local M = {}

local FIELD = string.char(31)
local RECORD = string.char(30)

M.FIELD = FIELD
M.RECORD = RECORD

---@param root string
---@param args string[]
---@param opts? { text?: boolean, async?: boolean }
function M.run_hg(root, args, opts)
    opts = opts or {}
    local argv = { "hg", "--cwd", root }
    vim.list_extend(argv, args)
    local sys_opts = vim.tbl_extend("force", { text = true }, opts)
    sys_opts.async = nil
    local job = vim.system(argv, sys_opts)
    if opts.async then
        return job
    end
    return job:wait()
end

return M
