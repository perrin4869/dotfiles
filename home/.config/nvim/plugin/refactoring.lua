local yall = require('yall')
yall.pack('async', 'async.nvim')
yall.setup('refactoring')
yall.pack('refactoring', 'refactoring.nvim')
yall.deps('refactoring', 'async')
yall.cmd('Refactor', 'refactoring')
local with = yall.with('refactoring')

local prefix = '<leader>.' -- official is `<leader>r`, but it is used by substitute.nvim
local map = require('map').create({
	desc = 'refactoring',
	mode = { 'n', 'x' },
	expr = true,
	rhs = function(rhs)
		return with(function()
			require('refactoring')[rhs]()
		end)
	end,
})
map(prefix .. 'e', 'extract_func', 'Extract Function')
map(prefix .. 'f', 'extract_func_to_file', 'Extract Function To File')
map(prefix .. 'v', 'extract_var', 'Extract Variable')
map(prefix .. 'I', 'inline_var', 'Inline Function')
map(prefix .. 'i', 'inline_func', 'Inline Variable')
