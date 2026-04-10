local yall = require('yall')

yall.on_load('mason', function()
	require('mason').setup({
		registries = {
			'file:' .. vim.fs.joinpath(vim.fn.stdpath('data'), 'mason-registry'),
		},
	})
end)
yall.cmd('MasonInstall', 'mason')
yall.hook('mason')
yall.very_lazy('mason')
