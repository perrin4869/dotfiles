---@type table<string, function[]>
local loaders = {}
---@type table<string, string> -- Separate table for pack names to avoid mutation errors
local pkgs = {}
---@type table<string, function[]>
local preloaders = {}
---@type table<string, any>
local hooks = {}

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
	if loaders[name] == nil then
		return require(name)
	end
	local config = loaders[name]
	local pre = preloaders[name]

	loaders[name] = nil -- wipe the whole entry instead of a field
	preloaders[name] = nil
	hooks[name] = nil -- in case both hooks and loaders are registered for the same module

	if pre then
		for _, fn in ipairs(pre) do
			fn()
		end
	end

	local pack = pkgs[name]
	if pack then
		vim.cmd("packadd " .. pack)
		pkgs[name] = nil -- Deleting from a basic table is always fine
	end

	local mod = require(name)
	if config then
		for _, fn in ipairs(config) do
			fn(mod)
		end
	end

	return mod
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

function M.hook(modname)
	hooks[modname] = true
end

local function loader(modname)
	if hooks[modname] then
		-- remove from the lazy list so we don't loop
		hooks[modname] = nil

		local mod = ensure(modname)
		-- lua expects a function that returns the module.
		return function()
			return mod
		end
	end

	return nil
end

table.insert(package.loaders, 2, loader)

---@param name string
---@param events string|string[]
---@param opts? { pattern?: string|string[] }
function M.on_event(name, events, opts)
	opts = opts or {}
	local group_id = vim.api.nvim_create_augroup("Defer_Event_" .. name, { clear = true })

	vim.api.nvim_create_autocmd(events, {
		group = group_id,
		pattern = opts.pattern, -- Allows filtering by filetype or file glob
		callback = function()
			ensure(name)
			vim.api.nvim_del_augroup_by_id(group_id)
		end,
	})
end

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
