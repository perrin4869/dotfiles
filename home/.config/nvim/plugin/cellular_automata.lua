local automaton = require("cellular-automaton")

-- for example "make_it_rain"
local animations = vim.tbl_keys(automaton.animations)
local fml = function()
	automaton.start_animation(animations[math.random(1, #animations)])
end
vim.keymap.set("n", "<leader>fml", fml, { noremap = true, silent = true })
