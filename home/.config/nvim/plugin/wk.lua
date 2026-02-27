local defer = require('defer')

defer.on_load('which-key', function()
	local wk = require('which-key')
	wk.setup()
	wk.add({
		{ '<leader>b', group = 'buffers' },
		{ '<leader>c', group = 'osc52' },
		{ '<leader>d', group = 'dap' },
		{ '<leader>f', group = 'format' },
		{ '<leader>g', group = 'fugitive' },
		{ '<leader>h', group = 'hunks' },
		{ '<leader>n', group = 'neotree' },
		{ '<leader>t', group = 'test' },
		{ '<leader>u', group = 'undotree' },
		{ '<leader>x', group = 'trouble' },
		{ '<leader>,', group = 'refactoring' },
		{ '<leader>.', group = 'execute' }, -- only lua and vim files
		{ '<leader>;', group = 'persistence' },
		{ '\\', group = 'toggle' },
		{ require('pickers').prefix, group = 'telescope' },
		{ require('pickers').prefix .. 'd', group = 'telescope.dap' },
		{ require('pickers').prefix .. 'g', group = 'telescope.git' },
		{ require('pickers').prefix .. 'l', group = 'telescope.lsp' },
	})
end)

defer.pack('which-key', 'which-key.nvim')
defer.very_lazy('which-key')
local with = defer.with('which-key')

require('map').map(
	'n',
	'<leader>?',
	with(function()
		require('which-key').show({ global = false })
	end),
	'Buffer Local Keymaps (which-key)'
)
