local flash = require("flash")
local utils = require("utils")

flash.setup({
	modes = {
		char = {
			-- disables f/F/t/T, would need to integrate with nvim-next
			enabled = false,
		},
	},
})

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set({ "n", "x", "o" }, "<leader>s", flash.jump, get_opts({ desc = "flash.jump" }))
vim.keymap.set("o", "r", flash.remote, get_opts({ desc = "flash.remote" }))
vim.keymap.set("c", "<C-s>", flash.toggle, get_opts({ desc = "flash.toggle" }))

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		-- duplicate functionality with tree-hopper
		vim.keymap.set(
			{ "n", "x", "o" },
			"<leader>S",
			flash.treesitter,
			get_opts({ buffer = args.buf, desc = "flash.treesitter" })
		)

		vim.keymap.set(
			{ "o", "x" },
			"R",
			flash.treesitter_search,
			get_opts({ buffer = args.buf, desc = "flash.treesitter_search" })
		)
	end,
})
