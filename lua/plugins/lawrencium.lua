local function toggle_hg_log(command)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local is_preview = vim.api.nvim_get_option_value("previewwindow", { win = win })
        local is_hg_log = vim.api.nvim_get_option_value("filetype", { buf = buf }) == "hglog"

        if is_preview and is_hg_log then
            vim.api.nvim_win_close(win, true)
            return
        end
    end

    vim.cmd(command)
end

return {
    "gyllstromk/vim-lawrencium",
    lazy = false,
    config = function()
        local group = vim.api.nvim_create_augroup("lawrencium_graph_log", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "hglog",
            callback = function(event)
                -- Lawrencium installs its own mapping after setting the filetype,
                -- so defer ours until its log setup has finished.
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(event.buf) then
                        return
                    end

                    vim.keymap.set("n", "<CR>", function()
                        local line = vim.api.nvim_get_current_line()
                        local revision = line:match("(%d+):[%da-fA-F]+")

                        if not revision then
                            vim.notify("No Mercurial revision found on this line", vim.log.levels.WARN)
                            return
                        end

                        local log_path = vim.fn["lawrencium#parse_lawrencium_path"](
                            vim.api.nvim_buf_get_name(0)
                        )
                        local rev_range = string.format("p1(%s)::%s", revision, revision)

                        vim.cmd(string.format(
                            "DiffviewOpen %s -C%s",
                            rev_range,
                            vim.fn.fnameescape(log_path.root)
                        ))
                    end, {
                        buffer = event.buf,
                        desc = "Open selected Mercurial revision in Diffview",
                    })
                end)
            end,
        })
    end,
    keys = {
        { "<leader>hs", "<cmd>Hgstatus<CR>", desc = "Mercurial status" },
        { "<leader>hd", "<cmd>DiffviewOpen<CR>", desc = "Open Mercurial working changes in Diffview" },
        {
            "<leader>hg",
            function()
                toggle_hg_log("Hglog -l 50 -G")
            end,
            desc = "Toggle Mercurial graph log (50)",
        },
        {
            "<leader>hG",
            function()
                toggle_hg_log("Hglog -l 500 -G")
            end,
            desc = "Toggle Mercurial graph log (500)",
        },
        {
            "<leader>hf",
            function()
                toggle_hg_log("Hglogthis -l 100")
            end,
            desc = "Toggle Mercurial current file log (100)",
        },
        { "<leader>ha", "<cmd>Hgannotate<CR>", desc = "Mercurial annotate current file" },
        { "<leader>hc", "<cmd>Hgcommit<CR>", desc = "Mercurial commit" },
        { "<leader>hr", "<cmd>Hgrecord<CR>", desc = "Mercurial record selected changes" },
    },
}
