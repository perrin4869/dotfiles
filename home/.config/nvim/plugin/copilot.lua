local yall = require('yall')

local options = {}
if vim.g.enable_copilot_ls then
	yall.on_insert('copilot')
	yall.deps('copilot', 'copilot_ls')
	options.nes = {
		enabled = true,
		keymap = {
			accept_and_goto = '<leader>p',
			accept = false,
			dismiss = '<Esc>',
		},
	}
end
yall.setup('copilot', options)
yall.pack('copilot', 'copilot.lua')
yall.cmd('Copilot', 'copilot')

yall.on_load('copilot_ls', function()
	vim.g.copilot_nes_debounce = 500
	vim.lsp.enable('copilot_ls')
end)
yall.pack('copilot_ls', 'copilot-lsp')
