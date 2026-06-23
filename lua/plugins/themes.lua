return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		config = function()
			-- vim.cmd.colorscheme("catppuccin-mocha") -- This remains commented out as per your original input
		end,
	},
	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			-- Initial settings for Gruvbox Material (defaulting to dark mode)
			vim.g.gruvbox_material_background = "medium" -- options for dark: 'soft', 'medium', 'hard'
			vim.g.gruvbox_material_enable_bold = 1
			vim.g.gruvbox_material_enable_italic = 1
			vim.g.gruvbox_material_transparent_background = 0
			vim.cmd.colorscheme("gruvbox-material") -- Apply the initial dark theme
		end,
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nightfox").setup({})
		end,
	},
	{
		"neanias/everforest-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("everforest").setup({
				background = "medium", -- "soft", "medium", "hard"
			})
		end,
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				compile = false,
				transparent = false,
				theme = "wave", -- "wave", "dragon", "lotus"
			})
		end,
	},
	{ "EdenEast/nightfox.nvim" }, -- lazy
	{
		"NLKNguyen/papercolor-theme",
		lazy = false,
		priority = 1000,
		config = function()
			vim.api.nvim_create_autocmd("ColorSchemePre", {
				pattern = "PaperColor",
				callback = function()
					vim.o.background = "light"
				end,
			})
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "PaperColor",
				callback = function()
					-- PaperColor has limited Treesitter/LSP semantic links for C/C++.
					-- Link common function captures to the classic Function group.
					vim.api.nvim_set_hl(0, "Function", { fg = "#1f6fbf", bold = true, ctermfg = 32, cterm = { bold = true } })

					local groups = {
						"@function",
						"@function.call",
						"@function.cpp",
						"@function.call.cpp",
						"@method",
						"@method.call",
						"@method.cpp",
						"@method.call.cpp",
						"@lsp.type.function",
						"@lsp.type.method",
						"@lsp.type.function.cpp",
						"@lsp.type.method.cpp",
					}
					for _, group in ipairs(groups) do
						vim.api.nvim_set_hl(0, group, { link = "Function" })
					end
				end,
			})
		end,
	},
	{
		"Shatur/neovim-ayu",
		lazy = false,
		priority = 1000,
		config = function()
			require("ayu").setup({
				mirage = false, -- set to true for mirage variant
			})
		end,
	},
	-- Using Lazy
	{
		"navarasu/onedark.nvim",
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			require("onedark").setup({
				style = "darker",
			})
			require("onedark").load()
		end,
	},
}
