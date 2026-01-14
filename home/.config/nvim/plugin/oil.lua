local defer = require("defer")

defer.on_load("oil", function()
	require("oil").setup()
end)
defer.pack("oil", "oil.nvim")
defer.very_lazy("oil")
require("map").map("n", "-", vim.cmd.Oil, "Open parent directory")
