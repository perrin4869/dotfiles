local defer = require('defer')
defer.pack('wrapped', 'wrapped.nvim')
defer.cmd('WrappedNvim', 'wrapped')
defer.cmd('NvimWrapped', 'wrapped')

require('map').map(
	'n',
	'<leader>W',
	defer.with('wrapped')(function()
		require('wrapped').run()
	end),
	'wrapped'
)
