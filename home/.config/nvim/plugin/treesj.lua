local defer = require("defer")

defer.on_load("treesj", function(tsj)
	tsj.setup({
		use_default_keymaps = false,
	})
end)

local with_tsj = defer.with("treesj")

local toggle = with_tsj(defer.call("toggle"))
local join = with_tsj(defer.call("join"))
local split = with_tsj(defer.call("split"))

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		local utils = require("utils")
		local get_opts = utils.create_get_opts({ buffer = args.buf, silent = true })

		vim.keymap.set("n", "<leader>mm", toggle, get_opts({ desc = "treesj.toggle" }))
		vim.keymap.set("n", "<leader>mj", join, get_opts({ desc = "treesj.join" }))
		vim.keymap.set("n", "<leader>ms", split, get_opts({ desc = "treesj.split" }))
	end,
})
