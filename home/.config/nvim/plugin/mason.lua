local yall = require('yall')

yall.setup('mason', {
	registries = {
		'file:' .. vim.fs.joinpath(vim.fn.stdpath('data'), 'mason-registry'),
	},
})
vim.iter({ '', 'Install', 'Log', 'Uninstall', 'UninstallAll', 'Update' }):each(function(cmd)
	yall.cmd('Mason' .. cmd, 'mason')
end)
yall.hook('mason')
yall.very_lazy('mason')
