local next = require("nvim-next").setup({
	default_mappings = {
		repeat_style = "original",
	},
})

local functions = require("nvim-next.builtins.functions")
local f_backward, f_forward = next.make_repeatable_pair(functions.F, functions.f)
vim.keymap.set("n", "f", f_forward)
vim.keymap.set("n", "F", f_backward)

local t_backward, t_forward = next.make_repeatable_pair(functions.T, functions.t)
vim.keymap.set("n", "t", t_forward)
vim.keymap.set("n", "T", t_backward)
