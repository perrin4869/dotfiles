local defer = require("defer")

defer.on_load("oil", function(oil)
	oil.setup()
end, "oil.nvim")
defer.cmd("Oil", "oil")
vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open parent directory" })
