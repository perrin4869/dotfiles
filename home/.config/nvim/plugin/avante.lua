local yall = require('yall')
local provider = vim.g.avante_provider
yall.pack('avante', 'avante.nvim')
local deps = { 'telescope', 'cmp' }
if provider == 'copilot' then
	table.insert(deps, 'copilot')
end
yall.deps('avante', deps)
local with = yall.with('avante')
local config = {
	-- add any opts here
	-- this file can contain specific instructions for your project
	instructions_file = 'avante.md',
	behaviour = {
		-- https://github.com/yetone/avante.nvim/issues/1048
		auto_suggestions = provider ~= 'copilot',
		auto_set_keymaps = false,
	},
	input = {
		provider = 'snacks',
	},
	-- for example
	provider = provider or 'ollama',
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
		copilot = {
			model = vim.g.avante_copilot_model or 'claude-sonnet-4.6',
		},
		ollama = {
			-- model = 'qwen3:8b',
			model = vim.g.avante_ollama_model or 'gemma4:12b',
			is_env_set = with(function()
				return require('avante.providers.ollama').check_endpoint_alive()
			end),
		},
		claude = {
			endpoint = 'https://api.anthropic.com',
			model = vim.g.avante_claude_model or 'claude-sonnet-5',
			timeout = 30000, -- Timeout in milliseconds
			extra_request_body = {
				temperature = 0.75,
				max_tokens = 20480,
			},
		},
		-- https://github.com/deepseek-ai/awesome-deepseek-integration/blob/main/docs/avante.nvim/README.md
		deepseek = {
			__inherited_from = 'openai',
			api_key_name = os.getenv('DEEPSEEK_API_KEY'),
			endpoint = 'https://api.deepseek.com',
			model = vim.g.avante_deepseek_model or 'deepseek-coder',
			max_tokens = 8192,
		},
	},
}
if vim.g.avante_claude_auth_type then
	-- default is 'api' and requires an api key, for 'pro', 'max' or 'teams' accounts use 'max' auth type
	config.providers.claude.auth_type = vim.g.avante_claude_auth_type
end
yall.setup('avante', config)

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
	prefix .. 'f',
	with(function()
		require('avante.api').add_selected_file(vim.api.nvim_buf_get_name(0))
	end),
	'add_current_file'
)
map(
	prefix .. 'b',
	with(function()
		require('avante.api').add_buffer_files()
	end),
	'add_buffer_files'
)

map(
	vim.g.toggle_prefix .. 'a',
	with(function()
		require('avante.api').toggle()
	end),
	'toggle'
)

map(
	prefix .. 'd',
	with(function()
		require('avante').toggle.debug()
	end),
	'toggle.debug'
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
