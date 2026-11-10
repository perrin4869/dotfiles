local assert = require('luassert')
local nvim = require('helpers/nvim')

-- The fixtures sit next to this spec, wherever the checkout is, and each one has a directory of its own; the child gets
-- the directory on its PATH so `:Pi` starts the stand-in instead of the real thing.
local HERE = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local PI_DIR = HERE .. '/fixtures/pi'

describe('plugin/pi.lua', function()
	---@type table<string, function>
	local child

	before_each(function()
		child = nvim.start({ env = { PATH = PI_DIR .. ':' .. vim.env.PATH } })
	end)

	after_each(function()
		nvim.stop(child)
	end)

	it('maps unfocus in the terminal :Pi opens', function()
		assert.is_true(child:exec_lua(
			[[
			vim.cmd('Pi')
			local buf = vim.api.nvim_get_current_buf()
			return vim.wait(5000, function()
				local channel = vim.bo[buf].channel
				return channel ~= 0 and vim.api.nvim_get_chan_info(channel).argv ~= nil
			end, 20)
		]],
			{}
		))
		assert.equal('pi: unfocus', child:exec_lua([[return vim.fn.maparg('<C-q>', 't', false, true).desc]], {}))
	end)

	-- A session saves the window as `term://…`, and restoring it re-runs the command through 'shell', so the terminal's
	-- argv becomes { '/bin/zsh', '-c', 'pi' } instead of { 'pi' }. plugin/pi.lua only looked at argv[1], so a restored
	-- window was left as a plain terminal.
	it('maps unfocus in a pi terminal restored through the shell', function()
		assert.is_true(child:exec_lua(
			[[
			vim.cmd('edit term://pi')
			local buf = vim.api.nvim_get_current_buf()
			return vim.wait(5000, function()
				local channel = vim.bo[buf].channel
				return channel ~= 0 and vim.api.nvim_get_chan_info(channel).argv ~= nil
			end, 20)
		]],
			{}
		))
		assert.equal('pi: unfocus', child:exec_lua([[return vim.fn.maparg('<C-q>', 't', false, true).desc]], {}))
	end)

	it('leaves a terminal that is not pi alone', function()
		assert.is_true(child:exec_lua(
			[[
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(buf)
			vim.fn.termopen({ 'sleep', '30' })
			return vim.wait(5000, function()
				local channel = vim.bo[buf].channel
				return channel ~= 0 and vim.api.nvim_get_chan_info(channel).argv ~= nil
			end, 20)
		]],
			{}
		))
		assert.equal('', child:exec_lua([[return vim.fn.maparg('<C-q>', 't')]], {}))
	end)
end)
