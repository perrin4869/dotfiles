local metals = require"metals"

vim.api.nvim_create_augroup("LspAttach_metals", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttach_metals",
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if (client.name ~= "metals") then
      return
    end

    local bufnum = args.buf
    local opts = { noremap=true, silent=true, buffer=bufnum }

    -- Toggle panel with Tree Views
    vim.keymap.set('n', '<leader>tv', metals.toggle_tree_view, opts)
    -- Reveal current current class (trait or object) in Tree View 'metalsPackages'
    vim.keymap.set('n', '<leader>tf', metals.reveal_in_tree, opts)

    vim.keymap.set('n', '<leader>o', metals.organize_imports, opts)
    vim.api.nvim_buf_create_user_command(bufnum, 'OR', 'MetalsOrganizeImport', { nargs = 0 })
  end,
})

require("lsp").initialize_metals()
