local yall = require('yall')
yall.pack('regexplainer', 'nvim-regexplainer')
yall.very_lazy('regexplainer')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local with = yall.with('regexplainer')
			local map = require('map').create({
				mode = 'n',
				desc = 'regexplainer',
				buffer = args.buf,
				rhs = function(l)
					return with(function()
						require('regexplainer')[l]()
					end)
				end,
			})

			map('<leader>RR', 'toggle')
			map('<leader>Ry', 'yank')
		end,
	})
end)
