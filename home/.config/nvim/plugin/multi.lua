local defer = require('defer')
defer.on_load('multicursor-nvim', function()
	local mc = require('multicursor-nvim')
	mc.setup()

	-- Mappings defined in a keymap layer only apply when there are
	-- multiple cursors. This lets you have overlapping mappings.
	mc.addKeymapLayer(function(layerSet)
		-- Select a different cursor as the main one.
		layerSet({ 'n', 'x' }, '<left>', mc.prevCursor)
		layerSet({ 'n', 'x' }, '<right>', mc.nextCursor)

		-- Delete the main cursor.
		layerSet({ 'n', 'x' }, '<leader>x', mc.deleteCursor)

		-- Enable and clear cursors using escape.
		layerSet('n', '<esc>', function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			else
				mc.clearCursors()
			end
		end)
	end)

	-- Customize how cursors look.
	local hl = vim.api.nvim_set_hl
	hl(0, 'MultiCursorCursor', { reverse = true })
	hl(0, 'MultiCursorVisual', { link = 'Visual' })
	hl(0, 'MultiCursorSign', { link = 'SignColumn' })
	hl(0, 'MultiCursorMatchPreview', { link = 'Search' })
	hl(0, 'MultiCursorDisabledCursor', { reverse = true })
	hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
	hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
end)
defer.pack('multicursor-nvim', 'multicursor.nvim')

local with = defer.with('multicursor-nvim')

local line_add_cursor = function(dir)
	return with(function()
		require('multicursor-nvim').lineAddCursor(dir)
	end)
end

local line_skip_cursor = function(dir)
	return with(function()
		require('multicursor-nvim').lineAddCursor(dir)
	end)
end

local match_add_cursor = function(dir)
	return with(function()
		require('multicursor-nvim').matchAddCursor(dir)
	end)
end

local match_skip_cursor = function(dir)
	return with(function()
		require('multicursor-nvim').matchAddCursor(dir)
	end)
end

local handle_mouse = with(function()
	require('multicursor-nvim').handleMouse()
end)

local handle_mouse_drag = with(function()
	require('multicursor-nvim').handleMouseDrag()
end)

local handle_mouse_release = with(function()
	require('multicursor-nvim').handleMouseRelease()
end)

local operator = with(function()
	require('multicursor-nvim').operator()
end)

local toggle_cursor = with(function()
	require('multicursor-nvim').toggleCursor()
end)

local map = require('map').create({
	desc = 'multicursor',
})

-- Add or skip cursor above/below the main cursor.
map({ 'n', 'x' }, '<c-up>', line_add_cursor(-1), 'add_line_up')
map({ 'n', 'x' }, '<c-down>', line_add_cursor(1), 'add_line_down')
map({ 'n', 'x' }, '<c-s-up>', line_skip_cursor(-1), 'skip_line_up')
map({ 'n', 'x' }, '<c-s-down>', line_skip_cursor(1), 'skip_line_down')

-- Add or skip adding a new cursor by matching word/selection
map({ 'n', 'x' }, '<C-n>', match_add_cursor(1), 'match_add_cursor_down')
map({ 'n', 'x' }, '<C-M-n>', match_add_cursor(-1), 'match_add_cursor_up')
map({ 'n', 'x' }, '<C-s>', match_skip_cursor(1), 'match_skip_cursor_down')
map({ 'n', 'x' }, '<C-M-s>', match_skip_cursor(-1), 'match_skip_cursor_up')
-- the official mappings above are <leader>n, <leader>s, <leader>N, <leader>S

-- Add and remove cursors with control + left click.
map('n', '<c-leftmouse>', handle_mouse, 'handle_mouse')
map('n', '<c-leftdrag>', handle_mouse_drag, 'handle_mouse_drag')
map('n', '<c-leftrelease>', handle_mouse_release, 'handle_mouse_release')

map({ 'n', 'x' }, '<leader>m', operator, 'operator')

-- Disable and enable cursors.
map({ 'n', 'x' }, '<c-q>', toggle_cursor, 'toggleCursor')
-- consider also vim.g.toggle_prefix .. m
