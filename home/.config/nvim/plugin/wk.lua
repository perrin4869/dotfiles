local defer = require('defer')

defer.on_load('which-key', function()
	local wk = require('which-key')
	wk.setup()
	wk.add({
		{ '<leader>b', group = 'buffers' },
		-- { '<leader>c', group = 'osc52' },
		{ '<leader>d', group = 'dap' },
		{ '<leader>g', group = 'fugitive' },
		{ '<leader>h', group = 'hunks' },
		{ '<leader>n', group = 'neotree' },
		{ '<leader>t', group = 'test' },
		{ '<leader>;', group = 'persistence' },
		{ '<leader>.', group = 'execute' }, -- only lua and vim files
		{ '\\', group = 'toggle' },
		{ require('pickers').prefix, group = 'telescope' },
	})
end)

defer.pack('which-key', 'which-key.nvim')
defer.very_lazy('which-key')
local with = defer.with('which-key')

require('map').map(
	'n',
	'<leader>?',
	with(function(wk)
		wk.show({ global = false })
	end),
	'Buffer Local Keymaps (which-key)'
)
