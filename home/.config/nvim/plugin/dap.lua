local yall = require('yall')

local function focus_repl()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == 'dap-repl' then
			vim.api.nvim_set_current_win(win)
			return true
		end
	end
	return false
end

yall.pack('nvim-dap-virtual-text', 'nvim-dap-virtual-text')
yall.on_load('nvim-dap-virtual-text', function()
	require('nvim-dap-virtual-text').setup()
end)

yall.pack('dapui', 'nvim-dap-ui')
yall.deps('dapui', { 'dap' })
yall.on_load('dapui', function()
	-- nvim-dap-ui
	require('dapui').setup()
end)
yall.hook('dapui')

local with_dap = yall.with('dap')

local toggle_breakpoint = with_dap(function()
	require('dap').toggle_breakpoint()
end)

local set_breakpoint = with_dap(function()
	require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
end)

local continue = with_dap(function()
	require('dap').continue()
end)

local up = with_dap(function()
	require('dap').up()
end)

local down = with_dap(function()
	require('dap').down()
end)

local disconnect = with_dap(function()
	require('dap').disconnect({ terminateDebuggee = true })
	require('dap').close()
end)

local repl_open_focus = with_dap(function()
	if focus_repl() == false then
		local _, win = require('dap').repl.open({}, 'vsplit')
		vim.api.nvim_set_current_win(win)
		vim.cmd('exe Resize("vertical", "", "35%")')
	end
end)

local repl_toggle = with_dap(function()
	require('dap').repl.toggle({}, 'vsplit')
	vim.cmd('wincmd h | exe Resize("vertical", "", "35%")')
end)

local set_exception_breakpoints = with_dap(function()
	require('dap').set_exception_breakpoints({ 'all' })
end)

local ui_widgets_hover = with_dap(function()
	require('dap.ui.widgets').hover(require('dap.utils').get_visual_selection_text())
end)

local ui_widgets_scopes = with_dap(function()
	require('dap.ui.widgets').cursor_float(require('dap.ui.widgets').scopes)
end)

local with_dapui = yall.with('dapui')

local open_dapui = with_dapui(function()
	require('dapui').open()
end)
local toggle_dapui = with_dapui(function()
	require('dapui').toggle()
end)

local map = require('map').create({
	desc = 'dap',
})

local debug_layer = yall.lazy(yall.with('layers')(function()
	local layer = require('layers').mode.new()
	layer:auto_show_help()
	layer:keymaps({
		n = {
			{
				'K',
				function()
					require('dap.ui.widgets').hover()
				end,
				{ silent = true, desc = 'dap.hover' },
			},
			{
				'<up>',
				with_dap(function()
					require('dap').step_out()
				end),
				{ silent = true, desc = 'dap.step_out' },
			},
			{
				'<down>',
				with_dap(function()
					require('dap').step_into()
				end),
				{ silent = true, desc = 'dap.step_into' },
			},
			{
				'<right>',
				with_dap(function()
					require('dap').step_over()
				end),
				{ silent = true, desc = 'dap.step_over' },
			},
			{
				'c',
				with_dap(function()
					require('dap').continue()
				end),
				{ silent = true, desc = 'dap.continue' },
			},
		},
	})

	return layer
end))

