local icons = require("hg_graph.icons")

local M = {}

M.ROW_COUNT = 3

---@param loaded integer commit count in the cached log
---@param topic_filter? string
---@param filtered? integer matching commits when a topic filter is active
---@return string[]
function M.lines(loaded, topic_filter, filtered)
    local filter_note = topic_filter and ("  ·  topic «" .. topic_filter .. "»") or "  ·  all topics"
    local count_note = topic_filter and filtered and string.format("  ·  showing %d", filtered) or ""
    return {
        string.format("Hg Graph  ·  %d commits loaded%s%s", loaded, filter_note, count_note),
        table.concat({
            icons.close .. " q  quit",
            icons.changeset .. " Enter/o  open whole commit",
            icons.info .. " Tab  file list popup",
            icons.filter .. " f  filter topic",
            icons.help .. " ?  keys",
        }, "    "),
        "",
    }
end

---@param buf number
---@param limit integer
---@param topic_filter? string
---@param visible? integer
function M.paint(buf)
    vim.b[buf].hg_graph_header_rows = M.ROW_COUNT
    for row = 0, M.ROW_COUNT - 2 do
        vim.api.nvim_buf_add_highlight(buf, -1, "Comment", row, 0, -1)
    end
end

return M
