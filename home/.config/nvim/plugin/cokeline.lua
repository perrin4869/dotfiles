local function setup()
	local is_picking_focus = require("cokeline/mappings").is_picking_focus
	local is_picking_close = require("cokeline/mappings").is_picking_close
	local pick = require("cokeline/mappings").pick
	local get_hex = require("cokeline.hlgroups").get_hl_attr

	local red = vim.g.terminal_color_1
	local yellow = vim.g.terminal_color_3

	require("cokeline").setup({
		show_if_buffers_are_at_least = 2,
		buffers = {
			filter_valid = function(buffer)
				return buffer.type ~= "terminal" and buffer.type ~= "quickfix"
			end,
		},
		default_hl = {
			fg = function(buffer)
				return buffer.is_focused and get_hex("Normal", "fg") or get_hex("Comment", "fg")
			end,
			bg = "NONE",
		},

		sidebar = {
			filetype = "neo-tree",
			components = {
				{
					text = "  neo-tree",
					fg = yellow,
					bg = get_hex("NeoTreeNormal", "bg"),
					style = "bold",
				},
			},
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
						.. (
							(is_picking_focus() or is_picking_close()) and buffer.pick_letter .. " "
							or buffer.devicon.icon
						)
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

	vim.keymap.set("n", "<leader>o", function()
		pick("focus")
	end, { silent = true, noremap = true, desc = "cokeline.pick.focus" })
end

local group = vim.api.nvim_create_augroup("LazyLoadCokeline", { clear = true })

vim.api.nvim_create_autocmd({ "BufAdd", "BufReadPost" }, {
	group = group,
	callback = function()
		-- Get a list of all listed buffers
		local listed_buffers = vim.fn.getbufinfo({ buflisted = 1 })

		if #listed_buffers >= 2 then
			setup()

			vim.api.nvim_del_augroup_by_id(group)
		end
	end,
})
