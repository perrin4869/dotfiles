local yall = require('yall')

vim.o.cmdheight = 0
vim.g.tiny_cmdline = {
	width = { value = '70%' },
}
yall.pack('tiny-cmdline', 'tiny-cmdline.nvim')
yall.deps('tiny-cmdline', 'ui2')
yall.on_bufenter('tiny-cmdline')
