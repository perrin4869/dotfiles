local defer = require('defer')
defer.on_load('refactoring', function()
	require('refactoring').setup({})
end)
defer.pack('refactoring', 'refactoring.nvim')
defer.cmd('Refactor', 'refactoring')
local with = defer.with('refactoring')
local call = defer.call

local prefix = '<leader>,' -- official is `<leader>r`, but it is used by substitute.nvim
local map = require('map').create({
	desc = 'refactoring',
	mode = { 'n', 'x' },
	expr = true,
	rhs = function(rhs)
		return with(call('refactor', rhs))
	end,
})
map(prefix .. 'e', 'Extract Function')
map(prefix .. 'f', 'Extract Function To File')
map(prefix .. 'v', 'Extract Variable')
map(prefix .. 'I', 'Inline Function')
map(prefix .. 'i', 'Inline Variable')

map(prefix .. 'bb', 'Extract Block')
map(prefix .. 'bf', 'Extract Block To File')
