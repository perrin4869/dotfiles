local defer = require("defer")
defer.very_lazy(function()
	local util = require("utils")

	local opts = { noremap = true, silent = true }
	local get_opts = util.create_get_opts(opts)

	vim.diagnostic.config({
		float = { border = util.border },
		virtual_text = { current_line = true },
	})

	vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, get_opts({ desc = "diagnostic.open_float" }))
	vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, get_opts({ desc = "diagnostic.setloclist" }))

	local next_move = require("nvim-next.move")

	local prev_diag, next_diag = next_move.make_repeatable_pair(function()
		vim.diagnostic.jump({ count = -vim.v.count1 })
	end, function()
		vim.diagnostic.jump({ count = vim.v.count1 })
	end)
	vim.keymap.set("n", "[d", prev_diag, { silent = true, desc = "Go to previous diagnostic" })
	vim.keymap.set("n", "]d", next_diag, { silent = true, desc = "Go to next diagnostic" })

	-- This is nicer than having virtual text
	-- https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
	-- vim.api.nvim_create_autocmd("CursorHold", {
	-- 	callback = function()
	-- 		vim.diagnostic.open_float({ focusable = false })
	-- 	end,
	-- })
end)
