local yd = require('yo-dawg')

local ROOT = vim.fn.getcwd()
-- `--embed` waits for a UI to attach unless `--headless` says none is coming; the rest keeps the child off the machine's
-- own config, swap and undo files
local spawn = yd:with_cmd({
	vim.v.progpath,
	'--embed',
	'--headless',
	'-i',
	'NONE',
	'-u',
	'NONE',
	'--cmd',
	'set rtp^=' .. ROOT .. '/home/.config/nvim',
	'--cmd',
	'set noswapfile',
	'--cmd',
	'set noundofile',
})
local env = vim.tbl_extend('force', vim.fn.environ(), { HOME = ROOT .. '/home' })

-- These run in a child Neovim rather than in the spec runner, so what is exercised is the config's own behaviour in a
-- process, not a module borrowed into the runner.
describe('restore', function()
	---@type table<string, function>
	local child

	before_each(function()
		child = spawn.start({ env = env, width = 80, height = 24 })
	end)

	after_each(function()
		yd.stop(child, 2000)
	end)

	it('closes a window the matcher names, and runs its hook', function()
		child:exec_lua(
			[[
			vim.cmd('edit a.txt')
			vim.cmd('vnew')
			vim.cmd('file replaced.txt')
			vim.g.restored = false
			require('restore').add_buf_match('replaced%.txt$', function()
				vim.g.restored = true
			end)
		]],
			{}
		)
		child:exec2([[lua require('restore').restore()]], {})
		assert.equal(1, child:exec_lua('return #vim.api.nvim_list_wins()', {}))
		assert.is_true(child:exec_lua('return vim.g.restored', {}))
	end)

	it('leaves a window it does not match', function()
		child:exec_lua(
			[[
			vim.cmd('edit a.txt')
			vim.cmd('vnew')
			vim.cmd('file kept.txt')
			require('restore').add_buf_match('nothing%.txt$')
		]],
			{}
		)
		child:exec2([[lua require('restore').restore()]], {})
		assert.equal(2, child:exec_lua('return #vim.api.nvim_list_wins()', {}))
	end)

	it('knows which filetypes hold the window open at quit', function()
		assert.is_true(child:exec_lua([[return require('restore').ft('qf') == true]], {}))
		assert.is_false(child:exec_lua([[return require('restore').ft('lua') == true]], {}))
	end)
end)
