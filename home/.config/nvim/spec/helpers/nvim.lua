-- A child Neovim per spec, through yo-dawg: the checkout is the child's home, so it boots the config under test with its
-- plugins, not the machine's. The one flag keeps a throwaway process from writing swap files.
local yd = require('yo-dawg')

local M = {}

local spawn = yd:with_cmd({ vim.v.progpath, '--embed', '--headless', '--cmd', 'set noswapfile' })
local env = vim.tbl_extend('force', vim.fn.environ(), { HOME = vim.fn.getcwd() .. '/home' })

--- @param opts? { width?: integer, height?: integer }
--- @return table<string, function> child
function M.start(opts)
	return spawn.start(vim.tbl_extend('force', { env = env, width = 80, height = 24 }, opts or {}))
end

--- @param child table<string, function>
function M.stop(child)
	yd.stop(child, 2000)
end

return M
