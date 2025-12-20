local M = {}

-- Stores setup functions and package names
local initializers = {}
-- Cache for loaded modules
local cache = {}

--- Defines the initialization logic for a plugin
--- @param name string The module name to require
--- @param setup_fn function The function to run once the module is required
--- @param package string? Optional: The folder name in 'opt/' to packadd
function M.on_load(name, setup_fn, package)
	initializers[name] = {
		setup = setup_fn,
		package = package,
	}
end

--- Internal: Bootstraps the plugin on demand
local function ensure(name)
	if not cache[name] then
		local config = initializers[name]

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

return M
