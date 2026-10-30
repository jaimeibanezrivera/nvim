local M = {}

local NS = vim.api.nvim_create_namespace("hg_graph_log")

local palette = {
    { name = "HgGraphTopicPurple", fg = "#af5fd7", ctermfg = 141 },
    { name = "HgGraphTopicLightBlue", fg = "#87d7ff", ctermfg = 117 },
    { name = "HgGraphTopicDarkBlue", fg = "#3a6ea5", ctermfg = 25 },
    { name = "HgGraphTopicOrange", fg = "#ff9f1c", ctermfg = 214 },
    { name = "HgGraphTopicMagenta", fg = "#d65d9a", ctermfg = 169 },
    { name = "HgGraphTopicTeal", fg = "#2ec4b6", ctermfg = 43 },
    { name = "HgGraphTopicGold", fg = "#e9c46a", ctermfg = 221 },
    { name = "HgGraphTopicBrown", fg = "#bc6c25", ctermfg = 166 },
    { name = "HgGraphTopicCyan", fg = "#4cc9f0", ctermfg = 81 },
    { name = "HgGraphTopicViolet", fg = "#7b2cbf", ctermfg = 98 },
    { name = "HgGraphTopicPink", fg = "#f72585", ctermfg = 205 },
    { name = "HgGraphTopicIndigo", fg = "#4361ee", ctermfg = 63 },
    { name = "HgGraphTopicLavender", fg = "#c77dff", ctermfg = 177 },
    { name = "HgGraphTopicSky", fg = "#00b4d8", ctermfg = 38 },
    { name = "HgGraphTopicCoral", fg = "#ee6c4d", ctermfg = 209 },
}

local function hsl_to_hex(h, s, l)
    h = h % 360
    local function channel(n)
        local k = (n + h / 30) % 12
        local a = s * math.min(l, 1 - l)
        local c = l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
        return math.floor(c * 255 + 0.5)
    end
    return string.format("#%02x%02x%02x", channel(0), channel(8), channel(4))
end

function M.define_highlights()
    local dark = vim.o.background ~= "light"
    vim.api.nvim_set_hl(0, "HgGraphSecret", {
        fg = dark and "#7c6f64" or "#928374",
        ctermfg = dark and 8 or 243,
        default = true,
    })
    vim.api.nvim_set_hl(0, "HgGraphDraft", { fg = "#e03131", ctermfg = 1, default = true })
    vim.api.nvim_set_hl(0, "HgGraphDefault", { fg = "#2f9e44", ctermfg = 2, default = true })
    vim.api.nvim_set_hl(0, "HgGraphPublic", { fg = "#74c0fc", ctermfg = 111, default = true })

    for _, color in ipairs(palette) do
        vim.api.nvim_set_hl(0, color.name, { fg = color.fg, ctermfg = color.ctermfg, default = true })
    end
end

local function topic_highlight(index)
    local color = palette[index]
    if color then
        return color.name
    end
    local name = "HgGraphTopicGen" .. index
    local hue = (270 + (index - 1) * 47) % 360
    if hue < 20 or hue > 345 then
        hue = (hue + 40) % 360
    end
    if hue > 95 and hue < 150 then
        hue = 155
    end
    vim.api.nvim_set_hl(0, name, { fg = hsl_to_hex(hue, 0.72, 0.55), default = true })
    return name
end

local function line_highlight(info, topic_keys)
    if info.topic ~= "" then
        return topic_keys["topic:" .. info.topic]
    end
    if info.phase == "secret" then
        return "HgGraphSecret"
    end
    if info.phase == "draft" then
        return "HgGraphDraft"
    end
    if info.branch == "default" then
        return "HgGraphDefault"
    end
    return topic_keys["branch:" .. info.branch] or "HgGraphPublic"
end

local function revision_on_line(line)
    return line:match("(%d+):[%da-fA-F]+")
end

--- Column where the changeset id starts (graph prefix stays uncolored for hggraphlog syntax).
local function revision_col(line)
    return line:find("%d+:[%da-fA-F]+")
end

---@param commit_meta table<string, { phase: string, branch: string, topic: string }>
---@param buf number
---@param header_rows integer
function M.apply(buf, commit_meta, header_rows)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    M.define_highlights()
    header_rows = header_rows or 0

    local lines = vim.api.nvim_buf_get_lines(buf, header_rows, -1, false)
    local revisions = {}
    for _, line in ipairs(lines) do
        local rev = revision_on_line(line)
        if rev and commit_meta[rev] then
            revisions[#revisions + 1] = rev
        end
    end

    local topic_keys = {}
    local next_topic = 1
    for _, rev in ipairs(revisions) do
        local info = commit_meta[rev]
        local key
        if info.topic ~= "" then
            key = "topic:" .. info.topic
        elseif info.phase == "public" and info.branch ~= "default" then
            key = "branch:" .. info.branch
        end
        if key and not topic_keys[key] then
            topic_keys[key] = topic_highlight(next_topic)
            next_topic = next_topic + 1
        end
    end

    vim.api.nvim_buf_clear_namespace(buf, NS, header_rows, -1)

    for index, line in ipairs(lines) do
        local row = header_rows + index - 1
        local rev = revision_on_line(line)
        local info = rev and commit_meta[rev]
        if info then
            local hl = line_highlight(info, topic_keys)
            if hl then
                local col0 = (revision_col(line) or 1) - 1
                local opts = {
                    end_row = row,
                    end_col = #line,
                    hl_group = hl,
                }
                if info.topic ~= "" then
                    opts.virt_text = { { "  " .. info.topic, hl } }
                    opts.virt_text_pos = "eol"
                end
                vim.api.nvim_buf_set_extmark(buf, NS, row, col0, opts)
            end
        end
    end
end

return M
