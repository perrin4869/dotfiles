local yall = require('yall')
yall.pack('dropbar', 'dropbar.nvim')
yall.on_bufreadpre('dropbar')

local pick = yall.with('dropbar')(function()
	require('dropbar.api').pick()
end)
require('map').map('n', '<leader>o', pick, 'dropbar.pick')
