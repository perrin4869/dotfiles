local yall = require('yall')

yall.pack('cellular-automaton', 'cellular-automaton.nvim')
yall.hook('cellular-automaton')
yall.cmd('CellularAutomaton', 'cellular-automaton')

-- for example "make_it_rain"
local get_animations = yall.lazy(function()
	return vim.tbl_keys(require('cellular-automaton').animations)
end)
local fml = function()
	local animations = get_animations()
	require('cellular-automaton').start_animation(animations[math.random(1, #animations)])
end
require('map').map('n', '<leader>fml', fml, 'fml')
