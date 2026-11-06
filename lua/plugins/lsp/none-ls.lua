return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.clang_format,
      },
    })

    -- Prefer none-ls formatters (stylua, black, clang-format) over the language
    -- server's own formatter; otherwise use the LSP (e.g. rustfmt via rust-analyzer).
    local function format(bufnr)
      local has_null_ls = #vim.lsp.get_clients({ bufnr = bufnr, name = "null-ls", method = "textDocument/formatting" }) > 0
      vim.lsp.buf.format({
        bufnr = bufnr,
        filter = function(client)
          return not has_null_ls or client.name == "null-ls"
        end,
      })
    end

    vim.keymap.set("n", "<leader>ff", function()
      format(0)
    end, {})

    -- Format on save for every buffer that has a formatter attached
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("format-on-save", { clear = true }),
      callback = function(ev)
        if #vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/formatting" }) > 0 then
          format(ev.buf)
        end
      end,
    })
  end,
}
