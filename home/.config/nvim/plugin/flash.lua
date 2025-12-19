local defer = require("defer")
local utils = require("utils")

defer.on_load("flash", function(flash)
	flash.setup({
		modes = { char = { enabled = false } },
	})
end) -- , "flash.nvim") -- "flash.nvim" is the folder name in pack/*/opt/
local with_flash = defer.with("flash")

local jump = with_flash(function(f)
	f.jump()
end)
local remote = with_flash(function(f)
	f.remote()
end)
local toggle = with_flash(function(f)
	f.toggle()
end)
local treesitter = with_flash(function(f)
	f.treesitter()
end)
local treesitter_search = with_flash(function(f)
	f.treesitter_search()
end)

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set({ "n", "x", "o" }, "<leader>s", jump, get_opts({ desc = "flash.jump" }))
vim.keymap.set("o", "r", remote, get_opts({ desc = "flash.remote" }))
vim.keymap.set("c", "<C-s>", toggle, get_opts({ desc = "flash.toggle" }))

-- Treesitter logic
vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<leader>S",
			treesitter,
			get_opts({ buffer = args.buf, desc = "flash.treesitter" })
		)

		vim.keymap.set(
			{ "o", "x" },
			"R",
			treesitter_search,
			get_opts({ buffer = args.buf, desc = "flash.treesitter_search" })
		)
	end,
})
