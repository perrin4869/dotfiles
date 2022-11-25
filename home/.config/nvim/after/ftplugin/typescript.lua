vim.keymap.set('n', '<leader>o', require("typescript").actions.organizeImports, { noremap=true, silent=true })
vim.api.nvim_buf_create_user_command(0, 'OR', 'TypescriptOrganizeImport', { nargs = 0 })
