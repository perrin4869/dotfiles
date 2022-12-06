local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- This is nicer than having virtual text
-- https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function() vim.diagnostic.open_float({focusable = false}) end
})
