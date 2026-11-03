local yall = require('yall')
yall.pack('pi', 'pi.nvim')
-- its default <leader>p prefix clashes with cokeline's buffer pick; <leader>P pairs with claudecode's <leader>C
yall.setup('pi', { keymap_prefix = '<leader>P' })
-- setup creates the keymaps, so it can't wait for a command
yall.very_lazy('pi')

local map = require('map').create({ desc = 'pi', desc_separator = ': ' })

--- @param bufnr integer
local function is_pi_terminal(bufnr)
	local ok, chan_info = pcall(vim.api.nvim_get_chan_info, vim.bo[bufnr].channel)
	if not ok or not chan_info.argv then
		return false
	end
	return vim.fs.basename(chan_info.argv[1] or '') == 'pi'
end

-- same as in the claude terminal: leave terminal mode and refocus the previous window in one step
vim.api.nvim_create_autocmd('TermOpen', {
	group = vim.api.nvim_create_augroup('pi_terminal_mappings', { clear = true }),
	callback = function(args)
		if is_pi_terminal(args.buf) then
			map('t', '<C-q>', '<C-\\><C-n><C-w>p', { buffer = args.buf, desc = 'unfocus' })
		end
	end,
})
