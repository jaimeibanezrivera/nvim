return {
	"neovim/nvim-lspconfig",
	lazy = false,
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- helper: common config table factory (you can extend per server)
		local function make_config(extra)
			extra = extra or {}
			extra.capabilities = capabilities
			return extra
		end

		-- Define server configs on vim.lsp.config (new 0.11+ API)
		-- You can add server-specific settings inside the table below.
		vim.lsp.config = vim.lsp.config or {} -- ensure table exists

		vim.lsp.config["bashls"] = make_config({
			filetypes = { "sh", "bash" },
		})

		vim.lsp.config["clangd"] = make_config({
			-- add clangd-specific options here if needed
		})

		vim.lsp.config["pyright"] = make_config({
			settings = { python = { analysis = { typeCheckingMode = "off" } } },
		})

		vim.lsp.config["lua_ls"] = make_config({
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
				},
			},
		})

		-- List of servers to enable
		local servers = { "bashls", "clangd", "pyright", "lua_ls" }

		-- Enable servers (starts them for matching buffers/filetypes)
		-- This is the 0.11+ equivalent of the old `require("lspconfig").<server>.setup({...})`.
		vim.lsp.enable(servers)

		-- Compatibility fallback: if running older Neovim (<0.11) that doesn't have vim.lsp.config/enable,
		-- try to call the old lspconfig setup to avoid breakage.
		if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
			local ok, lspconfig = pcall(require, "lspconfig")
			if ok then
				lspconfig.bashls.setup({ capabilities = capabilities })
				lspconfig.clangd.setup({ capabilities = capabilities })
				lspconfig.pyright.setup({ capabilities = capabilities })
				lspconfig.lua_ls.setup({ capabilities = capabilities })
			end
		end

		-- Keymaps for LSP (kept as you had them)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
		vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		vim.keymap.set("n", "<leader>rf", vim.lsp.buf.rename, { desc = "LSP Rename" })

		-- Diagnostic float preferences
		local float_opts = {
			focusable = true,
			border = "rounded",
			source = "always",
			prefix = "●",
		}

		vim.keymap.set("n", "<leader>e", function()
			vim.diagnostic.open_float(nil, float_opts)
		end, { desc = "Show Diagnostic Float" })

		vim.keymap.set("n", "<C-n>", function()
			vim.diagnostic.goto_next()
			vim.diagnostic.open_float(nil, float_opts)
			vim.cmd("normal! zz")
		end, { desc = "Go to Next Diagnostic with Float and Center" })

		vim.keymap.set("n", "<C-p>", function()
			vim.diagnostic.goto_prev()
			vim.diagnostic.open_float(nil, float_opts)
			vim.cmd("normal! zz")
		end, { desc = "Go to Previous Diagnostic with Float and Center" })

		-- (Optional) If you use mason-lspconfig and want to ensure that when mason installs servers
		-- they are enabled automatically, you can register a simple handler:
		local has_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
		if has_mason_lspconfig and mason_lspconfig.setup_handlers then
			mason_lspconfig.setup_handlers({
				-- default handler: enable the server if we already defined its config
				function(server_name)
					if vim.lsp.config[server_name] then
						vim.lsp.enable(server_name)
					end
				end,
			})
		end
	end,
}
