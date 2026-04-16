local yall = require('yall')
yall.pack('splitjoin', 'splitjoin.nvim')
yall.very_lazy('splitjoin')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local with = yall.with('splitjoin')
			local map = require('map').create({
				mode = 'n',
				desc = 'splitjoin',
				buffer = args.buf,
				rhs = function(l)
					return with(function()
						require('splitjoin')[l]()
					end)
				end,
			})

			map('<leader>,', 'toggle')
			map('<leader>j', 'split')
			map('<leader>k', 'join')
		end,
	})
end)
