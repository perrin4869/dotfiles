local defer = require("defer")

defer.on_load("oil", function()
	require("oil").setup()
end)
defer.pack("oil", "oil.nvim")
defer.very_lazy("oil")
vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open parent directory" })
