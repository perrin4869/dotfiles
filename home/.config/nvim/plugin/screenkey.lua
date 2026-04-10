local yall = require('yall')

yall.pack('screenkey', 'screenkey.nvim')
yall.cmd('Screenkey', 'screenkey')

require('map').map(
	'n',
	vim.g.toggle_prefix .. 'k',
	yall.with('screenkey')(function()
		require('screenkey').toggle()
	end),
	'screenkey.toggle'
)
