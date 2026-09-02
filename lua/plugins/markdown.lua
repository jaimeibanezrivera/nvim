return {
    {
        "OXY2DEV/markview.nvim",
        lazy = false,

        -- Completion for `blink.cmp`
        -- dependencies = { "saghen/blink.cmp" },
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = "cd app && ./install.sh",
        init = function()
            -- Keep the server private to the SSH host. Forward this port from
            -- the laptop with: ssh -L 7777:127.0.0.1:7777 <host>
            vim.g.mkdp_open_to_the_world = 0
            vim.g.mkdp_open_ip = "127.0.0.1"
            vim.g.mkdp_port = "7777"
            vim.g.mkdp_echo_preview_url = 1

            -- Do not try to launch a browser in the remote SSH session.
            vim.cmd([[
                function! MarkdownPreviewRemote(url) abort
                endfunction
            ]])
            vim.g.mkdp_browserfunc = "MarkdownPreviewRemote"
        end,
    },
}
