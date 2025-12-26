local defer = require("defer")
local utils = require("utils")

defer.on_load("persistence", function(persistence)
	persistence.setup()
end, "persistence.nvim")
defer.hook("persistence")
defer.on_event("persistence", "BufReadPre")

local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

-- restore the session for the current directory
vim.keymap.set("n", "<leader>qs", function()
	require("persistence").load()
end, get_opts({ desc = "persistence.load" }))

-- restore the last session
vim.keymap.set("n", "<leader>ql", function()
	require("persistence").load({ last = true })
end, get_opts({ desc = "persistence.load_last" }))

-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", function()
	require("persistence").stop()
end, get_opts({ desc = "persistence.stop" }))
