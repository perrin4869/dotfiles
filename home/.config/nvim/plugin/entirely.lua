local M = {}

-- Helper to set the marks without moving the cursor
local function set_marks()
	local buf = 0
	local last_line = vim.api.nvim_buf_line_count(buf)
	local last_line_content = vim.api.nvim_buf_get_lines(buf, last_line - 1, last_line, false)[1] or ""

	-- Set [ and ] marks (start and end of text object)
	vim.api.nvim_buf_set_mark(buf, "[", 1, 0, {})
	vim.api.nvim_buf_set_mark(buf, "]", last_line, #last_line_content, {})
end

-- 1. For Operator-pending (yae, dae, cae)
M.buffer_operator = function()
	local view = vim.fn.winsaveview()
	set_marks()

	-- We must "go to" the marks to define the range for the operator
	-- 'keepjumps' prevents this from appearing in your Ctrl-o list
	vim.cmd("keepjumps normal! `[V`]")

	-- Instantly snap back so the user never sees the jump
	vim.defer_fn(function()
		vim.fn.winrestview(view)
	end, 0)
end

-- 2. For Visual (vae)
M.buffer_visual = function()
	-- Clear current selection so we start fresh
	vim.cmd("normal! \27") -- \27 is the Escape code

	set_marks()

	-- Physically select the range
	vim.cmd("keepjumps normal! `[V`]")
end

-- Mappings
-- Note: 'o' mode requires a specific return or movement to trigger.
-- Calling the function directly works best here.
vim.keymap.set("o", "ae", M.buffer_operator, { desc = "Buffer text object (operator)" })
vim.keymap.set("x", "ae", M.buffer_visual, { desc = "Buffer text object (visual)" })
