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
			files = {
				-- Keep VCS metadata and language-server indexes out everywhere.
				-- Project-specific build artifacts belong in a repo-local .ignore.
				-- rg enumerates this repository roughly 10x faster than fd.
				cmd = "rg --files --color=never "
					.. "--glob '!.git/**' --glob '!.hg/**' --glob '!.cache/**'",
				hidden = false,
				no_ignore = false,
			},
			grep = {
				rg_opts = "--column --line-number --no-heading --color=always --smart-case "
					.. "--max-columns=4096 --glob '!.git/**' --glob '!.hg/**' --glob '!.cache/**' -e",
			},
		})

		local function scoped_picker_opts()
			local repo = vim.fs.root(vim.fn.getcwd(), { ".hg", ".git" }) or vim.fn.getcwd()
			local zacapa = repo .. "/vobs/dsl/sw/y/src/zacapa"

			-- Only apply the Zacapa scope when this picker is opened in that repository.
			if not (vim.uv or vim.loop).fs_stat(zacapa) then
				return {}
			end

			local function toggle_scope(_, opts)
				local current = vim.fs.normalize(opts.cwd or vim.fn.getcwd())
				local next_cwd = current == vim.fs.normalize(zacapa) and repo or zacapa
				local new_opts = vim.tbl_deep_extend("force", {}, opts.__call_opts or {}, {
					cwd = next_cwd,
					resume = true,
				})

				opts.__call_fn(new_opts)
			end

			return {
				cwd = zacapa,
				cwd_header = true,
				actions = {
					["alt-a"] = {
						fn = toggle_scope,
						reuse = true,
						header = false,
					},
				},
			}
		end

		local function browse_files()
			fzf.files(scoped_picker_opts())
		end

		vim.keymap.set("n", "<leader>bf", browse_files, { desc = "Browse Files (alt-a toggles repo scope)" })
		vim.keymap.set("n", "<leader>bt", function()
			fzf.live_grep(scoped_picker_opts())
		end, { desc = "Browse Text (alt-a toggles repo scope)" })
		vim.keymap.set("n", "<leader>bw", function()
			fzf.grep_cword(scoped_picker_opts())
		end, { desc = "Browse Word (alt-a toggles repo scope)" })
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
