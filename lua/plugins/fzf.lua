return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local fzf = require("fzf-lua")

		fzf.setup({
			winopts = function()
				local width = vim.o.columns
				local height = vim.o.lines

				if width >= 150 then
					-- Horizontal (side by side preview)
					return {
						width = 0.9,
						height = 0.9,
						preview = { layout = "horizontal", ratio = 50 },
					}
				else
					-- Vertical (preview on bottom)
					return {
						width = 0.9,
						height = 0.9,
						preview = { layout = "vertical", ratio = 50 },
					}
				end
			end,
		})

		vim.keymap.set("n", "<leader>bf", fzf.files, { desc = "Browse Files" })
		vim.keymap.set("n", "<leader>bh", function()
			fzf.files({ fd_opts = "--hidden --no-ignore --exclude .git" })
		end, { desc = "Browse Hidden files" })
		vim.keymap.set("n", "<leader>bt", fzf.live_grep, { desc = "Browse Text (grep)" })
		vim.keymap.set("n", "<leader>bw", fzf.grep_cword, { desc = "Browse Word under cursor" })
		vim.keymap.set("n", "<leader>br", fzf.oldfiles, { desc = "Browse Recent files" })
		vim.keymap.set("n", "<leader>bb", fzf.buffers, { desc = "Browse Buffers" })
		vim.keymap.set("n", "<leader>bc", function()
			fzf.colorschemes({
				actions = {
					["default"] = function(selected)
						local scheme = selected[1]
						vim.cmd.colorscheme(scheme)
						local f = io.open(vim.fn.stdpath("config") .. "/.colorscheme", "w")
						if f then
							f:write(scheme)
							f:close()
						end
					end,
				},
			})
		end, { desc = "Browse Colorschemes" })
	end,
}
