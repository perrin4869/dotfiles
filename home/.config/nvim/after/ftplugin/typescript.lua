local c = require "typescript-tools.protocol.constants"
local api = require "typescript-tools.api"

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspAttach_typescript", {}),
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if (client == nil or client.name ~= "typescript-tools") then
      return
    end

    local bufnum = args.buf
    local opts = { noremap=true, silent=true, buffer=bufnum }

    vim.keymap.set('n', '<leader>o', function () api.organize_imports(c.OrganizeImportsMode.All) end, opts)
    vim.api.nvim_buf_create_user_command(bufnum, 'OR', 'TSToolsOrganizeImports', { nargs = 0 })
  end,
})
