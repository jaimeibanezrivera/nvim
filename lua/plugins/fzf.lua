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

		local show_hidden = false
		local function browse_files()
			fzf.files({
				fd_opts = show_hidden and "--hidden --no-ignore --exclude .git" or nil,
				actions = {
					["ctrl-h"] = function()
						show_hidden = not show_hidden
						browse_files()
					end,
				},
			})
		end

		vim.keymap.set("n", "<leader>bf", browse_files, { desc = "Browse Files (ctrl-h toggles hidden)" })
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
