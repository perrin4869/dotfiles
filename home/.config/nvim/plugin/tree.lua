local defer = require("defer")

defer.on_load("neo-tree", function()
	require("neo-tree").setup({})
end)
defer.pack("neo-tree", "neo-tree.nvim")
defer.cmd("Neotree", "neo-tree")

local map = require("map").create({
	mode = "n",
	desc = "neo-tree",
	rhs = function(args)
		return function()
			vim.cmd.Neotree(args)
		end
	end,
})

local prefix = "<leader>n"
map(prefix .. "n", "toggle", "toggle")
map(prefix .. "f", "reveal_file=%:p", "focus-file")

-- ex bufname neo-tree filesystem [1]
require("restore").add_quitpre_ft("neo-tree")
require("restore").add_buf_match("neo%-tree filesystem", function()
	vim.cmd.Neotree("show")
end)
