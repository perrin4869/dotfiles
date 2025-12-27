---@type table<string, function>
local loaders = {}
---@type table<string, string> -- Separate table for pack names to avoid mutation errors
local pkgs = {}
---@type table<string, function>
local preloaders = {}
---@type table<string, string>
local hooks = {}

---@param f1 function
---@param f2 function
local function zip(f1, f2)
	return function(...)
		f1(...)
		f2(...)
	end
end

--- Registers a function to run BEFORE packadd or require.
--- Useful for clearing placeholder commands/mappings.
---@param name string The module name target
---@param fn function
local function on_preload(name, fn)
	if preloaders[name] then
		preloaders[name] = zip(preloaders[name], fn)
	else
		preloaders[name] = fn
	end
end

local M = {}

---@param name string
---@return any
function M.ensure(name)
	local loader = loaders[name]
	local preloader = preloaders[name]

	loaders[name] = nil -- wipe the whole entry instead of a field
	preloaders[name] = nil

	if preloader then
		preloader()
	end

	local pack = pkgs[name]
	if pack then
		vim.cmd.packadd(pack)
		pkgs[name] = nil -- Deleting from a basic table is always fine
	end

	if loader then
		loader()
	end
end

---@param name string
---@return any
function M.require(name)
	M.ensure(name)
	return require(name)
end

---@param name string
---@param fn function
function M.on_load(name, fn)
	if fn then
		if loaders[name] then
			loaders[name] = zip(loaders[name], fn)
		else
			loaders[name] = fn
		end
	end
end

function M.pack(name, pack)
	if not pack then
		pack = name
	end

	pkgs[name] = pack
end

--- Wraps a module for lazy execution via a callback.
---@param name string
---@return fun(callback: fun(m: any, ...): any): fun(...): any
function M.with(name)
	return function(callback)
		return function(...)
			if type(callback) == "function" then
				return callback(M.require(name), ...)
			end
		end
	end
end

--- Calls a method from a parameter.
---@param method string
---@return fun(callback: fun(m: any): any): fun(...): any
function M.call(method, ...)
	local args = { ... }
	local nargs = select("#", ...) -- Get the count to handle nil correctly
	return function(module)
		if method then
			return module[method](table.unpack(args, 1, nargs))
		end
		return module(table.unpack(args, 1, nargs))
	end
end

--- Memoizes a function result.
---@generic T
---@param fn fun(...): T
---@return fun(...): T
function M.lazy(fn)
	local value
	local ran = false
	return function(...)
		if not ran then
			value = fn(...)
			ran = true
		end
		return value
	end
end

--- Creates a lazy command trigger.
---@param name string The command name
---@param module string The module to load
function M.cmd(name, module)
	if vim.fn.exists(":" .. name) ~= 0 then
		error("defer.cmd: '" .. name .. "' already exists")
	end

	-- Clean up the placeholder BEFORE the plugin defines its own
	on_preload(module, function()
		pcall(vim.api.nvim_del_user_command, name)
	end)

	vim.api.nvim_create_user_command(name, function(opts)
		M.ensure(module)
		local bang = opts.bang and "!" or ""
		local args = (opts.args and opts.args ~= "") and (" " .. opts.args) or ""
		vim.cmd(name .. bang .. args)
	end, {
		nargs = "*",
		range = true,
		bang = true,
		complete = function(_, cmd_line, _)
			M.ensure(module)
			return vim.fn.getcompletion(cmd_line, "cmdline")
		end,
	})
end

--- Creates a lazy command trigger.
---@param modname string The command name
---@param loader string? The module to load
function M.hook(modname, loader)
	hooks[modname] = loader or modname
end

local function hook(modname)
	local match_key = nil
	local loader_key = nil

	if hooks[modname] then
		match_key = modname
		loader_key = hooks[modname]
	else
		-- prefix match
		for hook_mod, target_id in pairs(hooks) do
			local escaped = hook_mod:gsub("%-", "%%-")
			if modname:match("^" .. escaped .. "%.") then
				-- only match prefix if a package exists for this loader
				-- this way, if a plugin/ script was loaded and requires a lua
				-- module in the plugin, it won't trigger the load
				if pkgs[target_id] ~= nil then
					match_key = hook_mod
					loader_key = target_id
					break
				end
			end
		end
	end

	-- no match found, or prefix match didn't meet the 'pkgs' requirement
	if not match_key then
		return nil
	end

	hooks[match_key] = nil

	---@cast loader_key string
	M.ensure(loader_key)

	-- now that the RTP is updated and pre-configs run, require the actual module
	local mod = require(modname)

	return function()
		return mod
	end
end

table.insert(package.loaders, 2, hook)

---@param name string|function
---@param events string|string[]
---@param opts? { pattern?: string|string[], name?: string }
function M.on_event(name, events, opts)
	opts = opts or {}
	local fn
	if type(name) == "function" then
		fn = name
		name = opts.name
	else
		fn = function()
			M.ensure(name)
		end
	end
	local group_id = vim.api.nvim_create_augroup("Defer_Event_" .. name, { clear = true })

	vim.api.nvim_create_autocmd(events, {
		group = group_id,
		pattern = opts.pattern, -- Allows filtering by filetype or file glob
		callback = function()
			fn()
			vim.api.nvim_del_augroup_by_id(group_id)
		end,
	})
end

---@param loader string|function
function M.very_lazy(loader)
	local callback = loader
	if type(loader) == "string" then
		callback = function()
			M.ensure(loader)
		end
	end
	if vim.v.vim_did_enter == 1 then
		callback()
		return
	end

	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		once = true, -- Tasks usually only need to run once
		callback = callback,
	})
end

-- In defer.lua's initialization:
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
		end)
	end,
})

return M
