require'hop'.setup()

local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<leader>s', "<cmd>lua require'hop'.hint_char1()<cr>", opts)
vim.api.nvim_set_keymap('n', '<leader>S', "<cmd>lua require'hop'.hint_char2()<cr>", opts)
