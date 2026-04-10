local yall = require('yall')

yall.on_load('difftastic-nvim', function()
	require('difftastic-nvim').setup()
end)
yall.pack('difftastic-nvim', 'difftastic.nvim')
yall.very_lazy('difftastic-nvim')
