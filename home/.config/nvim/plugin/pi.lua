local yall = require('yall')
yall.pack('pi', 'pi.nvim')
-- its default <leader>p prefix clashes with cokeline's buffer pick; <leader>P pairs with claudecode's <leader>C
yall.setup('pi', { keymap_prefix = '<leader>P' })
-- setup creates the keymaps, so it can't wait for a command;
yall.very_lazy('pi')
for _, cmd in ipairs({
	'',
	'AddFile',
	'AddSelection',
	'Close',
	'Continue',
	'Focus',
	'Fork',
	'New',
	'NewNamed',
	'Open',
	'QuickChat',
	'Resume',
	'Send',
	'Session',
}) do
	yall.cmd('Pi' .. cmd, 'pi')
end

local map = require('map').create({ desc = 'pi', desc_separator = ': ' })

--- @param bufnr integer
local function is_pi_terminal(bufnr)
	local ok, chan_info = pcall(vim.api.nvim_get_chan_info, vim.bo[bufnr].channel)
	if not ok or not chan_info.argv then
		return false
	end
	-- a session restore respawns it through 'shell' ({ 'zsh', '-c', '/path/to/pi' })
	return vim.tbl_contains(chan_info.argv, function(arg)
		return vim.fs.basename(vim.split(arg, ' ')[1]) == 'pi'
	end, { predicate = true })
end

-- like the claude terminal, a session restore recreates pi as a plain terminal; replace it with the
-- pi.nvim-managed one, continuing the last session
require('restore').add_buf_match(
	is_pi_terminal,
	yall.with('pi')(function()
		require('pi').continue()
	end)
)

local group = vim.api.nvim_create_augroup('pi_terminal_mappings', { clear = true })

-- same as in the claude terminal: leave terminal mode and refocus the previous window in one step
vim.api.nvim_create_autocmd('TermOpen', {
	group = group,
	callback = function(args)
		if is_pi_terminal(args.buf) then
			map('t', '<C-q>', '<C-\\><C-n><C-w>p', { buffer = args.buf, desc = 'unfocus' })
		end
	end,
})

-- pi.nvim enters terminal mode only from its own commands; like snacks' auto_insert for the claude terminal, also do
-- it when moving into the pi window, e.g. with <C-w>l. BufEnter as well would cover bringing the pi buffer into the
-- window you are already in (":buffer"), but it fires beside WinEnter on every window move, so it is left out.
local pending_insert = false
vim.api.nvim_create_autocmd('WinEnter', {
	group = group,
	pattern = 'term://*',
	callback = function(args)
		if pending_insert or not is_pi_terminal(args.buf) then
			return
		end
		pending_insert = true
		-- startinsert applies to whichever window is current once this event finishes, and a session restore passes
		-- through the pi buffer on its way elsewhere; only enter terminal mode if pi is still where we are
		vim.schedule(function()
			pending_insert = false
			if vim.api.nvim_get_current_buf() == args.buf and vim.api.nvim_get_mode().mode == 'nt' then
				vim.cmd.startinsert()
			end
		end)
	end,
})
