local yall = require('yall')
yall.pack('codecompanion', 'codecompanion.nvim')
local with = yall.with('codecompanion')

-- HTTP interactions (inline, cmd, background) can't use an ACP agent; keep them on local ollama like avante
local ollama = { name = 'ollama', model = vim.g.codecompanion_ollama_model or 'gemma4:12b' }

yall.setup('codecompanion', {
	adapters = {
		acp = {
			-- no built-in adapter for pi; pi-acp (deps/pi-acp) bridges it until pi speaks ACP natively
			pi = function()
				return {
					name = 'pi',
					formatted_name = 'pi',
					type = 'acp',
					roles = { llm = 'assistant', user = 'user' },
					opts = { vision = true },
					commands = { default = { 'pi-acp' } },
					env = { NODE_NO_WARNINGS = '1' },
					defaults = { mcpServers = {}, timeout = 20000 },
					parameters = {
						protocolVersion = 1,
						clientCapabilities = { fs = { readTextFile = true, writeTextFile = true } },
						clientInfo = { name = 'CodeCompanion.nvim', version = '1.0.0' },
					},
					handlers = {
						lifecycle = {
							setup = function()
								return true
							end,
							-- pi authenticates with its own /login; pi-acp only reports a terminal auth method
							auth = function()
								return true
							end,
						},
						request = {
							build_messages = require('codecompanion.adapters.acp.helpers').build_messages,
						},
					},
				}
			end,
		},
	},
	rules = {
		opts = {
			chat = {
				-- an agent reads its own instruction files; the defaults would also send it Claude Code's ~/.claude/CLAUDE.md
				enabled = function(chat)
					return chat.adapter.type ~= 'acp'
				end,
			},
		},
	},
	interactions = {
		chat = { adapter = 'pi' },
		inline = { adapter = ollama },
		cmd = { adapter = ollama },
		background = { adapter = ollama },
	},
})

for _, cmd in ipairs({ '', 'Chat', 'Actions', 'Cmd', 'CLI', 'CodeReview' }) do
	yall.cmd('CodeCompanion' .. cmd, 'codecompanion')
end

-- <leader>i is avante's; the uppercase pairs with pi's <leader>P and claudecode's <leader>C
local map = require('map').create({ desc = 'codecompanion', desc_separator = ': ' })
local prefix = '<leader>I'

--- @param args string
local function chat(args)
	return with(function()
		vim.cmd('CodeCompanionChat ' .. args)
	end)
end

map('n', prefix .. 'i', chat('Toggle'), 'toggle')
map('n', prefix .. 'n', chat(''), 'new_chat')
map(
	'n',
	prefix .. 'a',
	with(function()
		vim.cmd.CodeCompanionActions()
	end),
	'actions'
)
-- yall's placeholder command drops the range, so load the plugin before the ranged command runs
map(
	'v',
	prefix,
	with(function()
		vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
		vim.cmd("'<,'>CodeCompanionChat Add")
	end),
	'add_selection'
)

require('restore').add_quitpre_ft('codecompanion')
