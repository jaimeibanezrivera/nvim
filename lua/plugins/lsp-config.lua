return {
	{
		"neovim/nvim-lspconfig",
		event = "BufReadPre",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"folke/trouble.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local function on_attach(client, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			end

			lspconfig.clangd.setup({
				cmd = { "clangd", "--offset-encoding=utf-16" },
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
				capabilities = capabilities,
				on_attach = on_attach,
				init_options = {
					fallbackFlags = {
						"-std=c++17",
						"-Wall",
						"-Wextra",
					},
				},
			})

			lspconfig.lua_ls.setup({
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						diagnostics = {
							globals = { "vim" },
						},
						telemetry = { enable = false },
					},
				},
			})

			lspconfig.basedpyright.setup({
				cmd = { "basedpyright-langserver", "--stdio" },
				filetypes = { "python" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			})

			lspconfig.rust_analyzer.setup({
				cmd = { "rust-analyzer" },
				filetypes = { "rust" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					["rust-analyzer"] = {
						checkOnSave = true,
						check = { command = "clippy" },
					},
				},
			})
		end,
	},
}
