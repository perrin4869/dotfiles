local yall = require('yall')

yall.setup('substitute')
yall.pack('substitute', 'substitute.nvim')
local with = yall.with('substitute')

local map = require('map').create({
	desc = 'substitute',
	rhs = function(fname)
		return with(function()
			require('substitute')[fname]()
		end)
	end,
})

local prefix = '<leader>r'
map('n', prefix .. '', 'operator')
map('n', prefix .. 'r', 'line')
map('n', prefix .. 'R', 'eol')
map('x', prefix .. '', 'visual')
