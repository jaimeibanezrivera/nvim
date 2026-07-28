return {
    'cavanaug/hgsigns.nvim',
    branch = 'mercurial',
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
