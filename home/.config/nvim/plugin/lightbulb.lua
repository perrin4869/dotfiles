local yall = require('yall')
yall.setup('nvim-lightbulb', {
	autocmd = { enabled = true },
})
yall.on_event('nvim-lightbulb', 'LspAttach')
