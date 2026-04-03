local defer = require('defer')

defer.on_load('copilot', function()
	require('copilot').setup({})
end)
defer.pack('copilot', 'copilot.lua')
defer.cmd('Copilot', 'copilot')
