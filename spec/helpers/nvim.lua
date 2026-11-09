-- A child Neovim driven over RPC. A spec that needs the config as it really runs gets a process of its own instead of
-- borrowing the runner's: `nvim --embed --headless` answers `nvim_*` calls over the job's channel, which is exactly
-- what Neovim's own functional tests and yo-dawg.nvim do, only without the wrapper.
local M = {}

local ROOT = vim.fn.getcwd()

--- @param opts? { config?: boolean, width?: integer, height?: integer }
--- @return table child
function M.start(opts)
	opts = opts or {}
	local args = { vim.v.progpath, '--embed', '--headless' }
	if opts.config then
		table.insert(args, '-u')
		table.insert(args, ROOT .. '/home/.config/nvim/init.lua')
	else
		table.insert(args, '-u')
		table.insert(args, 'NONE')
	end

	-- the repository's config and plugins, so a require resolves the way it does for the user
	for _, setting in ipairs({
		-- no swap files or shada in a throwaway process
		'set noswapfile',
		'set packpath^=' .. ROOT .. '/home/.local/share/nvim/site',
		'set rtp^=' .. ROOT .. '/home/.config/nvim',
	}) do
		vim.list_extend(args, { '--cmd', setting })
	end

	local channel = vim.fn.jobstart(args, { rpc = true, width = opts.width or 80, height = opts.height or 24 })
	if channel <= 0 then
		error('cannot start ' .. table.concat(args, ' '))
	end

	local child = { channel = channel }
	function child.lua(code, ...)
		return vim.rpcrequest(channel, 'nvim_exec_lua', code, { ... })
	end
	function child.lua_get(code)
		return vim.rpcrequest(channel, 'nvim_exec_lua', 'return ' .. code, {})
	end
	function child.cmd(command)
		return vim.rpcrequest(channel, 'nvim_exec2', command, {})
	end
	function child.call(method, ...)
		return vim.rpcrequest(channel, 'nvim_' .. method, ...)
	end
	function child.stop()
		vim.fn.jobstop(channel)
	end
	return child
end

return M
