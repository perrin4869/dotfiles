local M = {}

-- Stores setup functions and package names
local loaders = {}
local preloaders = {}
-- Cache for loaded modules
local cache = {}

--- Defines the initialization logic for a plugin
--- @param name string The module name to require
--- @param fn function The function to run once the module is required
--- @param pack string? Optional: The folder name in 'opt/' to packadd
function M.on_load(name, fn, pack)
	loaders[name] = {
		setup = fn,
		package = pack,
	}
end

function M.on_preload(name, fn)
	preloaders[name] = fn
end

--- Internal: Bootstraps the plugin on demand
local function ensure(name)
	if not cache[name] then
		if preloaders[name] then
			preloaders()
		end

		local config = loaders[name]

		-- Load from opt/ if a package name was provided
		if config and config.package then
			vim.cmd("packadd " .. config.package)
		end

		local module = require(name)

		-- Run setup if it exists
		if config and config.setup then
			config.setup(module)
		end

		cache[name] = module
	end
	return cache[name]
end

--- Curried wrapper for lazy execution
function M.with(name)
	return function(callback)
		return function(...)
			if type(callback) == "function" then
				return callback(ensure(name), ...)
			end
		end
	end
end

function M.call(method)
	return function(module)
		if method then
			return module[method]()
		end
		return module()
	end
end

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

function M.cmd(name, module)
	if vim.fn.exists(":" .. name) ~= 0 then
		error("defer.cmd: '" .. name .. "' already exists")
		return
	end

	M.on_preload(name, function()
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

return M
