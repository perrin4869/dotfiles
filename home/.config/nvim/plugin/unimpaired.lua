local next_move = require("nvim-next.move")

-- buffers
local prev_buffers, next_buffers = next_move.make_repeatable_pair(function()
	vim.cmd("bprevious")
end, function()
	vim.cmd("bnext")
end)

vim.keymap.set("n", "[b", prev_buffers, { silent = true, desc = "Go to previous buffer" })
vim.keymap.set("n", "]b", next_buffers, { silent = true, desc = "Go to next buffer" })

local prev_qf_item, next_qf_item = next_move.make_repeatable_pair(function(_)
	local status, err = pcall(vim.cmd, "cprevious")
	if not status then
		vim.notify("No more items", vim.log.levels.INFO)
	end
end, function(_)
	local status, err = pcall(vim.cmd, "cnext")
	if not status then
		vim.notify("No more items", vim.log.levels.INFO)
	end
end)

-- see help [q and help ]q for the default mappings in neovim >= 0.11
vim.keymap.set("n", "[q", prev_qf_item, { desc = "nvim-next: prev qfix" })
vim.keymap.set("n", "]q", next_qf_item, { desc = "nvim-next: next qfix" })
