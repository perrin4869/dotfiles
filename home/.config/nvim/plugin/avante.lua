local defer = require('defer')
defer.pack('avante', 'avante.nvim')
defer.deps('avante', { 'telescope', 'cmp' })
defer.cmd('avante', 'AvanteBuild')
defer.very_lazy('avante')
defer.on_load('avante', function()
	require('avante').setup({
		-- add any opts here
		-- this file can contain specific instructions for your project
		instructions_file = 'avante.md',
		-- for example
		provider = 'claude',
		providers = {
			claude = {
				endpoint = 'https://api.anthropic.com',
				model = 'claude-sonnet-4-20250514',
				timeout = 30000, -- Timeout in milliseconds
				extra_request_body = {
					temperature = 0.75,
					max_tokens = 20480,
				},
			},
		},
	})
end)
