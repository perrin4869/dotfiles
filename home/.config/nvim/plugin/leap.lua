local utils = require'utils'

local opts = { silent=true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set({ 'n', 'x', 'o', 'v' }, '<leader>s', function ()
  local current_window = vim.fn.win_getid()
  require('leap').leap { target_windows = { current_window } }
end, get_opts({ desc = "leap" }))
-- vim.keymap.set({ 'n', 'x', 'o', 'v' }, '<leader>s', "<Plug>(leap-forward-to)", opts)
-- vim.keymap.set({ 'n', 'x', 'o', 'v' }, '<leader>S', "<Plug>(leap-backward-to)", opts)
vim.keymap.set('v', '<leader>x', "<Plug>(leap-forward-till)", opts)
vim.keymap.set('v', '<leader>X', "<Plug>(leap-backward-till)", opts)
