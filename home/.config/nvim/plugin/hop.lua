require'hop'.setup()

local opts = { silent=true }
vim.keymap.set('n', '<leader>s', require'hop'.hint_char1, opts)
vim.keymap.set('n', '<leader>S', require'hop'.hint_char2, opts)
