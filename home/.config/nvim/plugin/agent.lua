local yall = require('yall')

-- one component of the filetype each surface opens under, which also says whether it is already up, without
-- loading the plugin
local agents = {
	avante = {
		filetype = 'Avante',
		toggle = function()
			require('avante.api').toggle()
		end,
	},
	claudecode = {
		filetype = 'claudecode',
		toggle = function()
			vim.cmd.ClaudeCode()
		end,
	},
	pi = {
		filetype = 'pi_terminal',
		toggle = function()
			require('pi').toggle()
		end,
	},
}

local names = vim.tbl_keys(agents)
table.sort(names)

-- avante's buffers are compound filetypes such as markdown.Avante, so a component is what identifies them
local function visible(agent)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
		if vim.tbl_contains(vim.split(filetype, '.', { plain = true }), agent.filetype) then
			return true
		end
	end
	return false
end

local function toggle(name)
	local agent = agents[name]
	if not agent then
		error(('vim.g.ai_agent is %q, expected one of %s'):format(name, table.concat(names, ', ')))
	end
	yall.with(name)(agent.toggle)()
end

-- \a toggles this one until \A picks another, so the choice lasts a session; vim.g.ai_agent sets it per checkout
local current = vim.g.ai_agent or 'pi'

-- \A opens the agent picked, closing whichever one was up, so two panels never share the screen
local function pick()
	vim.ui.select(names, {
		prompt = 'AI agent',
		format_item = function(name)
			return name == current and name .. ' (current)' or name
		end,
	}, function(choice)
		if not choice then
			return
		end
		for _, name in ipairs(names) do
			if name ~= choice and visible(agents[name]) then
				toggle(name)
			end
		end
		if not visible(agents[choice]) then
			toggle(choice)
		end
		current = choice
	end)
end

local map = require('map').create({ desc = 'agent', desc_separator = ': ' })
map('n', vim.g.toggle_prefix .. 'a', function()
	toggle(current)
end, 'toggle')
map('n', vim.g.toggle_prefix .. 'A', pick, 'pick')
