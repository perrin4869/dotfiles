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

local function check()
	local failures = {}
	for _, module in ipairs(vim.tbl_keys(modules)) do
		-- after the dependencies load and the placeholders are cleared, so only the plugin's own commands are new
		local before
		yall.on_preload(module, function()
			before = user_commands()
		end)
		local ok, err = pcall(yall.ensure, module)
		if not ok then
			table.insert(failures, ('%s: failed to load: %s'):format(module, err))
		else
			local after = user_commands()
			for _, name in ipairs(modules[module]) do
				if not after[name] then
					table.insert(failures, ('%s: stale placeholder %s'):format(module, name))
				elseif deprecated(after[name]) then
					table.insert(failures, ('%s: placeholder for deprecated %s'):format(module, name))
				end
			end
			-- nil when an earlier module already loaded this one as a dependency
			for name, command in pairs(before and after or {}) do
				if not before[name] and not vim.tbl_contains(modules[module], name) and not deprecated(command) then
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
