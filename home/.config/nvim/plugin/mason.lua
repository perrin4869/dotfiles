local yall = require('yall')

yall.setup('mason', {
	registries = {
		'file:' .. vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]], 'mason-registry'),
	},
})
for _, cmd in ipairs({ '', 'Install', 'Log', 'Uninstall', 'UninstallAll', 'Update' }) do
	yall.cmd('Mason' .. cmd, 'mason')
end
yall.hook('mason')
yall.very_lazy('mason')
