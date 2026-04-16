local yall = require('yall')
local provider = vim.g.avante_provider
yall.pack('dressing', 'dressing.nvim')
yall.pack('avante', 'avante.nvim')
yall.on_load('avante', function()
	require('avante').setup({
		-- add any opts here
		-- this file can contain specific instructions for your project
		instructions_file = 'avante.md',
		behaviour = {
			-- https://github.com/yetone/avante.nvim/issues/1048
			auto_suggestions = provider ~= 'copilot',
			auto_set_keymaps = false,
		},
		input = {
			provider = 'dressing',
		},
		-- for example
		provider = vim.g.avante_provider or 'ollama',
		acp_providers = {
			['gemini-cli'] = {
				command = 'npx',
				args = { '@google/gemini-cli', '--experimental-acp' },
				env = {
					NODE_NO_WARNINGS = '1',
					GEMINI_API_KEY = os.getenv('GEMINI_API_KEY'),
				},
			},
		},
		providers = {
			ollama = {
				model = 'qwen3:8b',
				is_env_set = require('avante.providers.ollama').check_endpoint_alive,
			},
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
local deps = { 'telescope', 'cmp', 'dressing' }
if provider == 'copilot' then
	table.insert(deps, 'copilot')
end
yall.deps('avante', deps)
local with = yall.with('avante')

local map = require('map').create({ desc = 'avante', desc_separator = ': ', mode = 'n' })
local prefix = '<leader>i'
map(
	prefix .. 'i',
	with(function()
		require('avante.api').focus()
	end),
	'focus'
)
map(
	prefix .. 'a',
	with(function()
		require('avante.api').ask()
	end),
	'ask'
)
map(
	prefix .. 'A',
	with(function()
		require('avante.api').ask({ new_chat = true })
	end),
	'create new ask'
)

map(
	vim.g.toggle_prefix .. 'a',
	with(function()
		require('avante.api').toggle()
	end),
	'toggle'
)

vim
	.iter({
		'Ask',
		'Build',
		'Chat',
		'ChatNew',
		'Clear',
		'Edit',
		'Stop',
		'Focus',
		'History',
		'Models',
		'Refresh',
		'ShowRepoMap',
		'SwitchProvider',
		'SwitchInputProvider',
		'SwitchSelectorProvider',
		'Toggle',
	})
	:each(function(cmd)
		yall.cmd('Avante' .. cmd, 'avante')
	end)

require('restore').add_quitpre_ft('Avante')
require('restore').add_quitpre_ft('AvanteInput')
require('restore').add_quitpre_ft('AvanteSelectedFiles')
require('restore').add_quitpre_ft('AvanteTodos')
