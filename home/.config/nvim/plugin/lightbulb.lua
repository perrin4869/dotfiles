local yall = require('yall')
yall.on_load('nvim-lightbulb', function()
	require('nvim-lightbulb').setup({
		autocmd = { enabled = true },
	})
end)
yall.on_event('nvim-lightbulb', 'LspAttach')
