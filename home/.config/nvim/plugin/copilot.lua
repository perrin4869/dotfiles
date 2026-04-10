local yall = require('yall')

local options = {}
yall.on_load('copilot', function()
	require('copilot').setup(options)
end)
yall.pack('copilot', 'copilot.lua')
yall.cmd('Copilot', 'copilot')

yall.on_load('copilot_ls', function()
	vim.keymap.set('n', '<tab>', function()
		local bufnr = vim.api.nvim_get_current_buf()
		local state = vim.b[bufnr].nes_state
		if state then
			-- Try to jump to the start of the suggestion edit.
			-- If already at the start, then apply the pending suggestion and jump to the end of the edit.
			local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
				or (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
			return nil
		else
			-- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
			return '<C-i>'
		end
	end, { desc = 'Accept Copilot NES suggestion', expr = true })
	vim.g.copilot_nes_debounce = 500
	vim.lsp.enable('copilot_ls')
end)
yall.pack('copilot_ls', 'copilot-lsp')

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
