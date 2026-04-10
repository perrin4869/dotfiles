local yall = require('yall')
yall.pack('wrapped', 'wrapped.nvim')
yall.cmd('WrappedNvim', 'wrapped')
yall.cmd('NvimWrapped', 'wrapped')

require('map').map(
	'n',
	'<leader>W',
	yall.with('wrapped')(function()
		require('wrapped').run()
	end),
	'wrapped'
)
