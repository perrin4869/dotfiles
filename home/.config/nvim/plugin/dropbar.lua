local defer = require("defer")
defer.pack("dropbar", "dropbar.nvim")
defer.on_bufenter("dropbar")

local map = vim.keymap.set
local pick = defer.with("dropbar")(function()
	require("dropbar.api").pick()
end)
map("n", "<leader>o", pick, { noremap = true, silent = true, desc = "dropbar.pick" })
