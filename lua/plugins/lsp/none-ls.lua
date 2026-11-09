return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")

    -- Work repos (this server only) use the project's astyle settings instead of clang-format
    local work_root = "/repo/asic_fpga/work/jaimrive/"
    local astyle_rc = work_root .. "sdk_debugger/vobs/dsl/sw/y/src/common_sdk/tools/astyle/astylerc"

    local function in_work_repo(params)
      return vim.startswith(params.bufname, work_root)
    end

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.astyle.with({
          extra_args = { "--options=" .. astyle_rc },
          runtime_condition = in_work_repo,
        }),
        null_ls.builtins.formatting.clang_format.with({
          runtime_condition = function(params)
            return not in_work_repo(params)
          end,
        }),
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
