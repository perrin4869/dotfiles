local defer = require('defer')
defer.pack('tsht', 'nvim-treehopper')
defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local map = require('map').create({
				desc = 'treehopper',
				buffer = args.buf,
			})
			-- duplicate functionality with flash.treesitter
			map('o', 'm', function()
				defer.require('tsht').nodes()
			end, 'nodes')

			-- ":<C-u>lua require('tsht').nodes()<CR>",
			map('x', 'm', function()
				vim.cmd.normal({ '!gv' })
				defer.require('tsht').nodes()
			end, 'nodes')
		end,
	})
end)

-- omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
-- xnoremap <silent> m :lua require('tsht').nodes()<CR>
