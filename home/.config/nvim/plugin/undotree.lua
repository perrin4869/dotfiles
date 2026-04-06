local defer = require('defer')
defer.pack('undotree', 'nvim.undotree')

local with_undotree = defer.with('undotree')

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

defer.cmd('Undotree', 'undotree')
