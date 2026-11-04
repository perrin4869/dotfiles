-- Load every module with yall.cmd placeholders and compare them with the commands it defines:
-- a placeholder the plugin no longer defines, or only as a deprecated alias, is stale, and a
-- command the plugin defines without a placeholder won't lazy-load.
-- Run with --cmd, before the config, so it can record the placeholders as they are created.
local yall = require('yall')

---@type table<string, string[]>
local modules = {}
local create = yall.cmd
yall.cmd = function(name, module)
	modules[module] = modules[module] or {}
	table.insert(modules[module], name)
	return create(name, module)
end

local function user_commands()
	return vim.api.nvim_get_commands({ builtin = false })
end

-- plugins keep renamed commands as aliases that say so in their description
local function deprecated(command)
	return command.definition:lower():find('deprecated', 1, true) ~= nil
end

-- the plugin directory whose file defined a command, so a dependency's commands aren't counted
local function plugin_dir(name)
	local output = vim.api.nvim_exec2('verbose command ' .. name, { output = true }).output
	local file = output:match('Last set from (.-) line %d+') or output:match('Last set from (%S+)')
	return file and vim.fs.normalize(file):match('^(.-/pack/[^/]+/[^/]+/[^/]+)/')
end

-- commands created from Lua only record their file while 'verbose' is set
local function load_module(module)
	vim.o.verbosefile = '/dev/null'
	vim.o.verbose = 1
	local ok, err = pcall(yall.ensure, module)
	vim.o.verbose = 0
	vim.o.verbosefile = ''
	return ok, err
end

local function check()
	local failures = {}
	for _, module in ipairs(vim.tbl_keys(modules)) do
		local stubs = modules[module]
		local before = user_commands()
		local ok, err = load_module(module)
		if not ok then
			table.insert(failures, ('%s: failed to load: %s'):format(module, err))
		else
			local after = user_commands()
			local dirs = {}
			for _, name in ipairs(stubs) do
				if not after[name] then
					table.insert(failures, ('%s: stale placeholder %s'):format(module, name))
				else
					if deprecated(after[name]) then
						table.insert(failures, ('%s: placeholder for deprecated %s'):format(module, name))
					end
					local dir = plugin_dir(name)
					if dir then
						dirs[dir] = true
					end
				end
			end
			for name, command in pairs(after) do
				if not before[name] and not deprecated(command) and dirs[plugin_dir(name) or ''] then
					table.insert(failures, ('%s: %s has no placeholder'):format(module, name))
				end
			end
		end
	end

	table.sort(failures)
	for _, failure in ipairs(failures) do
		io.stderr:write(failure .. '\n')
	end
	vim.cmd(#failures == 0 and 'qa!' or 'cquit!')
end

vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = check })
