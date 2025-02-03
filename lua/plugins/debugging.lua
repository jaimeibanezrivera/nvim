return {
	"mfussenegger/nvim-dap",
	url = "git@github.com:mfussenegger/nvim-dap.git",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap, dapui = require("dap"), require("dapui")

		-- Properly initialize dap-ui before calling `open()`
		dapui.setup()

		-- Auto open/close dap-ui when debugging starts/stops
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		-- Setup C/C++ debugging using codelldb
		local mason_registry = require("mason-registry")
		local codelldb_path = mason_registry.get_package("codelldb"):get_install_path() .. "/extension/adapter/codelldb"

		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = codelldb_path,
				args = { "--port", "${port}" },
			},
		}

		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}

		-- Use the same configuration for C
		dap.configurations.c = dap.configurations.cpp

		--For python using debugpy:
		-- 🔹 Python Debugging Setup
		local debugpy_path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"

		dap.adapters.python = {
			type = "executable",
			command = debugpy_path,
			args = { "-m", "debugpy.adapter" },
		}

		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}", -- Debug the current file
				pythonPath = function()
					return vim.fn.input("Path to python interpreter: ", "/usr/bin/python3", "file")
				end,
			},
		}

		vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {}) --Debugger Breaking point
		vim.keymap.set("n", "<leader>dc", dap.continue, {}) --Debugger Continue
	end,
}
