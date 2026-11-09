---@diagnostic disable: undefined-field -- luassert hangs its own fields on `assert`
local pi_terminal = require('pi_terminal')

describe('pi_terminal.matches', function()
	it('matches pi by name and by path', function()
		assert.is_true(pi_terminal.matches({ 'pi' }))
		assert.is_true(pi_terminal.matches({ '/usr/local/bin/pi' }))
	end)

	it('ignores another terminal', function()
		assert.is_false(pi_terminal.matches({ '/bin/zsh' }))
		assert.is_false(pi_terminal.matches({ '/usr/local/bin/pi-ide' }))
	end)

	it('ignores a terminal with no command', function()
		assert.is_false(pi_terminal.matches(nil))
		assert.is_false(pi_terminal.matches({}))
	end)
end)
