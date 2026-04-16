local yall = require('yall')

yall.setup('mason', {
	registries = {
		'file:' .. vim.fs.joinpath(vim.fn.stdpath('data'), 'mason-registry'),
	},
})
yall.cmd('MasonInstall', 'mason')
yall.hook('mason')
yall.very_lazy('mason')
