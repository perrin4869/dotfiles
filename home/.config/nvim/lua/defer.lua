---@class Defer.Entry
---@field pack string|nil The name of the package for packadd
---@field post function|nil Function to run after loading (setup)
---@field load function|nil Function to run to load (setup)
---@field pre function|nil Function to run before loading
---@field after boolean If set, will load the after directory after packadd
---@field deps string[] List of module names this entry depends on
---@field disabled boolean Whether the module is prevented from loading
---@field loaded boolean Internal state to track if ensure has already run

---@type table<string, Defer.Entry>
local registry = {}
---@type table<string, string>
local hooks = {}

---@param name string
---@return Defer.Entry
local function entry(name)
	if not registry[name] then
		registry[name] = {
			pack = nil,
			post = nil,
			load = nil,
			pre = nil,
			after = false,
			deps = {},
			disabled = false,
			loaded = false,
		}
	end
	return registry[name]
end
---@param f1 function
---@param f2 function
local function zip(f1, f2)
	return function(...)
		f1(...)
		f2(...)
	end
end

-- https://github.com/lumen-oss/lz.n/wiki/lazy‐loading-nvim‐cmp-and-its-extensions
local function trigger_load_with_after(plugin_name)
	local res, rtp = pcall(require, "rtp_nvim")
	if not res then
		return
	end
	for _, dir in ipairs(vim.opt.packpath:get()) do
		local glob = vim.fs.joinpath("pack", "*", "opt", plugin_name)
		local plugin_dirs = vim.fn.globpath(dir, glob, nil, true, true)
		if not vim.tbl_isempty(plugin_dirs) then
			rtp.source_after_plugin_dir(plugin_dirs[1])
			return
		end
	end
end

--- Registers a function to run BEFORE packadd or require.
--- Useful for clearing placeholder commands/mappings.
---@param name string The module name target
---@param fn function
local function on_preload(name, fn)
	local mod = entry(name)
	if mod.pre then
		mod.pre = zip(mod.pre, fn)
	else
		mod.pre = fn
	end
end

local M = {}

---@param name string
---@param fn function
function M.on_load(name, fn)
	local mod = entry(name)
	if mod.load then
		mod.load = zip(mod.load, fn)
	else
		mod.load = fn
	end
end

---@param name string
---@param fn function
function M.on_postload(name, fn)
	local mod = entry(name)
	if mod.loaded then
		fn()
	elseif mod.post then
		mod.post = zip(mod.post, fn)
	else
		mod.post = fn
	end
end

---@param name string
function M.after(name)
	local mod = entry(name)
	mod.after = true
end

---@param name string
function M.disable(name)
	local mod = entry(name)
	mod.disabled = true
end

---@param name string
---@return any
function M.ensure(name)
	local mod = registry[name]
	if not mod or mod.disabled then
		return false
	end

	if mod.loaded then
		return true
	end

	mod.loaded = true

	-- if some of the deps fails to load, abort
	for _, dep in ipairs(mod.deps) do
		if not M.ensure(dep) then
			mod.disabled = true
			return false
		end
	end

	if mod.pre then
		mod.pre()
	end
	if mod.pack then
		vim.cmd.packadd(mod.pack)
		if mod.after then
			trigger_load_with_after(mod.pack)
		end
	end

	if mod.load then
		mod.load()
	end

	if mod.post then
		mod.post()
	end

	return true
end

---@param name string
---@return any
function M.require(name)
	if M.ensure(name) then
		return require(name)
	end
	return false
end

function M.pack(name, pack)
	local mod = entry(name)
	if not pack then
		pack = name
	end

	mod.pack = pack
end

--- Registers dependencies for a module.
---@param name string
---@param deps string|string[]
function M.deps(name, deps)
	local mod = entry(name)
	if type(deps) == "string" then
		table.insert(mod.deps, deps)
	else
		for _, d in ipairs(deps) do
			table.insert(mod.deps, d)
		end
	end
end

--- Wraps a module for lazy execution via a callback.
---@param name string
---@return fun(callback: fun(m: any, ...): any): fun(...): any
function M.with(name)
	return function(callback)
		return function(...)
			if type(callback) == "function" and M.ensure(name) then
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
	return function(mod)
		if method then
			return mod[method](unpack(args, 1, nargs))
		end
		return mod(unpack(args, 1, nargs))
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
		for hook_mod, target_mod in pairs(hooks) do
			local escaped = hook_mod:gsub("%-", "%%-")
			if modname:match("^" .. escaped .. "%.") then
				-- only match prefix if a package exists for this loader
				-- this way, if a plugin/ script was loaded and requires a lua
				-- module in the plugin, it won't trigger the load
				local mod = registry[target_mod]
				if mod and mod.pack then
					match_key = hook_mod
					loader_key = target_mod
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
			M.ensure(name)
			vim.api.nvim_del_augroup_by_id(group_id)
		end,
	})
end

local on_insert_cb = nil
---@param name string|function
function M.on_insert(name)
	local fn
	if type(name) == "function" then
		fn = name
	else
		fn = function()
			M.ensure(name)
		end
	end

	if on_insert_cb then
		on_insert_cb = zip(on_insert_cb, fn)
		return
	end

	on_insert_cb = fn
	local group_id = vim.api.nvim_create_augroup("Defer_Event_InsertEnter", { clear = true })

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group_id,
		once = true,
		callback = function()
			on_insert_cb()
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
