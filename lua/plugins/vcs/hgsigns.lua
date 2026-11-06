return {
    'cavanaug/hgsigns.nvim',
    branch = 'mercurial',
    cond = vim.fn.executable('hg') == 1,
    config = function()
        require('hgsigns').setup({
            signs = {
                add          = { text = '│' },
                change       = { text = '│' },
                delete       = { text = '_' },
                topdelete    = { text = '‾' },
                changedelete = { text = '~' },
            },
        })
    end
}
