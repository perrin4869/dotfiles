local yall = require('yall')
yall.pack('undotree', 'nvim.undotree')

local with_undotree = yall.with('undotree')

local map = require('map').create({
	mode = 'n',
	desc = 'undotree',
})

map(
	vim.g.toggle_prefix .. 'u',
	with_undotree(function()
		require('undotree').open()
	end),
	'toggle'
)

yall.cmd('Undotree', 'undotree')
