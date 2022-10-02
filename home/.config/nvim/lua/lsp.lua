local config = require('lspconfig')
local status = require('lsp-status')
local metals = require('metals')

local autoformat_fts = {"scala"}

local formatting_supported = function (client)
  return client.server_capabilities.documentFormattingProvider or
    client.server_capabilities.documentRangeFormattingProvider
end

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { silent=true, buffer=bufnr }
  local function get_opts(right)
    local merged = {}
    for k,v in pairs(opts) do merged[k] = v end
    for k,v in pairs(right) do merged[k] = v end
    return merged
  end

  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    get_opts({ desc="lsp.list_workspace_folders" }))
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

  -- buf_set_keymap('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  -- buf_set_keymap('n', '<leader>ws', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  -- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
  vim.keymap.set('n', '<leader>ds', require('telescope.builtin').lsp_document_symbols, opts)
  vim.keymap.set('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, opts)
  -- https://github.com/nvim-telescope/telescope.nvim/issues/964
  -- uses dynamic because most language servers return an empty list on an empty query

  if client ~= nil and client.server_capabilities.codeLensProvider then
    vim.api.nvim_create_augroup("lsp_codelens",  { clear = false })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_codelens" })
    vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
      group = "lsp_codelens",
      buffer = bufnr,
      callback = vim.lsp.codelens.refresh
    })

    vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
  end

  vim.keymap.set("n", "<leader>xx", require'trouble'.open, get_opts({ desc="trouble.open" }))
  vim.keymap.set("n", "<leader>xw", function() require'trouble'.open('workspace_diagnostics') end,
    get_opts({ desc="trouble.workspace_diagnostics" }))
  vim.keymap.set("n", "<leader>xd", function() require'trouble'.open('document_diagnostics') end,
    get_opts({ desc="trouble.document_diagnostics" }))
  vim.keymap.set("n", "<leader>xl", function() require'trouble'.open('loclist') end,
    get_opts({ desc="trouble.loclist" }))
  vim.keymap.set("n", "<leader>xq", function() require'trouble'.open('quickfix') end,
    get_opts({ desc="trouble.quickfix" }))
  vim.keymap.set("n", "gR", function() require'trouble'.open('lsp_references') end,
    get_opts({ desc="trouble.lsp_references" }))

  vim.keymap.set("n", "gt", require'trouble'.toggle, get_opts({ desc="trouble.toggle" }))

  -- Set some keybinds conditional on server capabilities
  if client ~= nil and client.server_capabilities.documentFormattingProvider then
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.formatting, get_opts({ desc="lsp.formatting" }))
  elseif client ~= nil and client.server_capabilities.documentRangeFormattingProvider then
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.formatting, get_opts({ desc="lsp.formatting" }))
  end

  if client ~= nil and client.server_capabilities.documentHighlightProvider then
    vim.api.nvim_create_augroup("lsp_document_highlight",  { clear = false })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_document_highlight" })
    vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
      group = "lsp_document_highlight",
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = "lsp_document_highlight",
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references
    })
  end

  -- Format on save
  if
    bufnr ~= nil and
    client ~= nil and
    formatting_supported(client) and
    vim.tbl_contains(autoformat_fts, vim.api.nvim_buf_get_option(bufnr, "filetype"))
  then
    vim.api.nvim_create_augroup("lsp_autoformat",  { clear = false })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_autoformat" })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = "lsp_autoformat",
      buffer = bufnr,
      callback = function() vim.lsp.buf.formatting_sync(nil, 5000) end
    })
  end

  status.on_attach(client)
end

-- luacheck: push ignore 122
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)
-- luacheck: pop

status.register_progress()

require("trouble").setup {}

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

config.vimls.setup{on_attach=on_attach, capabilities=capabilities}
config.tsserver.setup{on_attach=on_attach, capabilities=capabilities}
config.ccls.setup{on_attach=on_attach, capabilities=capabilities}
config.html.setup{on_attach=on_attach, capabilities=capabilities}
config.cssls.setup{
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    css = {
      validate = false
    },
    less = {
      validate = true
    },
    scss = {
      validate = true
    }
  }
}
config.jsonls.setup {
  on_attach=on_attach,
  capabilities=capabilities,
  commands = {
    Format = {
      function()
        vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
      end
    }
  },
}
config.sqlls.setup{
  on_attach=on_attach,
  capabilities=capabilities,
  cmd={"sql-language-server", "up", "--method", "stdio"}
}

local metals_config = metals.bare_config()
metals_config.init_options.statusBarProvider = 'on'
metals_config.settings = {
  showImplicitArguments = true,
  showInferredType = true,
  showImplicitConversionsAndClasses = true,
  superMethodLensesEnabled = true,
}
metals_config.on_attach = function(client, bufnr)
  on_attach(client, bufnr)
  metals.setup_dap()
end
metals_config.capabilities = capabilities

local M = {}

M.get_status = function()
  if #vim.lsp.buf_get_clients() > 0 then
    return status.status()
  end

  return ''
end

M.initialize_metals = function()
  metals.initialize_or_attach(metals_config)
end

return M
