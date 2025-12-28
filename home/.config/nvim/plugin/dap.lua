local defer = require("defer")
local utils = require("utils")
local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

local function focus_repl()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "dap-repl" then
			vim.api.nvim_set_current_win(win)
			return true
		end
	end
	return false
end

defer.pack("nvim-dap-virtual-text", "nvim-dap-virtual-text")
defer.on_load("nvim-dap-virtual-text", function()
	require("nvim-dap-virtual-text").setup()
end)

defer.pack("dap-ui", "nvim-dap-ui")
defer.on_load("dapui", function()
	-- nvim-dap-ui
	require("dapui").setup()
end)
defer.hook("dapui")

local with_dap = defer.with("dap")
local with_dapui = defer.with("dapui")
local call = defer.call

defer.pack("dap", "nvim-dap")
defer.on_load("dap", function()
	local dap = require("dap")

	dap.adapters["pwa-node"] = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			-- command = "node",
			-- -- 💀 Make sure to update this path to point to your installation
			-- args = { "/path/to/js-debug/src/dapDebugServer.js", "${port}" },
			command = "js-debug-adapter",
			args = { "${port}" },
		},
	}

	for _, language in ipairs({ "typescript", "javascript" }) do
		dap.configurations[language] = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}
	end

	dap.configurations.scala = {
		{
			type = "scala",
			request = "launch",
			name = "Run",
			metals = {
				runType = "run",
			},
		},
		{
			type = "scala",
			request = "launch",
			name = "Run or Test Target",
			metals = {
				runType = "runOrTestFile",
			},
		},
		{
			type = "scala",
			request = "launch",
			name = "Test File",
			metals = {
				runType = "testFile",
			},
		},
		{
			type = "scala",
			request = "launch",
			name = "Test Target",
			metals = {
				runType = "testTarget",
			},
		},
		{
			type = "scala",
			request = "attach",
			name = "Attach to Localhost",
			hostName = "localhost",
			port = 5005,
			buildTarget = "root",
		},
	}

	dap.configurations.lua = {
		{
			type = "nlua",
			request = "attach",
			name = "Attach to running Neovim instance",
		},
	}

	dap.adapters.nlua = function(callback, config)
		callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
	end

	vim.fn.sign_define("DapBreakpoint", { text = "🟥", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointRejected", { text = "🟦", texthl = "", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "⭐️", texthl = "", linehl = "", numhl = "" })

	-- Map K to hover while session is active.
	local keymap_restore = {}
	dap.listeners.after["event_initialized"]["me"] = function()
		for _, buf in pairs(vim.api.nvim_list_bufs()) do
			local keymaps = vim.api.nvim_buf_get_keymap(buf, "n")
			for _, keymap in pairs(keymaps) do
				if keymap.lhs == "K" then
					table.insert(keymap_restore, keymap)
					vim.api.nvim_buf_del_keymap(buf, "n", "K")
				end
			end
		end

		vim.keymap.set("n", "K", require("dap.ui.widgets").hover, { silent = true })
	end

	dap.listeners.after["event_terminated"]["me"] = function()
		for _, keymap in pairs(keymap_restore) do
			local rhs = keymap.callback ~= nil and keymap.callback or keymap.rhs
			vim.keymap.set(keymap.mode, keymap.lhs, rhs, { buffer = keymap.buffer, silent = keymap.silent == 1 })
		end
		keymap_restore = {}
	end

	-- autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("dap_float", { clear = true }),
		pattern = "dap-float",
		callback = function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close!")
			end, get_opts({ desc = "dap.close_float" }))
		end,
	})

	defer.ensure("nvim-dap-virtual-text")

	dap.listeners.before.attach.dapui_config = with_dapui(call("open"))
	dap.listeners.before.launch.dapui_config = with_dapui(call("open"))
	dap.listeners.before.event_terminated["dapui_config"] = function()
		focus_repl()

		-- closing is too intrusive - cannot inspect the output
		-- require("dapui").close()
	end
	-- dap.listeners.before.event_exited["dapui_config"] = function()
	-- 	require("dapui").close()
	-- end
end)
defer.very_lazy("dap")

-- Mappings.
local prefix = "<leader>d"
local map = function(mode, lhs, rhs, desc)
	local t = type(rhs)
	if t == "function" then
		vim.keymap.set(mode, lhs, rhs, get_opts({ desc = "dap." .. desc }))
	elseif t == "string" then
		vim.keymap.set(mode, lhs, with_dap(call(rhs)), get_opts({ desc = "dap." .. rhs }))
	else -- table
		vim.keymap.set(mode, lhs, with_dap(call(table.unpack(rhs))), get_opts({ desc = "dap." .. rhs[1] }))
	end
end

local set_breakpoint = with_dap(function(dap)
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end)

local disconnect = with_dap(function(dap)
	dap.disconnect({ terminateDebuggee = true })
	dap.close()
end)

local repl_open_focus = with_dap(function(dap)
	if focus_repl() == false then
		local _, win = dap.repl.open({}, "vsplit")
		vim.api.nvim_set_current_win(win)
		vim.cmd('exe Resize("vertical", "", "35%")')
	end
end)

local repl_toggle = with_dap(function(dap)
	dap.repl.toggle({}, "vsplit")
	vim.cmd('wincmd h | exe Resize("vertical", "", "35%")')
end)

local ui_widgets_hover = with_dap(function()
	require("dap.ui.widgets").hover(require("dap.utils").get_visual_selection_text())
end)

local ui_widgets_scopes = with_dap(function()
	require("dap.ui.widgets").cursor_float(require("dap.ui.widgets").scopes)
end)

map("n", prefix .. "t", "toggle_breakpoint")
map("n", prefix .. "H", set_breakpoint, "set_breakpoint")
map("n", "<c-k>", "step_out")
map("n", "<c-l>", "step_into")
map("n", "<c-j>", "step_over")
map("n", "<c-h>", "continue")
map("n", prefix .. "k", "up")
map("n", prefix .. "j", "down")
map("n", prefix .. "d", disconnect, "disconnect")
map("n", prefix .. "r", repl_open_focus, "repl.open_focus")
map("n", prefix .. "R", repl_toggle, "repl.toggle")
map("n", prefix .. "e", { "set_exception_breakpoints", { "all" } })
map("n", prefix .. "i", ui_widgets_hover, "ui.widgets.hover")
map("n", prefix .. "?", ui_widgets_scopes, "ui.widgets.scopes")

vim.keymap.set("n", prefix .. "u", with_dapui(call("toggle")), get_opts({ desc = "dapui.toggle" }))

-- telescope-dap
local pickers = require("pickers")
pickers.map(prefix .. "c", function(telescope)
	with_dap(function()
		telescope.extensions.dap.commands()
	end)()
end, { prefix = false, desc = "dap.commands" })
pickers.map(prefix .. "b", function(telescope)
	with_dap(function()
		telescope.extensions.dap.list_breakpoints()
	end)()
end, { prefix = false, desc = "dap.list_breakpoints" })
pickers.map(prefix .. "v", function(telescope)
	with_dap(function()
		telescope.extensions.dap.variables()
	end)()
end, { prefix = false, desc = "dap.variables" })
pickers.map(prefix .. "f", function(telescope)
	with_dap(function()
		telescope.extensions.dap.frames()
	end)()
end, { prefix = false, desc = "dap.frames" })
