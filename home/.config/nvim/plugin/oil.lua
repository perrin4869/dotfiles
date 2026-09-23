local yall = require('yall')

yall.setup('oil')
yall.pack('oil', 'oil.nvim')
yall.very_lazy('oil')
-- `-` overlaps with nvim.dir's builtin parent-directory mapping. Our config
-- directory loads before $VIMRUNTIME in 'runtimepath', so this `unique`
-- mapping wins and nvim.dir's own guarded `plugin/dir.lua` mapping (which
-- only sets `-` if unmapped) defers to it. This briefly broke between
-- https://github.com/neovim/neovim/pull/40531 (moved the mapping to
-- defaults.lua, set unconditionally *before* our config loads, so this
-- `unique` mapping started raising E227) and
-- https://github.com/neovim/neovim/pull/40676 (reverted it back).
require('map').map('n', '-', vim.cmd.Oil, 'Open parent directory')
