local function select_entire_buffer()
	local buf = 0

	-- define the range (Start: Line 1, Col 0 | End: Last Line, Last Col)
	local start_row, start_col = 0, 0
	local end_row = vim.api.nvim_buf_line_count(buf) - 1
	local last_line_content = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, true)[1] or ""
	local end_col = math.max(0, #last_line_content)

	-- enter visual mode (linewise 'V' is usually best for "entire buffer")
	-- this satisfies the "If mapping ends in visual mode, operate on it" rule.
	local mode = vim.api.nvim_get_mode().mode
	if mode ~= "V" and mode ~= "v" and mode ~= "\22" then
		vim.cmd.normal({ "V", bang = true })
	end

	vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
	vim.cmd.normal({ "o", bang = true }) -- Swap cursor to other end
	vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

require("config").map({ "x", "o" }, "ae", select_entire_buffer, "Entire buffer (operator)")
