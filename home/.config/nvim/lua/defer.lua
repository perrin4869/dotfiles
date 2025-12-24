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
		vim.cmd("packadd " .. pack)
		pkgs[name] = nil -- Deleting from a basic table is always fine
	end

	local mod = require(name)
	if loader then
		loader(mod)
	end

	return mod
end

---@param name string
---@param fn function|string?
---@param pack string?
function M.on_load(name, fn, pack)
	if type(fn) == "string" then
		pack = fn
		fn = nil
	end
	if fn then
		if loaders[name] then
			loaders[name] = zip(loaders[name], fn)
		else
			loaders[name] = fn
		end
	end

	if pack then
		pkgs[name] = pack
	end
end

--- Wraps a module for lazy execution via a callback.
---@param name string
---@return fun(callback: fun(m: any, ...): any): fun(...): any
function M.with(name)
	return function(callback)
		return function(...)
			if type(callback) == "function" then
				return callback(M.ensure(name), ...)
			end
		end
	end
end

--- Calls a method from a parameter.
---@param method string
---@return fun(callback: fun(m: any): any): fun(...): any
function M.call(method)
	return function(module)
		if method then
			return module[method]()
		end
		return module()
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
	if hooks[modname] == nil then
		return nil
	end

	local loader = hooks[modname]
	-- remove from the lazy list so we don't loop
	hooks[modname] = nil

	if loaders[loader] == nil then
		return nil
	end

	M.ensure(loader)
	local mod = require(modname)
	-- lua expects a function that returns the module.
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
