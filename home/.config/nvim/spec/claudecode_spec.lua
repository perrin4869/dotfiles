local assert = require('luassert')
local here = require('helpers/here')
local nvim = require('helpers/nvim')

-- The fixture directory goes on the child's PATH, so claudecode.nvim starts the stand-in instead of the real claude.
local info = debug.getinfo(1, 'S')
---@cast info -nil
local HERE = here.dir(info)
local CLAUDE_DIR = HERE .. '/fixtures/claude'

-- Opens `term://…` beside a file, as a session would restore it, and returns that terminal's window.
local function restored(child, command)
	return child:exec_lua(
		[[
		vim.cmd('edit ' .. ...)
		vim.cmd('vsplit')
		vim.cmd('edit term://' .. select(2, ...))
		return vim.api.nvim_get_current_win()
	]],
		{ HERE .. '/.scratch', command }
	)
end

describe('plugin/claudecode.lua', function()
	---@type table<string, function>
	local child

	before_each(function()
		child = nvim.start({ env = { PATH = CLAUDE_DIR .. ':' .. vim.env.PATH } })
	end)

	after_each(function()
		nvim.stop(child)
	end)

	-- Restoring a session re-runs the command through 'shell', so the program and its arguments arrive as one argv
	-- element ({ '/bin/zsh', '-c', 'claude --resume' }), which used to go unrecognized.
	it('replaces a claude terminal restored with arguments', function()
		local win = restored(child, 'claude --resume')
		child:exec_lua([[require('restore').restore()]], {})
		assert.is_false(child:exec_lua('return vim.api.nvim_win_is_valid(...)', { win }))
		assert.is_true(child:exec_lua(
			[[
			return vim.wait(5000, function()
				return vim.iter(vim.api.nvim_list_bufs()):any(function(buf)
					return vim.bo[buf].filetype == 'claudecode'
				end)
			end, 20)
		]],
			{}
		))
	end)

	it('leaves a terminal that is not claude alone', function()
		local win = restored(child, 'sleep 30')
		child:exec_lua([[require('restore').restore()]], {})
		assert.is_true(child:exec_lua('return vim.api.nvim_win_is_valid(...)', { win }))
	end)
end)
