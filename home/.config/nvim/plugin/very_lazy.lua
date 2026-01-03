local defer = require("defer")
defer.very_lazy(function()
	local packadd = vim.cmd.packadd
	packadd("vim-caser")
	packadd("vim-illuminate")
	packadd("vim-floaterm")
	packadd("vim-fugitive")
end)

defer.on_insert(function()
	local packadd = vim.cmd.packadd
	packadd("vim-fat-finger")
end)
