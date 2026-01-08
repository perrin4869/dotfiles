local defer = require("defer")

defer.on_load("treesj", function()
	require("treesj").setup({
		use_default_keymaps = false,
	})
end)

local with_tsj = defer.with("treesj")

defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			local utils = require("utils")
			local get_opts = utils.create_get_opts({ buffer = args.buf, silent = true })
			local map = function(lhs, fname)
				vim.keymap.set("n", lhs, with_tsj(defer.call(fname)), get_opts({ desc = "treesj." .. fname }))
			end

			map("<leader>j", "toggle")
			map("<C-j>", "split")
			map("<C-k>", "join")
		end,
	})
end)
