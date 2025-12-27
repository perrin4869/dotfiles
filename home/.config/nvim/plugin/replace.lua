local defer = require("defer")

defer.on_load("substitute", function(substitute)
	substitute.setup()
end, "substitute.nvim")
local with = defer.with("substitute")
local call = defer.call

local map = function(mode, lhs, func_name)
	vim.keymap.set(
		mode,
		"<leader>r" .. lhs,
		with(call(func_name)),
		{ silent = true, noremap = true, desc = "substitute." .. func_name }
	)
end

map("n", "", "operator")
map("n", "r", "line")
map("n", "R", "eol")
map("x", "", "visual")
