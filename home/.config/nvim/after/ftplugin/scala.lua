local metals = require"metals"

local opts = { noremap=true, silent=true }

-- Toggle panel with Tree Views
vim.keymap.set('n', '<leader>tv', metals.toggle_tree_view, opts)
-- Reveal current current class (trait or object) in Tree View 'metalsPackages'
vim.keymap.set('n', '<leader>tf', metals.reveal_in_tree, opts)

vim.keymap.set('n', '<leader>o', metals.organize_imports, opts)
vim.api.nvim_buf_create_user_command(0, 'OR', 'MetalsOrganizeImport', { nargs = 0 })

require("lsp").initialize_metals()
