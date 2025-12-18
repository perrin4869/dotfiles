local next_move = require("nvim-next.move")

-- buffers
local prev_buffers, next_buffers = next_move.make_repeatable_pair(function()
	vim.cmd("bprevious")
end, function()
	vim.cmd("bnext")
end)

vim.keymap.set("n", "[b", prev_buffers, { silent = true, desc = "Go to previous buffer" })
vim.keymap.set("n", "]b", next_buffers, { silent = true, desc = "Go to next buffer" })

-- see help [q and help ]q for the default mappings in neovim >= 0.11
require("nvim-next.integrations").quickfix().setup()
