local yall = require('yall')

yall.setup('oil')
yall.pack('oil', 'oil.nvim')
yall.very_lazy('oil')
require('map').map('n', '-', vim.cmd.Oil, 'Open parent directory')
