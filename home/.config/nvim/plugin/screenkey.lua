local defer = require('defer')

defer.pack('screenkey', 'screenkey.nvim')
defer.cmd('Screenkey', 'screenkey')

require('map').map(
	'n',
	vim.g.toggle_prefix .. 'k',
	defer.with('screenkey')(function()
		require('screenkey').toggle()
	end),
	'screenkey.toggle'
)
