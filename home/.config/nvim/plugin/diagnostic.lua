local yall = require('yall')
yall.very_lazy(function()
	local map = require('map').create({
		mode = 'n',
		desc = 'diagnostic',
		rhs = function(func_name)
			return vim.diagnostic[func_name] --[[@as function]]
		end,
	})

	vim.diagnostic.config({
		float = { border = require('config').border },
		virtual_text = { current_line = true },
	})

	map('<leader>e', 'open_float')
	map('<leader>q', 'setloclist')

	local next_move = require('nvim-next.move')
	-- nvim-next's two return values are lost to the type checker, which would see one argument short
	---@type fun(prev: function, next: function): function, function
	local make_repeatable_pair = next_move.make_repeatable_pair
	local trigger = require('trigger').trigger

	local prev_diag, next_diag = trigger(
		'd',
		make_repeatable_pair(function()
			vim.diagnostic.jump({ count = -vim.v.count1 })
		end, function()
			vim.diagnostic.jump({ count = vim.v.count1 })
		end)
	)
	require('map').map('n', '[d', prev_diag, { desc = 'Go to previous diagnostic', unique = false }) -- overrides default
	require('map').map('n', ']d', next_diag, { desc = 'Go to next diagnostic', unique = false }) -- overrides default

	-- This is nicer than having virtual text
	-- https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
	-- vim.api.nvim_create_autocmd("CursorHold", {
	-- 	callback = function()
	-- 		vim.diagnostic.open_float({ focusable = false })
	-- 	end,
	-- })
end)
