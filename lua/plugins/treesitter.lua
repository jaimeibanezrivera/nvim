return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- The main branch ignores ensure_installed/highlight options:
      -- parsers are installed explicitly and highlighting is started per buffer.
      require("nvim-treesitter").install({
        "python", "lua", "vim", "vimdoc", "query", "c", "cpp", "rust", "toml", "markdown", "markdown_inline", "html", "latex", "yaml",
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
