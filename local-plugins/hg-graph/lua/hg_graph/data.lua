local hg = require("hg_graph.hg")

local M = {}

local FIELD = hg.FIELD

local commit_template = table.concat({
    "{rev}",
    "{node}",
    "{p1rev}",
    "{p2rev}",
    "{topic}",
    "{phase}",
    "{author|person}",
    "{date|isodatesec}",
    "{branch}",
    "{desc}",
}, FIELD)

---@param diff string
---@return table<string, { added: integer, deleted: integer, binary: boolean }>
local function diff_stats(diff)
    local stats = {}
    local current
    local in_hunk = false

    for line in vim.gsplit(diff, "\n", { plain = true }) do
        if vim.startswith(line, "diff --git a/") then
            local length = (#line - 16) / 2
            local old_path = line:sub(14, 13 + length)
            local new_path = line:sub(17 + length)
            current = { added = 0, deleted = 0, binary = false }
            local path = old_path == new_path and old_path or new_path
            stats[path] = current
            in_hunk = false
        elseif not current then
            -- skip
        elseif not in_hunk and vim.startswith(line, "rename to ") then
            stats[line:sub(11)] = current
        elseif not in_hunk and vim.startswith(line, "copy to ") then
            stats[line:sub(9)] = current
        elseif line == "GIT binary patch" or vim.startswith(line, "Binary file") then
            current.binary = true
        elseif vim.startswith(line, "@@") then
            in_hunk = true
        elseif in_hunk and vim.startswith(line, "+") then
            current.added = current.added + 1
        elseif in_hunk and vim.startswith(line, "-") then
            current.deleted = current.deleted + 1
        end
    end

    return stats
end

---@param root string
---@param rev string|integer
---@return table? commit
---@return string? error
function M.commit_at_rev(root, rev)
    local result = hg.run_hg(root, {
        "log",
        "-r",
        tostring(rev),
        "-T",
        commit_template,
    })

    if result.code ~= 0 then
        return nil, vim.trim(result.stderr or "hg log failed")
    end

    local record = vim.trim(result.stdout or "")
    if record == "" then
        return nil, "No such revision"
    end

    local parts = vim.split(record, FIELD, { plain = true })
    local rev_n = tonumber(parts[1])
    local p1 = tonumber(parts[3])
    local p2 = tonumber(parts[4])
    local parents = {}
    if p1 and p1 >= 0 then
        parents[#parents + 1] = p1
    end
    if p2 and p2 >= 0 then
        parents[#parents + 1] = p2
    end

    return {
        rev = rev_n,
        node = parts[2],
        short_node = parts[2]:sub(1, 12),
        parents = parents,
        topic = parts[5] or "",
        phase = parts[6] or "",
        author = parts[7] or "",
        date = parts[8] or "",
        branch = parts[9] or "default",
        description = parts[10] or "",
    }
end

---@param root string
---@param rev string|integer
---@return table[] files
---@return string? error
function M.changed_files(root, rev)
    local status_result = hg.run_hg(root, { "status", "--change", tostring(rev) })
    if status_result.code ~= 0 then
        return {}, vim.trim(status_result.stderr or "hg status failed")
    end

    local diff_result = hg.run_hg(root, { "diff", "--git", "-c", tostring(rev) })
    local stats = {}
    if diff_result.code == 0 then
        stats = diff_stats(diff_result.stdout or "")
    end

    local files = {}
    for line in vim.gsplit(status_result.stdout or "", "\n", { plain = true }) do
        if line ~= "" then
            local status = line:sub(1, 1)
            local path = line:sub(3)
            local file = { status = status, path = path }
            local st = stats[path]
            if st then
                file.added = st.added
                file.deleted = st.deleted
                file.binary = st.binary
            end
            files[#files + 1] = file
        end
    end

    return files
end

local function files_from_hg_output(status_stdout, diff_stdout)
    local stats = {}
    if diff_stdout then
        stats = diff_stats(diff_stdout)
    end

    local files = {}
    for line in vim.gsplit(status_stdout or "", "\n", { plain = true }) do
        if line ~= "" then
            local status = line:sub(1, 1)
            local path = line:sub(3)
            local file = { status = status, path = path }
            local st = stats[path]
            if st then
                file.added = st.added
                file.deleted = st.deleted
                file.binary = st.binary
            end
            files[#files + 1] = file
        end
    end
    return files
end

---@param root string
---@param rev string|integer
---@param on_done fun(result: { commit?: table, files?: table[], error?: string })
function M.load_details_async(root, rev, on_done)
    local rev_s = tostring(rev)
    local commit
    local status_out, diff_out
    local status_code, diff_code
    local pending = 3

    local function finish()
        pending = pending - 1
        if pending > 0 then
            return
        end
        if not commit then
            on_done({ error = "Could not read changeset" })
            return
        end
        if status_code ~= 0 then
            on_done({ error = "hg status failed" })
            return
        end
        on_done({
            commit = commit,
            files = files_from_hg_output(status_out, diff_out),
        })
    end

    vim.system({
        "hg",
        "--cwd",
        root,
        "log",
        "-r",
        rev_s,
        "-T",
        commit_template,
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 or vim.trim(result.stdout or "") == "" then
                commit = nil
            else
                local parts = vim.split(vim.trim(result.stdout), FIELD, { plain = true })
                local rev_n = tonumber(parts[1])
                local p1 = tonumber(parts[3])
                local p2 = tonumber(parts[4])
                local parents = {}
                if p1 and p1 >= 0 then
                    parents[#parents + 1] = p1
                end
                if p2 and p2 >= 0 then
                    parents[#parents + 1] = p2
                end
                commit = {
                    rev = rev_n,
                    node = parts[2],
                    short_node = parts[2]:sub(1, 12),
                    parents = parents,
                    topic = parts[5] or "",
                    phase = parts[6] or "",
                    author = parts[7] or "",
                    date = parts[8] or "",
                    branch = parts[9] or "default",
                    description = parts[10] or "",
                }
            end
            finish()
        end)
    end)

    vim.system({
        "hg",
        "--cwd",
        root,
        "status",
        "--change",
        rev_s,
    }, { text = true }, function(result)
        vim.schedule(function()
            status_code = result.code
            status_out = result.stdout
            finish()
        end)
    end)

    vim.system({
        "hg",
        "--cwd",
        root,
        "diff",
        "--git",
        "-c",
        rev_s,
    }, { text = true }, function(result)
        vim.schedule(function()
            diff_code = result.code
            diff_out = result.code == 0 and result.stdout or ""
            finish()
        end)
    end)
end

--- Topic label used by the Cursor graph (topic, else branch).
---@param root string
---@param limit? integer
---@return string[]
function M.topic_names(root, limit)
    limit = limit or 300
    local result = hg.run_hg(root, {
        "log",
        "-r",
        string.format("last(::., %d)", limit),
        "-T",
        '{ifeq(topic, "", branch, topic)}\n',
    })

    if result.code ~= 0 then
        return {}
    end

    local seen = {}
    local names = {}
    for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
        line = vim.trim(line)
        if line ~= "" and not seen[line] then
            seen[line] = true
            names[#names + 1] = line
        end
    end
    table.sort(names)
    return names
end

---@param root string
---@return string?
function M.current_topic_name(root)
    local result = hg.run_hg(root, {
        "log",
        "-r",
        ".",
        "-T",
        '{ifeq(topic, "", branch, topic)}\n',
    })
    if result.code ~= 0 then
        return nil
    end
    local name = vim.trim(result.stdout or "")
    if name == "" then
        return nil
    end
    return name
end

return M
