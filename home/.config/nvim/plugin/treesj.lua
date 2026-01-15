local defer = require('defer')

defer.on_load('treesj', function()
	require('treesj').setup({
		use_default_keymaps = false,
	})
end)

local with_tsj = defer.with('treesj')

defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local map = require('map').create({
				mode = 'n',
				desc = 'treesj',
				buffer = args.buf,
				rhs = function(fname)
					return with_tsj(defer.call(fname))
				end,
			})

			map('<leader>j', 'toggle')
			map('<C-j>', 'split')
			map('<C-k>', 'join')
		end,
	})
end)
