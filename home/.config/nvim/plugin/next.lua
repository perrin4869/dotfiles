local yall = require('yall')
yall.setup('nvim-next', function()
	return {
		default_mappings = {
			repeat_style = 'original',
		},
		items = {
			require('nvim-next.builtins').f,
			require('nvim-next.builtins').t,
		},
	}
end)
yall.very_lazy('nvim-next')
