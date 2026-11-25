return {
    'lewis6991/gitsigns.nvim',
    config = function()
        require('gitsigns').setup({
            signs = {
                add          = { text = '│' },
                change       = { text = '│' },
                delete       = { text = '_' },
                topdelete    = { text = '‾' },
                changedelete = { text = '~' },
            },
            current_line_blame_opts = {
                virt_text_pos = 'right_align',
            },
            -- Show "author, date - message" when it fits next to the code,
            -- otherwise just the author.
            current_line_blame_formatter = function(_, info)
                local hl = 'GitSignsCurrentLineBlame'
                local author = info.author
                local full = string.format(' %s, %s - %s ', author,
                    os.date('%Y-%m-%d', info.author_time), info.summary)

                local win = vim.api.nvim_get_current_win()
                local textoff = vim.fn.getwininfo(win)[1].textoff
                local code_width = vim.fn.strdisplaywidth(vim.api.nvim_get_current_line())
                local room = vim.api.nvim_win_get_width(win) - textoff - code_width

                local text = full
                if vim.fn.strdisplaywidth(full) > room then
                    text = ' ' .. author .. ' '
                end
                return { { text, hl } }
            end,
        })
        -- Keymap to toggle git blame
        vim.keymap.set('n', '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<cr>',
            { desc = 'Toggle git blame' })
    end
}
