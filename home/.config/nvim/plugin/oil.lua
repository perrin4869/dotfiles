local yall = require('yall')

yall.on_load('oil', function()
	require('oil').setup()
end)
yall.pack('oil', 'oil.nvim')
yall.very_lazy('oil')
require('map').map('n', '-', vim.cmd.Oil, 'Open parent directory')
