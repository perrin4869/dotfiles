local utils = require("utils")

local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set("n", "<C-g>b", require("dropbar.api").pick, get_opts({ desc = "dropbar.pick" }))
