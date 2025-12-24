local utils = require("utils")

local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set("n", "<C-g>b", function()
	require("dropbar.api").pick()
end, get_opts({ desc = "dropbar.pick" }))
