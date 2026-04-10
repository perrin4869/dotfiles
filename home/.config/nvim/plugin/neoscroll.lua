local yall = require('yall')

yall.pack('neoscroll', 'neoscroll.nvim')
yall.very_lazy('neoscroll')
yall.on_load('neoscroll', function()
	require('neoscroll').setup({
		duration_multiplier = 0.9,
		easing = 'quintic',
	})
end)
