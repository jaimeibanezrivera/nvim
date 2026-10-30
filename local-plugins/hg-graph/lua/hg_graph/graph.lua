local M = {}

local NS = vim.api.nvim_create_namespace("hg_graph_glyphs")

local LANES = { "HgGraphLane1", "HgGraphLane2", "HgGraphLane3", "HgGraphLane4" }

function M.define_highlights()
    local lane_colors = {
        { fg = "#4fc1ff", ctermfg = 75 },
        { fg = "#b5e48e", ctermfg = 114 },
        { fg = "#ffd166", ctermfg = 221 },
        { fg = "#e599f7", ctermfg = 176 },
    }
    for i, spec in ipairs(lane_colors) do
        vim.api.nvim_set_hl(0, LANES[i], vim.tbl_extend("force", { default = true }, spec))
        vim.api.nvim_set_hl(0, "hlLevel" .. i, { link = LANES[i], default = true })
    end

    vim.api.nvim_set_hl(0, "HgGraphHead", { fg = "#ff8787", bold = true, default = true })
    vim.api.nvim_set_hl(0, "HgGraphNode", { fg = "#ffe066", bold = true, default = true })
    vim.api.nvim_set_hl(0, "HgGraphMerge", { fg = "#ffa94d", default = true })
    vim.api.nvim_set_hl(0, "HgGraphCap", { fg = "#868e96", default = true })
    vim.api.nvim_set_hl(0, "HgGraphLogMeta", { link = "Comment", default = true })
end

local function lane_hl(col)
    return LANES[(math.floor((col - 1) / 2) % #LANES) + 1]
end

local function revision_col(line)
    return line:find("%d+:[%da-fA-F]+")
end

--- Paint Mercurial graph glyphs (|, o, @, ~, merges) like Lawrencium's hggraphlog view.
---@param buf number
---@param header_rows integer
function M.apply(buf, header_rows)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    M.define_highlights()
    header_rows = header_rows or 0
    vim.api.nvim_buf_clear_namespace(buf, NS, header_rows, -1)

    local lines = vim.api.nvim_buf_get_lines(buf, header_rows, -1, false)
    for index, line in ipairs(lines) do
        local row = header_rows + index - 1
        local rev_col = revision_col(line)
        local graph_end = rev_col and (rev_col - 1) or #line

        for col = 1, graph_end do
            local ch = line:sub(col, col)
            local hl
            if ch == "@" then
                hl = "HgGraphHead"
            elseif ch == "o" then
                hl = "HgGraphNode"
            elseif ch == "|" then
                hl = lane_hl(col)
            elseif ch == "~" then
                hl = "HgGraphCap"
            elseif ch == "/" or ch == "\\" then
                hl = "HgGraphMerge"
            end
            if hl then
                vim.api.nvim_buf_set_extmark(buf, NS, row, col - 1, {
                    end_col = col,
                    hl_group = hl,
                    priority = 20,
                })
            end
        end

        if rev_col then
            local meta_start = line:find("%s%(by .+, .+%)$")
            if meta_start then
                vim.api.nvim_buf_set_extmark(buf, NS, row, meta_start, {
                    end_col = #line,
                    hl_group = "HgGraphLogMeta",
                    priority = 5,
                })
            end
        end
    end
end

return M
