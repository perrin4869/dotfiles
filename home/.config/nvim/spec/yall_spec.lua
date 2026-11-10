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
