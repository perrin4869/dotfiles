-- require'hop'.setup()

local opts = { silent=true }
vim.keymap.set({ 'n', 'x', 'o', 'v' }, '<leader>s', "<Plug>(leap-forward-to)", opts)
vim.keymap.set({ 'n', 'x', 'o', 'v' }, '<leader>S', "<Plug>(leap-backward-to)", opts)
vim.keymap.set('v', '<leader>x', "<Plug>(leap-forward-till)", opts)
vim.keymap.set('v', '<leader>X', "<Plug>(leap-backward-till)", opts)
