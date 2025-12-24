local defer = require("defer")
defer.very_lazy(function()
	vim.cmd.packadd("vim-visual-multi")
end)
