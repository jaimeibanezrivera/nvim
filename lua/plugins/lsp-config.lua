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

			local on_attach = function(_, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "ge", vim.diagnostic.goto_next, opts)
				vim.keymap.set("n", "gE", vim.diagnostic.goto_prev, opts)
			end

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
				on_attach = on_attach,
				init_options = {
					fallbackFlags = {
						"-std=c++17",
						"-Wall",
						"-Wextra",
					},
				},
			}

			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
				capabilities = capabilities,
				on_attach = on_attach,
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
				root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", ".git" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			}
			vim.lsp.enable("basedpyright")
			vim.lsp.config.rust_analyzer = {
				cmd = { "rust-analyzer" },
				filetypes = { "rust" },
				root_markers = { "Cargo.toml", "Cargo.lock", ".git" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					["rust-analyzer"] = {
						checkOnSave = true,
						check = { command = "clippy" },
					},
				},
			}
			vim.lsp.enable("rust_analyzer")
			-- Enable clangd LSP
			vim.lsp.enable("clangd")
		end,
	},
}
