local defer = require("defer")
defer.very_lazy(function()
	local packadd = vim.cmd.packadd
	packadd("vim-fat-finger")
	packadd("vim-caser")
	packadd("vim-illuminate")
end)
