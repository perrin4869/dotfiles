local defer = require("defer")
defer.on_load("multicursor-nvim", function()
	local mc = require("multicursor-nvim")
	mc.setup()

	-- Mappings defined in a keymap layer only apply when there are
	-- multiple cursors. This lets you have overlapping mappings.
	mc.addKeymapLayer(function(layerSet)
		-- Select a different cursor as the main one.
		layerSet({ "n", "x" }, "<left>", mc.prevCursor)
		layerSet({ "n", "x" }, "<right>", mc.nextCursor)

		-- Delete the main cursor.
		layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

		-- Enable and clear cursors using escape.
		layerSet("n", "<esc>", function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			else
				mc.clearCursors()
			end
		end)
	end)

	-- Customize how cursors look.
	local hl = vim.api.nvim_set_hl
	hl(0, "MultiCursorCursor", { reverse = true })
	hl(0, "MultiCursorVisual", { link = "Visual" })
	hl(0, "MultiCursorSign", { link = "SignColumn" })
	hl(0, "MultiCursorMatchPreview", { link = "Search" })
	hl(0, "MultiCursorDisabledCursor", { reverse = true })
	hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
	hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
end)
defer.pack("multicursor-nvim", "multicursor.nvim")

local call = defer.call
local with_mc = defer.with("multicursor-nvim")

local map = function(mode, lhs, args, desc)
	vim.keymap.set(mode, lhs, with_mc(call(unpack(args))), { silent = true, desc = desc })
end

-- Add or skip cursor above/below the main cursor.
map({ "n", "x" }, "<c-up>", { "lineAddCursor", -1 }, "multicursor.add_line_up")
map({ "n", "x" }, "<c-down>", { "lineAddCursor", 1 }, "multicursor.add_line_down")
map({ "n", "x" }, "<c-s-up>", { "lineSkipCursor", -1 }, "multicursor.skip_line_up")
map({ "n", "x" }, "<c-s-down>", { "lineSkipCursor", 1 }, "multicursor.skip_line_down")

-- Add or skip adding a new cursor by matching word/selection
map({ "n", "x" }, "<C-n>", { "matchAddCursor", 1 }, "multicursor.match_add_cursor_down")
map({ "n", "x" }, "<C-s>", { "matchSkipCursor", 1 }, "multicursor.match_skip_cursor_down")
map({ "n", "x" }, "<C-M-n>", { "matchAddCursor", -1 }, "multicursor.match_add_cursor_up")
map({ "n", "x" }, "<C-M-s>", { "matchSkipCursor", -1 }, "multicursor.match_skip_cursor_up")
-- the official mappings above are <leader>n, <leader>s, <leader>N, <leader>S

-- Add and remove cursors with control + left click.
map("n", "<c-leftmouse>", { "handleMouse" }, "multicursor.handle_mouse")
map("n", "<c-leftdrag>", { "handleMouseDrag" }, "multicursor.handle_mouse_drag")
map("n", "<c-leftrelease>", { "handleMouseRelease" }, "multicursor.handle_mouse_release")

map({ "n", "x" }, "<leader>m", { "operator" }, "multicursor.operator")

-- Disable and enable cursors.
map({ "n", "x" }, "<c-q>", { "toggleCursor" }, "multicursor.toggleCursor")
-- consider also <leader>tm
