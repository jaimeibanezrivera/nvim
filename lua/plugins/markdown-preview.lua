-- Remote-friendly setup: no browser is opened on this machine. Instead the
-- preview URL is copied to the clipboard (OSC 52 reaches the local machine),
-- and an ssh `LocalForward 8765 127.0.0.1:8765` makes it reachable there.
return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = "cd app && ./install.sh",
    init = function()
        vim.g.mkdp_port = "8765"
        vim.g.mkdp_open_ip = "127.0.0.1"
        vim.g.mkdp_echo_preview_url = 1
        vim.g.mkdp_auto_close = 0

        vim.cmd([[
            function! MkdpCopyUrl(url) abort
                call setreg('+', a:url)
                echom 'Markdown preview URL copied to clipboard: ' . a:url
            endfunction
        ]])
        vim.g.mkdp_browserfunc = "MkdpCopyUrl"
    end,
    keys = {
        { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Toggle markdown preview" },
    },
}
