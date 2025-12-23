---@type table<string, function[]>
local loaders = {}
---@type table<string, string> -- Separate table for pack names to avoid mutation errors
local pkgs = {}
---@type table<string, function[]>
local preloaders = {}
---@type table<string, any>
local cache = {}

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

--- Registers a function to run BEFORE packadd or require.
--- Useful for clearing placeholder commands/mappings.
---@param name string The module name target
---@param fn function
function M.on_preload(name, fn)
	if not preloaders[name] then
		preloaders[name] = {}
	end
	table.insert(preloaders[name], fn)
end

---@param name string
---@return any
function M.ensure(name)
	if cache[name] then
		return cache[name]
	end

	-- 1. Pre-load logic
	local pre = preloaders[name]
	if pre then
		for _, fn in ipairs(pre) do
			fn()
		end
		preloaders[name] = nil
	end

	-- 2. Handle package (using separate table lookup)
	local pack = pkgs[name]
	if pack then
		vim.cmd("packadd " .. pack)
		pkgs[name] = nil -- Deleting from a basic table is always fine
	end

	local module = require(name)

	-- 3. Post-load logic
	local config = loaders[name]
	if config then
		for _, fn in ipairs(config) do
			fn(module)
		end
		loaders[name] = nil -- Wipe the whole entry instead of a field
	end

	cache[name] = module
	return module
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
	M.on_preload(module, function()
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

return M
