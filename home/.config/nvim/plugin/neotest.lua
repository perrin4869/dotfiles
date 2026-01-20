local defer = require('defer')

defer.pack('neotest')
defer.on_bufreadpre('neotest', { nested = true })
defer.on_load('neotest', function()
	--- @diagnostic disable-next-line: missing-fields
	require('neotest').setup({})
end)

local function add_adapter(adapter_name)
	defer.pack(adapter_name)
	defer.deps('neotest', adapter_name)
end
add_adapter('neotest-mocha')
add_adapter('neotest-busted')

if vim.g.test_get_adapters then
	defer.on_postload('neotest', function()
		-- hint: set vim.g.test_root to vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ':h') in .nvim.lua is the safest option
		local root = vim.g.test_root or defer.require('project').get_project_root() or vim.fn.getcwd()

		--- @diagnostic disable-next-line: missing-fields
		require('neotest').setup_project(root, {
			adapters = vim.g.test_get_adapters(root),
		})
	end)
end

---@type Defer.With<neotest>
local with_neotest = defer.with('neotest')

local map = require('map').create({ mode = 'n', desc = 'neotest' })

map(
	'<leader>ii',
	with_neotest(function(neotest)
		neotest.run.run()
	end),
	'run'
)

map(
	'<leader>if', -- entire file
	with_neotest(function(neotest)
		neotest.run.run(vim.fn.expand('%'))
	end),
	'run_file'
)

map(
	'<leader>id',
	with_neotest(function(neotest)
		--- @diagnostic disable-next-line: missing-fields
		neotest.run.run({ strategy = 'dap' })
	end),
	'run_dap'
)

map(
	'<leader>is',
	with_neotest(function(neotest)
		neotest.run.stop()
	end),
	'stop'
)

map(
	'<leader>ia',
	with_neotest(function(neotest)
		neotest.run.attach()
	end),
	'attach'
)

map(
	'<leader>ts',
	with_neotest(function(neotest)
		neotest.summary.toggle()
	end),
	'attach'
)

map(
	'<leader>to',
	with_neotest(function(neotest)
		neotest.output_panel.toggle()
	end),
	'attach'
)

local restore = require('restore')
restore.add_quitpre_ft('neotest-summary')
restore.add_buf_match('Neotest Summary', function()
	defer.on_postload('neotest', function()
		require('neotest').summary.toggle()
	end)
end)
restore.add_quitpre_ft('neotest-output-panel')
restore.add_buf_match('Neotest Output Panel', function()
	defer.on_postload('neotest', function()
		require('neotest').output_panel.toggle()
	end)
end)
