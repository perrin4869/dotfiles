local defer = require("defer")

defer.on_load("nvim-treeclimber", function(treeclimber)
	treeclimber.setup({})
end, "nvim-treeclimber")

local with_tc = defer.with("nvim-treeclimber")

local function plug(name)
	return with_tc(function()
		local code = vim.api.nvim_replace_termcodes(name, true, true, true)
		vim.api.nvim_feedkeys(code, "m", true)
	end)
end

local show_control_flow = plug("<Plug>(treeclimber-show-control-flow)")
local select_node = plug("<Plug>(treeclimber-select-current-node)")
local select_expand = plug("<Plug>(treeclimber-select-expand)")
local select_forward_end = plug("<Plug>(treeclimber-select-forward-end)")
local select_backward = plug("<Plug>(treeclimber-select-backward)")
local select_previous = plug("<Plug>(treeclimber-select-previous)")
local select_shrink = plug("<Plug>(treeclimber-select-shrink)")
local select_parent = plug("<Plug>(treeclimber-select-parent)")
local select_next = plug("<Plug>(treeclimber-select-next)")
local grow_forward = plug("<Plug>(treeclimber-select-grow-forward)")
local grow_backward = plug("<Plug>(treeclimber-select-grow-backward)")
local siblings_backward = plug("<Plug>(treeclimber-select-siblings-backward)")
local siblings_forward = plug("<Plug>(treeclimber-select-siblings-forward)")
local select_top_level = plug("<Plug>(treeclimber-select-top-level)")

defer.on_event(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			local function map(modes, lhs, thunk, desc)
				vim.keymap.set(modes, lhs, thunk, { buffer = args.buf, silent = true, desc = desc })
			end

			map("n", "<leader>k", show_control_flow, "treeclimber: control flow")

			map({ "x", "o" }, "i.", select_node, "treeclimber: select node")
			map({ "x", "o" }, "a.", select_expand, "treeclimber: expand")

			map({ "n", "x", "o" }, "<M-e>", select_forward_end, "treeclimber: forward end")
			map({ "n", "x", "o" }, "<M-b>", select_backward, "treeclimber: backward")
			map({ "n", "x", "o" }, "<M-h>", select_previous, "treeclimber: previous")
			map({ "n", "x", "o" }, "<M-j>", select_shrink, "treeclimber: shrink")
			map({ "n", "x", "o" }, "<M-k>", select_parent, "treeclimber: parent")
			map({ "n", "x", "o" }, "<M-l>", select_next, "treeclimber: next")

			map({ "n", "x", "o" }, "<M-L>", grow_forward, "treeclimber: grow forward")
			map({ "n", "x", "o" }, "<M-H>", grow_backward, "treeclimber: grow backward")

			map({ "n", "x", "o" }, "<M-[>", siblings_backward, "treeclimber: siblings backward")
			map({ "n", "x", "o" }, "<M-]>", siblings_forward, "treeclimber: siblings forward")
			map({ "n", "x", "o" }, "<M-g>", select_top_level, "treeclimber: top level")
		end,
	})
end, "BufEnter", { name = "treesitter-treeclimber" })
