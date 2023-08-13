local flash = require("flash")
local utils = require("utils")

flash.setup({
	modes = {
		char = {
			enabled = false,
		},
		treesitter_search = {
			label = {
				rainbow = { enabled = true },
			},
		},
	},
})

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set({ "n", "x", "o" }, "<leader>s", flash.jump, get_opts({ desc = "flash.jump" }))
vim.keymap.set({ "n", "x", "o" }, "<leader>S", flash.treesitter, get_opts({ desc = "flash.treesitter" }))
vim.keymap.set("o", "r", flash.remote, get_opts({ desc = "flash.remote" }))
vim.keymap.set({ "o", "x" }, "R", flash.treesitter_search, get_opts({ desc = "flash.treesitter_search" }))
vim.keymap.set("c", "<C-s>", flash.toggle, get_opts({ desc = "flash.toggle" }))
