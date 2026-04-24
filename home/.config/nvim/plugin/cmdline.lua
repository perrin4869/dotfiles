local yall = require('yall')

vim.o.cmdheight = 0
vim.g.tiny_cmdline = {
	width = { value = '70%' },
}
yall.pack('tiny-cmdline', 'tiny-cmdline.nvim')
yall.on_bufreadpre('tiny-cmdline')
