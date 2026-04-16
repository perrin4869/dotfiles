local yall = require('yall')

yall.pack('neoscroll', 'neoscroll.nvim')
yall.very_lazy('neoscroll')
yall.setup('neoscroll', {
	duration_multiplier = 0.9,
	easing = 'quintic',
})
