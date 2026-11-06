return {
	{
		"projekt0n/github-nvim-theme",
		lazy = false,
		priority = 1000,
		config = function()
			require("github-theme").setup({})
			-- The startup colorscheme is applied in init.lua (THEME section),
			-- picked via <leader>T / fzf colorschemes and saved in .colorscheme.
			-- Variants in use: 'github_dark', 'github_dark_dimmed'.
			-- The plugin also registers *_default, *_high_contrast, *_colorblind,
			-- *_tritanopia and the light variants; they can't be uninstalled
			-- individually without deleting files from the clone.
		end,
	},
}
