local defer = require("defer")
local dap = require("dap")
local utils = require("utils")

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

-- Mappings.
local prefix = "<leader>d"
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

vim.keymap.set("n", prefix .. "t", dap.toggle_breakpoint, get_opts({ desc = "dap.toggle_breakpoint" }))
vim.keymap.set("n", prefix .. "H", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, get_opts({ desc = "dap.set_breakpoint" }))
vim.keymap.set("n", "<c-k>", dap.step_out, get_opts({ desc = "dap.step_out" }))
vim.keymap.set("n", "<c-l>", dap.step_into, get_opts({ desc = "dap.step_into" }))
vim.keymap.set("n", "<c-j>", dap.step_over, get_opts({ desc = "dap.step_over" }))
vim.keymap.set("n", "<c-h>", dap.continue, get_opts({ desc = "dap.continue" }))
vim.keymap.set("n", prefix .. "k", dap.up, get_opts({ desc = "dap.up" }))
vim.keymap.set("n", prefix .. "j", dap.down, get_opts({ desc = "dap.down" }))
vim.keymap.set("n", prefix .. "d", function()
	dap.disconnect({ terminateDebuggee = true })
	dap.close()
end, get_opts({ desc = "dap.disconnect" }))
vim.keymap.set("n", prefix .. "r", function()
	if focus_repl() == false then
		local _, win = dap.repl.open({}, "vsplit")
		vim.api.nvim_set_current_win(win)
		vim.cmd('exe Resize("vertical", "", "35%")')
	end
end, get_opts({ desc = "dap.repl.open_focus" }))
vim.keymap.set("n", prefix .. "R", function()
	dap.repl.toggle({}, "vsplit")
	vim.cmd('wincmd h | exe Resize("vertical", "", "35%")')
end, get_opts({ desc = "dap.repl.toggle" }))
vim.keymap.set("n", prefix .. "e", function()
	dap.set_exception_breakpoints({ "all" })
end, get_opts({ desc = "dap.set_exception_breakpoints" }))
vim.keymap.set("n", prefix .. "i", function()
	require("dap.ui.widgets").hover(require("dap.utils").get_visual_selection_text())
end, get_opts({ desc = "dap.ui.widgets.hover" }))
vim.keymap.set("n", prefix .. "?", function()
	require("dap.ui.widgets").cursor_float(require("dap.ui.widgets").scopes)
end, get_opts({ desc = "dap.ui.widgets.scopes" }))

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
		end, opts)
	end,
})

require("nvim-dap-virtual-text").setup()

defer.hook("dapui", function()
	-- nvim-dap-ui
	require("dapui").setup()
end)

vim.keymap.set("n", prefix .. "u", function()
	require("dapui").toggle()
end, get_opts({ desc = "dapui.toggle" }))

dap.listeners.before.attach.dapui_config = function()
	require("dapui").open()
end
dap.listeners.before.launch.dapui_config = function()
	require("dapui").open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	focus_repl()

	-- closing is too intrusive - cannot inspect the output
	-- require("dapui").close()
end
-- dap.listeners.before.event_exited["dapui_config"] = function()
-- 	require("dapui").close()
-- end

-- telescope-dap
local pickers = require("pickers")
pickers.map(prefix .. "c", function(telescope)
	telescope.commands()
end, { prefix = false, desc = "dap.commands" })
pickers.map(prefix .. "b", function(telescope)
	telescope.list_breakpoints()
end, { prefix = false, desc = "dap.list_breakpoints" })
pickers.map(prefix .. "v", function(telescope)
	telescope.variables()
end, { prefix = false, desc = "dap.variables" })
pickers.map(prefix .. "f", function(telescope)
	telescope.frames()
end, { prefix = false, desc = "dap.frames" })
