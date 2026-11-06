-- For `plugins/markview.lua` users.
return {
    "OXY2DEV/markview.nvim",
    ft = "markdown",

    -- A function so markview's presets can be required after it's loaded.
    opts = function()
        return {
            preview = {
                -- Keep rendering while selecting text (visual, visual-line, visual-block).
                modes = { "n", "no", "c", "v", "V", "\22" },
                -- Above this, only the area around the cursor is rendered.
                max_buf_lines = 10000,
            },
            markdown = {
                headings = require("markview.presets").headings.glow_center,
            },
        }
    end,

    -- Completion for `blink.cmp`
    -- dependencies = { "saghen/blink.cmp" },
};
