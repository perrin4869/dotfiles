local formatting_supported = function (client)
  return client.server_capabilities.documentFormattingProvider or
    client.server_capabilities.documentRangeFormattingProvider
end

local M = {}

M.autoformat = function(client, bufnr)
  if
    bufnr ~= nil and
    client ~= nil and
    formatting_supported(client)
  then
    vim.api.nvim_create_augroup("lsp_autoformat",  { clear=false })
    vim.api.nvim_clear_autocmds({ buffer=bufnr, group="lsp_autoformat" })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = "lsp_autoformat",
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ timeout_ms=5000 }) end
    })
  end
end

M.capabilities = require('cmp_nvim_lsp').default_capabilities()
M.formatting_supported = formatting_supported

return M
