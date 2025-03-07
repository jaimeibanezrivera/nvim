return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      auto_install = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })
      lspconfig.clangd.setup({
        capabilities = capabilities,
      })
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
      })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
      vim.keymap.set("n", "<leader>rf", vim.lsp.buf.rename, { desc = "LSP Rename" })

      --Errors
      local float_opts = {
        focusable = true,
        border = "rounded",
        source = "always",
        prefix = "●",
      }

      -- Show diagnostic float with <leader>e
      vim.keymap.set("n", "<leader>e", function()
        vim.diagnostic.open_float(nil, float_opts)
      end, { desc = "Show Diagnostic Float" })

      -- Navigate diagnostics with float & auto-center
      vim.keymap.set("n", "<C-n>", function()
        vim.diagnostic.goto_next()
        vim.diagnostic.open_float(nil, float_opts) -- Show float window on next
        vim.cmd("normal! zz")                  -- Center the cursor
      end, { desc = "Go to Next Diagnostic with Float and Center" })

      vim.keymap.set("n", "<C-p>", function()
        vim.diagnostic.goto_prev()
        vim.diagnostic.open_float(nil, float_opts) -- Show float window on previous
        vim.cmd("normal! zz")                  -- Center the cursor
      end, { desc = "Go to Previous Diagnostic with Float and Center" })
    end,
  },
}
