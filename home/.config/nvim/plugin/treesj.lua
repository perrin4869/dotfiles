local yall = require('yall')

yall.setup('treesj', {
	use_default_keymaps = false,
})

local with = yall.with('treesj')

local toggle = with(function()
	require('treesj').toggle()
end)
local split = with(function()
	require('treesj').split()
end)
local join = with(function()
	require('treesj').join()
end)

yall.on_bufreadpre(function()
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
