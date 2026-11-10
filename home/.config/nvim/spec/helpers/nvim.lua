-- A child Neovim driven over RPC, named like the harness in Neovim's own functional tests: `exec_lua`, `cmd`,
-- `cmd_capture`, `eval`, `api`, `fn`, `stop`. A spec that needs a process of its own gets one instead of borrowing the
-- runner's, which is what `nvim --embed` plus the job's channel provides.
--
-- `config = true` boots the checkout's own init.lua, and it does not currently work: with `--embed --headless` the
-- child never reaches the point where it answers RPC, and with `--embed` alone the init only runs once a UI attaches.
-- Booting this config therefore needs it to degrade without a UI first — separate work, not a helper option.
local M = {}

local ROOT = vim.fn.getcwd()

---@class Child
---@field exec_lua fun(code: string, ...: any): any
---@field cmd fun(command: string)
---@field cmd_capture fun(command: string): string
---@field eval fun(expression: string): any
---@field api fun(method: string, ...: any): any
---@field fn fun(name: string, ...: any): any
---@field stop fun()

--- @param opts? { config?: boolean, width?: integer, height?: integer }
--- @return Child
function M.start(opts)
	opts = opts or {}
	-- `--embed` already runs without a UI; adding `--headless` to it stops a real config from reaching the point where
	-- it answers RPC, which is why the child never wakes up
	local args = { vim.v.progpath, '--embed', '-i', 'NONE' }
	-- the repository's home, so `~/.vimrc`, `~/.config/nvim` and `stdpath('data')` are the checkout's, not the machine's
	local env = vim.tbl_extend('force', vim.fn.environ(), { HOME = ROOT .. '/home' })
	if opts.config then
		table.insert(args, '-u')
		table.insert(args, ROOT .. '/home/.config/nvim/init.lua')
	else
		table.insert(args, '-u')
		table.insert(args, 'NONE')
		vim.list_extend(args, { '--cmd', 'set rtp^=' .. ROOT .. '/home/.config/nvim' })
	end
	-- a throwaway process should not leave swap or undo files behind
	for _, setting in ipairs({ 'set noswapfile', 'set noundofile' }) do
		vim.list_extend(args, { '--cmd', setting })
	end

	local channel = vim.fn.jobstart(args, { rpc = true, env = env, width = opts.width or 80, height = opts.height or 24 })
	if channel <= 0 then
		error('cannot start ' .. table.concat(args, ' '))
	end

	-- a failure inside the child would otherwise surface as a bare "channel closed"; name the call that failed
	local function request(label, method, sent, ...)
		local ok, result = pcall(vim.rpcrequest, channel, method, ...)
		if not ok then
			error(('%s(%s) failed: %s'):format(label, sent, result), 0)
		end
		return result
	end

	local child = {}
	function child.exec_lua(code, ...)
		return request('exec_lua', 'nvim_exec_lua', code, code, { ... })
	end
	function child.cmd(command)
		request('cmd', 'nvim_exec2', command, command, {})
	end
	function child.cmd_capture(command)
		return request('cmd_capture', 'nvim_exec2', command, command, {}).output
	end
	function child.eval(expression)
		return request('eval', 'nvim_eval', expression, expression)
	end
	function child.api(method, ...)
		return request('api', 'nvim_' .. method, method, method, ...)
	end
	function child.fn(name, ...)
		return request('fn', 'nvim_call_function', name, name, { ... })
	end
	function child.stop()
		-- ask the child to quit so its VimLeave handlers run, and only signal it if that does not happen
		pcall(vim.rpcnotify, channel, 'nvim_cmd', { cmd = 'quitall', bang = true }, {})
		if vim.fn.jobwait({ channel }, 2000)[1] == -1 then
			vim.fn.jobstop(channel)
		end
	end
	return child
end

return M
