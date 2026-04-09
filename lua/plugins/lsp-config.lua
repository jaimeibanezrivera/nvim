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
			-- Get capabilities from cmp-nvim-lsp
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Define clangd configuration using vim.lsp.config
			vim.lsp.config.clangd = {
				cmd = { "clangd", "--offset-encoding=utf-16" },
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
				root_markers = {
					".clangd",
					".clang-tidy",
					".clang-format",
					"compile_commands.json",
					"compile_flags.txt",
					"configure.ac",
					".git",
				},
				capabilities = capabilities,
				init_options = {
					fallbackFlags = {
						"-std=c++17",
						"-Wall",
						"-Wextra",
					},
				},
				on_attach = function(client, bufnr)
					-- Optional: Configure buffer-specific keymaps
					local opts = { noremap = true, silent = true, buffer = bufnr }

					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			}

			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
				capabilities = capabilities,
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" }, -- Neovim uses LuaJIT
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true), -- expose nvim runtime
						},
						diagnostics = {
							globals = { "vim" }, -- stop "undefined global vim" warnings
						},
						telemetry = { enable = false },
					},
				},
			}
			vim.lsp.enable("lua_ls")
			vim.lsp.config.basedpyright = {
				cmd = { "basedpyright-langserver", "--stdio" },
				filetypes = { "python" },
				root_markers = { "pyproject.toml", "setup.py", ".git" },
				capabilities = capabilities,
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			}
			vim.lsp.enable("basedpyright")
			-- Enable clangd LSP
			vim.lsp.enable("clangd")
		end,
	},
} -- ← Make sure this closing brace is present!
