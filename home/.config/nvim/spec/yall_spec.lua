local assert = require('luassert')
local nvim = require('helpers/nvim')

-- The plugins only exist in the checkout's pack, so `ensure` has nothing to load in the spec runner; a child running
-- this config has them.
describe('yall.ensure', function()
	---@type table<string, function>
	local child

	before_each(function()
		child = nvim.start()
	end)

	after_each(function()
		nvim.stop(child)
	end)

	it('loads a plugin the config registered', function()
		assert.is_false(child:exec_lua([[return package.loaded['which-key'] ~= nil]], {}))
		assert.is_true(child:exec_lua([[return require('yall').ensure('which-key')]], {}))
		assert.is_true(child:exec_lua([[return type(require('which-key')) == 'table']], {}))
	end)

	it('reports a name it does not know', function()
		assert.is_false(child:exec_lua([[return require('yall').ensure('not-a-plugin')]], {}))
	end)
end)

-- Registering a loader is enough: `ensure` runs it without requiring anything, so the two cases differ only in the
-- environment
describe('yall.disable through the environment', function()
	it('loads a module the variable does not name', function()
		local yall = require('yall')
		yall.on_load('probe-module', function() end)
		assert.is_true(yall.ensure('probe-module'))
	end)

	it('leaves a module whose variable is set unloaded', function()
		local yall = require('yall')
		yall.on_load('switched-off', function() end)
		vim.env.YALL_DISABLE_SWITCHED_OFF = '1'
		assert.is_false(yall.ensure('switched-off'))
		vim.env.YALL_DISABLE_SWITCHED_OFF = nil
	end)
end)

-- The placeholder's own callback stands in for the command line, where an error message is only a message: calling
-- it through vim.cmd would turn any error message into an exception before the placeholder could matter
describe('yall.cmd', function()
	local names = { 'YallProbeWarns', 'YallProbeWhole' }

	after_each(function()
		for _, name in ipairs(names) do
			pcall(vim.api.nvim_del_user_command, name)
		end
	end)

	local function run(name, args)
		local placeholder = vim.api.nvim_get_commands({})[name].callback --[[@as function]]
		placeholder({
			name = name,
			args = args,
			fargs = vim.split(args, ' ', { trimempty = true }),
			bang = false,
			line1 = 1,
			line2 = 1,
			range = 0,
			count = -1,
			reg = '',
			mods = '',
			smods = {},
		})
	end

	it('leaves the error messages of the command it loads as messages', function()
		local ran = false
		require('yall').on_load('yall-probe-warns', function()
			vim.api.nvim_create_user_command('YallProbeWarns', function()
				vim.api.nvim_echo({ { 'a warning' } }, true, { err = true })
				ran = true
			end, {})
		end)
		require('yall').cmd('YallProbeWarns', 'yall-probe-warns')
		run('YallProbeWarns', '')
		assert.is_true(ran)
	end)

	it('gives a command that takes one argument its arguments whole', function()
		local received
		require('yall').on_load('yall-probe-whole', function()
			vim.api.nvim_create_user_command('YallProbeWhole', function(opts)
				received = opts.fargs
			end, { nargs = '?' })
		end)
		require('yall').cmd('YallProbeWhole', 'yall-probe-whole')
		run('YallProbeWhole', 'hello world')
		assert.same({ 'hello world' }, received)
	end)
end)
