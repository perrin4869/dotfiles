local assert = require('luassert')
local ui = require('helpers/ui')

-- The child has a UI and boots this config (see helpers/ui.lua), so the terminal plugin is loaded the way a user's is.
describe('plugin/terminal.lua', function()
	---@type table<string, function>
	local child
	---@type integer
	local neighbour

	before_each(function()
		child = ui.start()
		neighbour = child:exec_lua(
			[[
			vim.g.leaves = 0
			vim.api.nvim_create_autocmd('TermLeave', {
				callback = function()
					vim.g.leaves = vim.g.leaves + 1
				end,
			})
			-- the window the child booted with keeps the scratch file and becomes the neighbour, so the pointer has
			-- somewhere to be that is not the terminal: that is where the phantom drag does its damage
			local beside = vim.api.nvim_get_current_win()
			vim.cmd('vsplit')
			vim.cmd('terminal sleep 30')
			vim.wait(3000, function()
				return vim.bo.channel ~= 0
			end, 20)
			local term = vim.api.nvim_get_current_win()
			vim.cmd('startinsert')
			vim.wait(3000, function()
				return vim.api.nvim_get_mode().mode == 't'
			end, 20)
			return beside
		]],
			{}
		)
	end)

	after_each(function()
		child.stop()
	end)

	--- @return string mode, integer leaves
	local function state()
		return child:exec_lua([[return { vim.api.nvim_get_mode().mode, vim.g.leaves }]], {})
	end

	-- An emulator can lose a button release and then report every movement as a drag with that button still held
	-- (Ghostty does, ghostty-org/ghostty#12078). Neovim leaves terminal mode for a drag, and the report lands on the
	-- neighbouring window while the terminal is the one in terminal mode.
	it('keeps terminal mode when a thumb-button drag lands elsewhere', function()
		-- the same event fed straight in is `vim.api.nvim_input('\128\253\90')`: K_SPECIAL, KS_EXTRA and the
		-- <X1Drag> byte, which exercises the mapping just as well but says nothing about where the pointer was
		assert.is_not_nil(neighbour)
		child.mouse('x1', 'drag', neighbour)
		assert.same({ 't', 0 }, state())
	end)

	-- only the phantom drags are swallowed: a click on another window still takes the terminal out of terminal mode,
	-- which is what Neovim does with any mouse event it handles
	it('leaves terminal mode for a click on another window', function()
		assert.is_not_nil(neighbour)
		child.mouse('left', 'press', neighbour)
		assert.same(1, child:exec_lua('return vim.g.leaves', {}))
	end)
end)
