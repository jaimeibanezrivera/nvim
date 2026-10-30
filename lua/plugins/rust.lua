return {
	{
		"mrcjkb/rustaceanvim",
		lazy = false, -- the plugin lazy-loads itself on Rust files
		init = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(_, bufnr)
						local function map(lhs, cmd, desc)
							vim.keymap.set("n", lhs, function()
								vim.cmd.RustLsp(cmd)
							end, { buffer = bufnr, silent = true, desc = desc })
						end
						map("<leader>rr", "runnables", "Rust: run")
						map("<leader>rt", "testables", "Rust: run test")
						map("<leader>re", "explainError", "Rust: explain error")
						map("<leader>rd", "renderDiagnostic", "Rust: full diagnostic")
						map("<leader>rm", "expandMacro", "Rust: expand macro")
						map("<leader>rc", "openCargo", "Rust: open Cargo.toml")
						map("<leader>rp", "parentModule", "Rust: parent module")
						map("<leader>rj", "joinLines", "Rust: join lines")
						-- Rust-aware hover with actions (go to impl, run, etc.)
						vim.keymap.set("n", "K", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, { buffer = bufnr, silent = true })
					end,
					default_settings = {
						["rust-analyzer"] = {
							check = { command = "clippy" },
							cargo = { allFeatures = true },
							procMacro = { enable = true },
							inlayHints = {
								closureReturnTypeHints = { enable = "with_block" },
								lifetimeElisionHints = { enable = "skip_trivial" },
							},
						},
					},
				},
			}
		end,
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			-- In-process LSP: version/feature completion, hover and code actions in Cargo.toml
			lsp = {
				enabled = true,
				actions = true,
				completion = true,
				hover = true,
			},
		},
	},
}
