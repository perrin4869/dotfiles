---@type table<string, function[]>
local loaders = {}
---@type table<string, string> -- Separate table for pack names to avoid mutation errors
local pkgs = {}
---@type table<string, function[]>
local preloaders = {}
---@type table<string, any>
local cache = {}
---@type table<string, function>
local hooks = {}

local function ensure_pack(name)
	local pack = pkgs[name]
	if pack then
		vim.cmd("packadd " .. pack)
		pkgs[name] = nil -- Deleting from a basic table is always fine
	end
end

--- Registers a function to run BEFORE packadd or require.
--- Useful for clearing placeholder commands/mappings.
---@param name string The module name target
---@param fn function
local function on_preload(name, fn)
	if not preloaders[name] then
		preloaders[name] = {}
	end
	table.insert(preloaders[name], fn)
end

---@param name string
---@return any
local function ensure(name)
	if cache[name] then
		return cache[name]
	end

	local pre = preloaders[name]
	if pre then
		for _, fn in ipairs(pre) do
			fn()
		end
		preloaders[name] = nil
	end

	ensure_pack(name)

	local module = require(name)
	local config = loaders[name]
	if config then
		for _, fn in ipairs(config) do
			fn(module)
		end
		loaders[name] = nil -- wipe the whole entry instead of a field
		hooks[name] = nil -- in case both hooks and loaders are registered for the same module
	end

	cache[name] = module
	return module
end

local M = {}

---@param name string
---@param fn function
---@param pack string?
function M.on_load(name, fn, pack)
	if not loaders[name] then
		loaders[name] = {}
	end
	table.insert(loaders[name], fn)

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
				return callback(ensure(name), ...)
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
		ensure(module)
		local bang = opts.bang and "!" or ""
		local args = (opts.args and opts.args ~= "") and (" " .. opts.args) or ""
		vim.cmd(name .. bang .. args)
	end, {
		nargs = "*",
		range = true,
		bang = true,
		complete = function(_, cmd_line, _)
			ensure(module)
			return vim.fn.getcompletion(cmd_line, "cmdline")
		end,
	})
end

function M.hook(modname, fn, pack)
	hooks[modname] = fn
	if pack then
		pkgs[modname] = pack
	end
end

local function loader(modname)
	for curmod, load in pairs(hooks) do
		if modname == curmod then
			-- remove from the lazy list so we don't loop
			hooks[curmod] = nil
			loaders[curmod] = nil -- in case both a loader and a hook are defined

			ensure_pack(modname)

			local mod = require(modname)
			load(mod)

			-- lua expects a function that returns the module.
			return function()
				return mod
			end
		end
	end

	return nil
end

table.insert(package.loaders, 2, loader)

---@param fn function
function M.very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		once = true, -- Tasks usually only need to run once
		callback = fn,
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
