local yall = require('yall')
local provider = vim.g.avante_provider
yall.pack('avante', 'avante.nvim')
local deps = { 'telescope', 'cmp', 'nui', 'mega.cmdparse' }
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
	-- submit always focuses the result window, so the real keys are mapped below to refocus the input
	mappings = {
		submit = {
			normal = '<Plug>(avante-submit)',
			insert = '<Plug>(avante-submit)',
		},
	},
	-- the builtin /resume only lists avante's histories, even when the agent keeps its own sessions
	slash_commands = {
		{
			name = 'resume',
			description = 'Resume a previous session',
			details = "Resume a previous session; lists the agent's sessions for ACP providers",
			callback = function()
				local avante_config = require('avante.config')
				if avante_config.acp_providers[avante_config.provider] then
					require('avante.api').select_acp_session()
				else
					require('avante.api').select_history()
				end
			end,
		},
	},
	-- native picks via vim.ui.select, then asks open/delete/cancel through vim.ui.input
	selector = {
		provider = 'telescope',
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
		pi = {
			command = 'pi-acp',
			env = {
				NODE_NO_WARNINGS = '1',
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

for _, cmd in ipairs({
	'',
	'Ask',
	'Build',
	'Chat',
	'ChatNew',
	'Clear',
	'Edit',
	'Stop',
	'Focus',
	'Models',
	'Refresh',
	'ShowRepoMap',
	'SwitchProvider',
	'SwitchInputProvider',
	'SwitchSelectorProvider',
}) do
	yall.cmd('Avante' .. cmd, 'avante')
end

-- same as <C-q> in the claude terminal: leave the sidebar for the code window it was opened from
local sidebar_map = require('map').create({ desc = 'avante', desc_separator = ': ', mode = { 'n', 'i' } })
vim.api.nvim_create_autocmd('FileType', {
	group = vim.api.nvim_create_augroup('avante_mappings', { clear = true }),
	pattern = { 'Avante', 'AvanteInput', 'AvanteSelectedFiles', 'AvanteTodos' },
	callback = function(args)
		sidebar_map('<C-q>', function()
			vim.cmd.stopinsert()
			local sidebar = require('avante').get()
			if sidebar and vim.api.nvim_win_is_valid(sidebar.code.winid) then
				vim.api.nvim_set_current_win(sidebar.code.winid)
			else
				vim.cmd.wincmd('p')
			end
		end, { buffer = args.buf, desc = 'unfocus' })

		if vim.bo[args.buf].filetype ~= 'AvanteInput' then
			return
		end
		local function submit()
			local sidebar = require('avante').get()
			if not sidebar then
				return
			end
			local input_winid = sidebar.containers.input.winid
			sidebar:submit_input()
			if input_winid and vim.api.nvim_win_is_valid(input_winid) then
				vim.api.nvim_set_current_win(input_winid)
			end
		end
		map('<CR>', submit, { buffer = args.buf, desc = 'submit' })
		require('map').map('i', '<C-s>', submit, { buffer = args.buf, unique = false, desc = 'avante: submit' })
	end,
})

-- entering the sidebar from a code window (e.g. <C-w>l) lands on the result pane; go to the prompt instead
vim.api.nvim_create_autocmd('WinEnter', {
	group = vim.api.nvim_create_augroup('avante_focus_input', { clear = true }),
	callback = function()
		if vim.bo.filetype ~= 'Avante' then
			return
		end
		local sidebar = require('avante').get()
		if not sidebar or sidebar:is_sidebar_winid(vim.fn.win_getid(vim.fn.winnr('#'))) then
			return
		end
		vim.schedule(function()
			sidebar:focus_input()
		end)
	end,
})

require('restore').add_quitpre_ft('Avante')
require('restore').add_quitpre_ft('AvanteInput')
require('restore').add_quitpre_ft('AvanteSelectedFiles')
require('restore').add_quitpre_ft('AvanteTodos')
