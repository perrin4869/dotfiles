local yall = require('yall')
yall.on_load('lsp-progress', function()
	require('lsp-progress').setup()
end)
