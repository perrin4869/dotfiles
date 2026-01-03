local defer = require("defer")

defer.on_load("treesj", function()
	require("treesj").setup({
		use_default_keymaps = false,
	})
end)

local with_tsj = defer.with("treesj")

local toggle = with_tsj(defer.call("toggle"))
local join = with_tsj(defer.call("join"))
local split = with_tsj(defer.call("split"))

defer.on_bufenter(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			local utils = require("utils")
			local get_opts = utils.create_get_opts({ buffer = args.buf, silent = true })

			vim.keymap.set("n", "<leader>ts", toggle, get_opts({ desc = "treesj.toggle" }))
			vim.keymap.set("n", "<C-j>", join, get_opts({ desc = "treesj.join" }))
			vim.keymap.set("n", "<C-k>", split, get_opts({ desc = "treesj.split" }))
		end,
	})
end)
