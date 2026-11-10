-- A child Neovim per spec, through yo-dawg: the checkout is the child's home, so it boots the config under test with its
-- plugins, not the machine's. The one flag keeps a throwaway process from writing swap files.
local yd = require('yo-dawg')

local M = {}

local spawn = yd:with_cmd({ vim.v.progpath, '--embed', '--headless', '--cmd', 'set noswapfile' })
local env = vim.tbl_extend('force', vim.fn.environ(), { HOME = vim.fn.getcwd() .. '/home' })

--- @param opts? { env?: table<string, string>, width?: integer, height?: integer }
--- @return table<string, function> child
function M.start(opts)
	opts = opts or {}
	return spawn.start({
		env = vim.tbl_extend('force', env, opts.env or {}),
		width = opts.width or 80,
		height = opts.height or 24,
	})
end

--- @param child table<string, function>
function M.stop(child)
	yd.stop(child, 2000)
end

return M
