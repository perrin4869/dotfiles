local assert = require('luassert')
local cleanup = require('helpers/cleanup')
local trigger = require('trigger')

before_each(cleanup.reset)
after_each(cleanup.clean)

describe('trigger', function()
	it('overrides the key while the repeat lasts', function()
		cleanup.mapping('n', 'gX')
		local calls = 0
		local wrapped = trigger.trigger('gX', function()
			calls = calls + 1
		end, function() end, 50)
		wrapped()
		assert.equal(1, calls)
		assert.equal('Sticky repeat: gX', vim.fn.maparg('gX', 'n', false, true).desc)
	end)

	it('removes the override once the timeout passes', function()
		cleanup.mapping('n', 'gY')
		trigger.trigger('gY', function() end, function() end, 20)()
		assert.is_not_nil(vim.fn.maparg('gY', 'n', false, true).desc)
		vim.wait(500, function()
			return vim.fn.maparg('gY', 'n') == ''
		end)
		assert.equal('', vim.fn.maparg('gY', 'n'))
	end)

	it('puts back a mapping it overrode', function()
		cleanup.mapping('n', 'gZ')
		vim.keymap.set('n', 'gZ', ':echo 1<cr>', { desc = 'mine' })
		trigger.trigger('gZ', function() end, function() end, 20)()
		assert.equal('Sticky repeat: gZ', vim.fn.maparg('gZ', 'n', false, true).desc)
		vim.wait(500, function()
			return vim.fn.maparg('gZ', 'n', false, true).desc == 'mine'
		end)
		assert.equal('mine', vim.fn.maparg('gZ', 'n', false, true).desc)
	end)
end)
