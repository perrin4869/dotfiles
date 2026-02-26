local defer = require('defer')

defer.on_load('treesj', function()
	require('treesj').setup({
		use_default_keymaps = false,
	})
end)

local with = defer.with('treesj')

local toggle = with(function()
	require('treesj').toggle()
end)
local split = with(function()
	require('treesj').split()
end)
local join = with(function()
	require('treesj').join()
end)

defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local map = require('map').create({
				mode = 'n',
				desc = 'treesj',
				buffer = args.buf,
			})

			map('<leader>j', toggle, 'toggle')
			map('<C-j>', split, 'split')
			map('<C-k>', join, 'join')
		end,
	})
end)
