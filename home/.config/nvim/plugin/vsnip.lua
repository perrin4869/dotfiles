local defer = require("defer")
defer.very_lazy(function()
	vim.cmd.packadd("vim-vsnip")
	vim.cmd.packadd("vim-vsnip-integ")

	-- more code from after/plugin
	-- https://github.com/hrsh7th/vim-vsnip-integ/blob/c7c93934dece8315db3649bdc6898b76358a8b8d/after/plugin/vsnip_integ.vim
	vim.fn["vsnip_integ#integration#attach"]()
end)
