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
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			})

			vim.lsp.config("clangd", {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--offset-encoding=utf-16",
				},
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
				root_markers = { "compile_commands.json", ".clangd", ".hg", ".git" },
				capabilities = capabilities,
				init_options = {
					fallbackFlags = {
						"-Wall",
						"-Wextra",
					},
				},
			})

			vim.lsp.config("lua_ls", {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				capabilities = capabilities,
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

			vim.lsp.config("basedpyright", {
				cmd = { "basedpyright-langserver", "--stdio" },
				filetypes = { "python" },
				capabilities = capabilities,
				settings = {
					basedpyright = {
						analysis = {
							diagnosticMode = "openFilesOnly",
							autoSearchPaths = false,
							typeCheckingMode = "basic",
						},
					},
				},
			})

			vim.lsp.config("rust_analyzer", {
				cmd = { "rust-analyzer" },
				filetypes = { "rust" },
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						checkOnSave = true,
						check = { command = "clippy" },
					},
				},
			})

			vim.lsp.enable({ "clangd", "lua_ls", "basedpyright", "rust_analyzer" })
		end,
	},
}
