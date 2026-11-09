---@diagnostic disable: undefined-field -- luassert hangs its own fields on `assert`
local nvim = require('helpers/nvim')

-- These run in a child Neovim rather than in the spec runner, so what is exercised is the config's own behaviour in a
-- process, not a module borrowed into the runner.
describe('restore', function()
	---@type Child
	local child

	before_each(function()
		child = nvim.start()
	end)

	after_each(function()
		child.stop()
	end)

	it('closes a window the matcher names, and runs its hook', function()
		child.lua([[
			vim.cmd('edit a.txt')
			vim.cmd('vnew')
			vim.cmd('file replaced.txt')
			RESTORED = false
			require('restore').add_buf_match('replaced%.txt$', function()
				RESTORED = true
			end)
		]])
		child.lua([[require('restore').restore()]])
		assert.equal(1, child.lua_get('#vim.api.nvim_list_wins()'))
		assert.is_true(child.lua_get('RESTORED'))
	end)

	it('leaves a window it does not match', function()
		child.lua([[
			vim.cmd('edit a.txt')
			vim.cmd('vnew')
			vim.cmd('file kept.txt')
			require('restore').add_buf_match('nothing%.txt$')
		]])
		child.lua([[require('restore').restore()]])
		assert.equal(2, child.lua_get('#vim.api.nvim_list_wins()'))
	end)

	it('knows which filetypes hold the window open at quit', function()
		assert.is_true(child.lua_get([[require('restore').ft('qf') == true]]))
		assert.is_false(child.lua_get([[require('restore').ft('lua') == true]]))
	end)
end)
