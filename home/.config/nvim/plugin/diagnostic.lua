local defer = require("defer")
defer.very_lazy(function()
	local config = require("config")

	local map = config.create_map({
		mode = "n",
		desc = "diagnostic",
		rhs = function(func_name)
			return vim.diagnostic[func_name]
		end,
	})

	vim.diagnostic.config({
		float = { border = require("config").border },
		virtual_text = { current_line = true },
	})

	map("<leader>e", "open_float")
	map("<leader>q", "setloclist")

	local next_move = require("nvim-next.move")

	local prev_diag, next_diag = next_move.make_repeatable_pair(function()
		vim.diagnostic.jump({ count = -vim.v.count1 })
	end, function()
		vim.diagnostic.jump({ count = vim.v.count1 })
	end)
	config.map("n", "[d", prev_diag, "Go to previous diagnostic")
	config.map("n", "]d", next_diag, "Go to next diagnostic")

	-- This is nicer than having virtual text
	-- https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
	-- vim.api.nvim_create_autocmd("CursorHold", {
	-- 	callback = function()
	-- 		vim.diagnostic.open_float({ focusable = false })
	-- 	end,
	-- })
end)
