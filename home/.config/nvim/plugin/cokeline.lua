local is_picking_focus = require("cokeline/mappings").is_picking_focus
local is_picking_close = require("cokeline/mappings").is_picking_close
local get_hex = require("cokeline/utils").get_hex

local red = vim.g.terminal_color_1
local yellow = vim.g.terminal_color_3

require("cokeline").setup({
	show_if_buffers_are_at_least = 2,
	default_hl = {
		fg = function(buffer)
			return buffer.is_focused and get_hex("Normal", "fg") or get_hex("Comment", "fg")
		end,
		bg = "NONE",
	},

	components = {
		{
			text = function(buffer)
				return (buffer.index ~= 1) and "▏" or ""
			end,
			fg = get_hex("Normal", "fg"),
		},
		{
			text = function(buffer)
				return "    "
					.. ((is_picking_focus() or is_picking_close()) and buffer.pick_letter .. " " or buffer.devicon.icon)
			end,
			fg = function(buffer)
				return (is_picking_focus() and yellow) or (is_picking_close() and red) or buffer.devicon.color
			end,
			style = function(_)
				return (is_picking_focus() or is_picking_close()) and "italic,bold" or nil
			end,
		},
		{
			text = function(buffer)
				return buffer.filename
			end,
			style = function(buffer)
				return buffer.is_focused and "bold" or (buffer.is_hovered and "underline" or nil)
			end,
		},
		{
			text = function(buffer)
				return buffer.is_modified and " " or ""
			end,
		},
		{
			text = "    ",
		},
		{
			text = "󰅖",
			on_click = function(_, _, _, _, buffer)
				buffer:delete()
			end,
		},
		{
			text = "  ",
		},
	},
})

vim.keymap.set("n", "<leader>bp", "<Plug>(cokeline-pick-focus)", { silent = true, noremap = true })
