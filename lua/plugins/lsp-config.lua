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

			-- Show errors inline (off by default since Neovim 0.11)
			vim.diagnostic.config({
				virtual_text = true,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})

			-- Drop the built-in gr* mappings so `gr` (references) fires immediately
			for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
				pcall(vim.keymap.del, "n", lhs)
			end
			pcall(vim.keymap.del, "x", "gra")

			-- Keymaps for every LSP client (including rust-analyzer started by rustaceanvim)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
				callback = function(ev)
					local bufnr = ev.buf
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "ge", function()
						vim.diagnostic.jump({ count = 1 })
					end, opts)
					vim.keymap.set("n", "gE", function()
						vim.diagnostic.jump({ count = -1 })
					end, opts)

					-- Inlay hints (types, parameter names) like Zed
					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
						vim.keymap.set("n", "<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
						end, { buffer = bufnr, desc = "Toggle inlay hints" })
					end

					-- Highlight other references to the symbol under the cursor
					if client and client:supports_method("textDocument/documentHighlight") then
						local group = vim.api.nvim_create_augroup("lsp-highlight-" .. bufnr, { clear = true })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd("LspDetach", {
							group = group,
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
							end,
						})
					end
				end,
			})

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
				root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", ".git" },
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
			-- rust-analyzer is started by rustaceanvim (lua/plugins/rust.lua)
			-- Enable clangd LSP
			vim.lsp.enable("clangd")
		end,
	},
}
