-- Load every module with yall.cmd placeholders and compare them with the commands it defines:
-- a placeholder the plugin no longer defines, or only as a deprecated alias, is stale, and a
-- plugin command sharing the placeholders' name prefix without one of its own won't lazy-load.
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

local function common_prefix(names)
	local prefix = names[1]
	for _, name in ipairs(names) do
		while not vim.startswith(name, prefix) do
			prefix = prefix:sub(1, -2)
		end
	end
	return prefix
end

local function check()
	local failures = {}
	for _, module in ipairs(vim.tbl_keys(modules)) do
		local stubs = modules[module]
		local before = user_commands()
		local ok, err = pcall(yall.ensure, module)
		if not ok then
			table.insert(failures, ('%s: failed to load: %s'):format(module, err))
		else
			local after = user_commands()
			local stubbed = {}
			for _, name in ipairs(stubs) do
				stubbed[name] = true
				if not after[name] then
					table.insert(failures, ('%s: stale placeholder %s'):format(module, name))
				elseif deprecated(after[name]) then
					table.insert(failures, ('%s: placeholder for deprecated %s'):format(module, name))
				end
			end
			local prefix = common_prefix(stubs)
			for name in pairs(after) do
				local defined_by_load = not before[name] or stubbed[name]
				if defined_by_load and not stubbed[name] and vim.startswith(name, prefix) and not deprecated(after[name]) then
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
