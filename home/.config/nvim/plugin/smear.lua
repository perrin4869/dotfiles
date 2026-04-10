local yall = require('yall')

yall.on_load('smear_cursor', function()
	require('smear_cursor').enabled = true
end)
yall.very_lazy('smear_cursor')
