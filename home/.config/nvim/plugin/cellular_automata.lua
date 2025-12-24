local defer = require("defer")

defer.on_load("cellular-automaton", "cellular-automaton.nvim")
defer.hook("cellular-automaton")
defer.cmd("CellularAutomaton", "cellular-automaton")

-- for example "make_it_rain"
local get_animations = defer.lazy(function()
	return vim.tbl_keys(require("cellular-automaton").animations)
end)
local fml = function()
	local animations = get_animations()
	require("cellular-automaton").start_animation(animations[math.random(1, #animations)])
end
vim.keymap.set("n", "<leader>fml", fml, { noremap = true, silent = true })
