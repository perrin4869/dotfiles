local typescript = require("typescript")

vim.api.nvim_create_augroup("LspAttach_typescript", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttach_typescript",
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if (client.name ~= "tsserver") then
      return
    end

    local bufnum = args.buf
    local opts = { noremap=true, silent=true, buffer=bufnum }

    vim.keymap.set('n', '<leader>o', typescript.actions.organizeImports, opts)
    vim.api.nvim_buf_create_user_command(bufnum, 'OR', 'TypescriptOrganizeImport', { nargs = 0 })
  end,
})
