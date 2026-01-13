local defer = require("defer")
local utils = require("utils")

defer.on_load("neo-tree", function()
	require("neo-tree").setup({})
end)
defer.pack("neo-tree", "neo-tree.nvim")
defer.cmd("Neotree", "neo-tree")

local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set("n", "<leader>nn", function()
	vim.cmd.Neotree("toggle")
end, get_opts({ desc = "neo-tree.toggle" }))
vim.keymap.set("n", "<leader>nf", function()
	vim.cmd.Neotree("reveal_file=%:p")
	-- require("nvim-tree.api").tree.find_file({ focus = true, open = true })
end, get_opts({ desc = "neo-tree.focus-file" }))

-- ex bufname neo-tree filesystem [1]
require("restore").add_quitpre_ft("neo-tree")
require("restore").add_buf_match("neo%-tree filesystem", function()
	vim.cmd.Neotree("show")
end)
