local defer = require('defer')
local map = require('map').map
defer.very_lazy(function()
	vim.cmd.packadd('vim-unimpaired')

	local next_move = require('nvim-next.move')
	local trigger = require('trigger').trigger

	-- buffers
	local prev_buffers, next_buffers = trigger(
		'b',
		next_move.make_repeatable_pair(function()
			if package.loaded['cokeline'] then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes('<Plug>(cokeline-focus-prev)', true, false, true),
					'n',
					false
				)
			else
				vim.cmd('bprevious')
			end
		end, function()
			if package.loaded['cokeline'] then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes('<Plug>(cokeline-focus-next)', true, false, true),
					'n',
					false
				)
			else
				vim.cmd('bnext')
			end
		end)
	)

	map('n', '[b', prev_buffers, 'Go to previous buffer')
	map('n', ']b', next_buffers, 'Go to next buffer')

	-- see help [q and help ]q for the default mappings in neovim >= 0.11
	require('nvim-next.integrations').quickfix().setup()
end)
