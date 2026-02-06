local defer = require('defer')
defer.very_lazy(function()
	vim.cmd.packadd('vim-unimpaired')

	-- see help [q and help ]q for the default mappings in neovim >= 0.11
	require('nvim-next.integrations').quickfix().setup()
end)
