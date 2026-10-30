local hg = require("hg_graph.hg")

local M = {}

local function revision_on_line(line)
    return line:match("(%d+):[%da-fA-F]+")
end

--- Split log body into blocks (graph continuation lines stick to the previous changeset).
---@param lines string[]
---@return { rev: string?, lines: string[] }[]
function M.split_blocks(lines)
    local blocks = {}
    local current

    for _, line in ipairs(lines) do
        local rev = revision_on_line(line)
        if rev then
            current = { rev = rev, lines = { line } }
            blocks[#blocks + 1] = current
        elseif current then
            current.lines[#current.lines + 1] = line
        else
            blocks[#blocks + 1] = { rev = nil, lines = { line } }
        end
    end

    return blocks
end

---@param info { topic: string, branch: string }
---@return string
function M.topic_label(info)
    return info.topic ~= "" and info.topic or info.branch
end

---@param root string
---@param revisions string[]
---@return table<string, { phase: string, branch: string, topic: string }>
function M.meta_by_rev(root, revisions)
    if #revisions == 0 then
        return {}
    end

    local revset = table.concat(revisions, " or ")
    local result = hg.run_hg(root, {
        "log",
        "-r",
        revset,
        "-T",
        "{rev}\t{phase}\t{branch}\t{topic}\n",
    })

    local map = {}
    if result.code ~= 0 then
        return map
    end

    for rev, phase, branch, topic in (result.stdout or ""):gmatch("(%d+)\t([^\t]*)\t([^\t]*)\t([^\n]*)") do
        map[rev] = {
            phase = phase,
            branch = branch,
            topic = topic,
        }
    end

    return map
end

---@param root string
---@param revisions string[]
---@param on_done fun(map: table<string, { phase: string, branch: string, topic: string }>)
function M.fetch_meta_async(root, revisions, on_done)
    if #revisions == 0 then
        on_done({})
        return
    end

    local revset = table.concat(revisions, " or ")
    vim.system({
        "hg",
        "--cwd",
        root,
        "log",
        "-r",
        revset,
        "-T",
        "{rev}\t{phase}\t{branch}\t{topic}\n",
    }, { text = true }, function(result)
        vim.schedule(function()
            local map = {}
            if result.code == 0 then
                for rev, phase, branch, topic in (result.stdout or ""):gmatch("(%d+)\t([^\t]*)\t([^\t]*)\t([^\n]*)") do
                    map[rev] = {
                        phase = phase,
                        branch = branch,
                        topic = topic,
                    }
                end
            end
            on_done(map)
        end)
    end)
end

---@param topic_label string
---@param filter string
---@return boolean
local function matches(topic_label, filter)
    return topic_label == filter
end

---@param body string[]
---@param topic_filter? string
---@param commit_meta table<string, { phase: string, branch: string, topic: string }>
---@return string[]
function M.apply(body, topic_filter, commit_meta)
    if not topic_filter or topic_filter == "" then
        return vim.deepcopy(body)
    end

    local out = {}
    for _, block in ipairs(M.split_blocks(body)) do
        if not block.rev then
            out[#out + 1] = block.lines[1]
        else
            local info = commit_meta[block.rev]
            local label = info and M.topic_label(info) or ""
            if matches(label, topic_filter) then
                for _, line in ipairs(block.lines) do
                    out[#out + 1] = line
                end
            end
        end
    end

    return out
end

---@param body string[]
---@return string[]
function M.revisions_in_body(body)
    local seen = {}
    local list = {}
    for _, line in ipairs(body) do
        local rev = revision_on_line(line)
        if rev and not seen[rev] then
            seen[rev] = true
            list[#list + 1] = rev
        end
    end
    return list
end

return M