yall.pack('dap', 'nvim-dap')
yall.on_load('dap', function()
	local dap = require('dap')

	dap.adapters['pwa-node'] = {
		type = 'server',
		host = 'localhost',
		port = '${port}',
		executable = {
			-- command = "node",
			-- -- 💀 Make sure to update this path to point to your installation
			-- args = { "/path/to/js-debug/src/dapDebugServer.js", "${port}" },
			command = 'js-debug-adapter',
			args = { '${port}' },
		},
	}

	for _, language in ipairs({ 'typescript', 'javascript' }) do
		dap.configurations[language] = {
			{
				type = 'pwa-node',
				request = 'launch',
				name = 'Launch file',
				program = '${file}',
				cwd = '${workspaceFolder}',
			},
			{
				type = 'pwa-node',
				request = 'attach',
				name = 'Attach',
				processId = require('dap.utils').pick_process,
				cwd = '${workspaceFolder}',
			},
		}
	end

	dap.configurations.scala = {
		{
			type = 'scala',
			request = 'launch',
			name = 'Run',
			metals = {
				runType = 'run',
			},
		},
		{
			type = 'scala',
			request = 'launch',
			name = 'Run or Test Target',
			metals = {
				runType = 'runOrTestFile',
			},
		},
		{
			type = 'scala',
			request = 'launch',
			name = 'Test File',
			metals = {
				runType = 'testFile',
			},
		},
		{
			type = 'scala',
			request = 'launch',
			name = 'Test Target',
			metals = {
				runType = 'testTarget',
			},
		},
		{
			type = 'scala',
			request = 'attach',
			name = 'Attach to Localhost',
			hostName = 'localhost',
			port = 5005,
			buildTarget = 'root',
		},
	}

	dap.configurations.lua = {
		{
			type = 'nlua',
			request = 'attach',
			name = 'Attach to running Neovim instance',
		},
	}

	dap.adapters.nlua = function(callback, config)
		callback({ type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 })
	end

	vim.fn.sign_define('DapBreakpoint', { text = '🟥', texthl = '', linehl = '', numhl = '' })
	vim.fn.sign_define('DapBreakpointRejected', { text = '🟦', texthl = '', linehl = '', numhl = '' })
	vim.fn.sign_define('DapStopped', { text = '⭐️', texthl = '', linehl = '', numhl = '' })

	-- Map K to hover while session is active.
	dap.listeners.after['event_initialized']['me'] = function()
		yall.ensure('nvim-dap-virtual-text')

		if not debug_layer():active() then
			debug_layer():activate()
		end
	end

	dap.listeners.after['event_terminated']['me'] = function()
		if debug_layer():active() then
			debug_layer():deactivate()
		end
	end

	dap.listeners.after['event_exited']['me'] = function()
		if debug_layer():active() then
			debug_layer():deactivate()
		end
	end

	-- autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>
	vim.api.nvim_create_autocmd('FileType', {
		group = vim.api.nvim_create_augroup('dap_float', { clear = true }),
		pattern = 'dap-float',
		callback = function()
			map('n', 'q', function()
				vim.cmd('close!')
			end, 'close_float')
		end,
	})

	yall.on_postload('telescope', function()
		require('telescope').load_extension('dap')
	end)

	dap.listeners.before.attach.dapui_config = open_dapui
	dap.listeners.before.launch.dapui_config = open_dapui
	dap.listeners.before.event_terminated['dapui_config'] = function()
		focus_repl()

		-- closing is too intrusive - cannot inspect the output
		-- require("dapui").close()
	end
	-- dap.listeners.before.event_exited["dapui_config"] = function()
	-- 	require("dapui").close()
	-- end
end)
yall.very_lazy('dap')

-- Mappings.
local prefix = '<leader>d'

map('n', prefix .. 't', toggle_breakpoint, 'toggle_breakpoint')
map('n', prefix .. 'H', set_breakpoint, 'set_breakpoint')
map('n', prefix .. '<cr>', continue, 'continue')
map('n', prefix .. 'k', up, 'up')
map('n', prefix .. 'j', down, 'down')
map('n', prefix .. 'd', disconnect, 'disconnect')
map('n', prefix .. 'r', repl_open_focus, 'repl.open_focus')
map('n', prefix .. 'R', repl_toggle, 'repl.toggle')
map('n', prefix .. 'e', set_exception_breakpoints, 'set_exception_breakpoints')
map('n', prefix .. 'i', ui_widgets_hover, 'ui.widgets.hover')
map('n', prefix .. '?', ui_widgets_scopes, 'ui.widgets.scopes')

require('map').map('n', prefix .. 'u', toggle_dapui, 'dapui.toggle')

-- telescope-dap
local pickers = require('pickers')
pickers.map(pickers.prefix .. 'dc', function()
	with_dap(function()
		require('telescope').extensions.dap.commands()
	end)()
end, 'dap.commands')
pickers.map(pickers.prefix .. 'db', function()
	with_dap(function()
		require('telescope').extensions.dap.list_breakpoints()
	end)()
end, 'dap.list_breakpoints')
pickers.map(pickers.prefix .. 'dv', function()
	with_dap(function()
		require('telescope').extensions.dap.variables()
	end)()
end, 'dap.variables')
pickers.map(pickers.prefix .. 'df', function()
	with_dap(function()
		require('telescope').extensions.dap.frames()
	end)()
end, 'dap.frames')
