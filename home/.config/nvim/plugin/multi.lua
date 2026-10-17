-- Neovim >= 0.13 has multicursor built in, see `:h multicursor`.
-- Core defaults kept as-is: Q, [count]Q, {Visual}Q, <C-LeftMouse>, CTRL-L, gQ, ]C, [C, q=.
local map = require('map').create({
	desc = 'multicursor',
})

-- Leave a cursor at the current position and move to the line above/below,
-- so repeated presses extend a column of cursors (à la Sublime/VSCode).
local function add_vertical_cursor(dir)
	return function()
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_win_get_buf(win)
		local cursor = vim.api.nvim_win_get_cursor(win)
		local target = cursor[1] + dir
		if target < 1 or target > vim.api.nvim_buf_line_count(buf) then
			return
		end
		vim.api.nvim_mcursor(buf, cursor)
		vim.api.nvim_win_set_cursor(win, { target, cursor[2] })
	end
end

map({ 'n', 'x' }, '<c-up>', add_vertical_cursor(-1), 'add_cursor_up')
map({ 'n', 'x' }, '<c-down>', add_vertical_cursor(1), 'add_cursor_down')

-- Seed a cursor at every occurrence of the word under the cursor.
map('n', '<C-n>', function()
	vim.fn.setreg('/', [[\<]] .. vim.fn.expand('<cword>') .. [[\>]])
	vim.cmd.normal({ '1Q', bang = true })
end, 'match_add_cursor')

-- Place a cursor on each line of the visual selection (`{Visual}Q`).
map('x', '<leader>m', 'Q', 'add_cursor_per_line')
