local yall = require('yall')

yall.setup('oil')
yall.pack('oil', 'oil.nvim')
yall.very_lazy('oil')
-- nvim.dir only claims `-` if unmapped (loads after our config), so this wins.
-- Briefly broken by neovim/neovim#40531, reverted by #40676.
require('map').map('n', '-', vim.cmd.Oil, 'Open parent directory')
