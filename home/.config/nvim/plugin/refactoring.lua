local yall = require('yall')
yall.setup('refactoring')
yall.pack('refactoring', 'refactoring.nvim')
yall.cmd('Refactor', 'refactoring')
local with = yall.with('refactoring')

local prefix = '<leader>.' -- official is `<leader>r`, but it is used by substitute.nvim
local map = require('map').create({
	desc = 'refactoring',
	mode = { 'n', 'x' },
	expr = true,
	rhs = function(rhs)
		return with(function()
			require('refactoring').refactor(rhs)
		end)
	end,
})
map(prefix .. 'e', 'Extract Function')
map(prefix .. 'f', 'Extract Function To File')
map(prefix .. 'v', 'Extract Variable')
map(prefix .. 'I', 'Inline Function')
map(prefix .. 'i', 'Inline Variable')

map(prefix .. 'bb', 'Extract Block')
map(prefix .. 'bf', 'Extract Block To File')
