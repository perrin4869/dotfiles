local defer = require('defer')

local options = {}
defer.on_load('copilot', function()
	require('copilot').setup(options)
end)
defer.pack('copilot', 'copilot.lua')
defer.cmd('Copilot', 'copilot')

defer.on_load('copilot_ls', function()
	vim.g.copilot_nes_debounce = 500
	vim.lsp.enable('copilot_ls')
end)
defer.pack('copilot_ls', 'copilot-lsp')

if vim.g.enable_copilot_ls then
	defer.on_insert('copilot')
	defer.deps('copilot', 'copilot_ls')
	options.nes = {
		enabled = true,
		keymap = {
			accept_and_goto = '<leader>p',
			accept = false,
			dismiss = '<Esc>',
		},
	}
end
