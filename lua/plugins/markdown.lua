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
            vim.g.mkdp_echo_preview_url = 0

            local last_url = nil

            -- The echoed URL lands in the message area, which cannot be yanked,
            -- so put it in the clipboard instead (OSC 52 when over SSH).
            local function copy_url(url)
                last_url = url
                vim.fn.setreg("+", url)
                vim.notify("Preview URL copied: " .. url)
            end

            -- Do not try to launch a browser in the remote SSH session.
            _G.markdown_preview_copy_url = copy_url
            vim.cmd([[
                function! MarkdownPreviewRemote(url) abort
                    call v:lua.markdown_preview_copy_url(a:url)
                endfunction
            ]])
            vim.g.mkdp_browserfunc = "MarkdownPreviewRemote"

            vim.api.nvim_create_user_command("MarkdownPreviewUrl", function()
                local url = string.format("http://127.0.0.1:%s/page/%d", vim.g.mkdp_port, vim.fn.bufnr())
                copy_url(last_url or url)
            end, { desc = "Copy the markdown preview URL to the clipboard" })
        end,
    },
}
