local lspconfig = require('lspconfig')
local lsp_status = require('lsp-status')
local lsp_signature = require('lsp_signature')
local compe = require('compe')
local saga = require('lspsaga')
local illuminate = require('illuminate')
local metals = require('metals')

lsp_status.register_progress()

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)

compe.setup {
  enabled = true,
  autocomplete = true,
  source = {
    path = true,
    buffer = true,
    calc = true,
    nvim_lsp = true,
    nvim_lua = true,
    vsnip = true,
    emoji = true,
    tmux = true,
  },
}

saga.init_lsp_saga()

require("trouble").setup {}

local autoformat_fts = {"scala"}

function formatting_supported(client)
  return client.resolved_capabilities.document_formatting or
    client.resolved_capabilities.document_range_formatting
end

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  -- lsp saga for vim.lsp.buf.hover()
  buf_set_keymap('n', 'K', "<Cmd>lua require('lspsaga.hover').render_hover_doc()<CR>", opts)
  buf_set_keymap('n', '<C-f>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", opts)
  buf_set_keymap('n', '<C-b>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  -- lsp saga for vim.lsp.buf.rename()
  buf_set_keymap('n', '<leader>rn', "<cmd>lua require('lspsaga.rename').rename()<CR>", opts)
  -- lsp saga for vim.lsp.buf.code_action()
  buf_set_keymap('n', '<leader>ca', "<cmd>lua require('lspsaga.codeaction').code_action()<CR>", opts)
  buf_set_keymap('v', '<leader>ca', "<cmd>lua require('lspsaga.codeaction').range_code_action()<CR>", opts)
  -- vim.lsp.buf.references()
  buf_set_keymap('n', 'gr', "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>", opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  vim.cmd([[autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()]])
  buf_set_keymap("n", "<leader>cl", "<Cmd>lua vim.lsp.codelens.run()<CR>", opts)

  buf_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>", opts)
  buf_set_keymap("n", "<leader>xw", "<cmd>Trouble lsp_workspace_diagnostics<cr>", opts)
  buf_set_keymap("n", "<leader>xd", "<cmd>Trouble lsp_document_diagnostics<cr>", opts)
  buf_set_keymap("n", "<leader>xl", "<cmd>Trouble loclist<cr>", opts)
  buf_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>", opts)
  buf_set_keymap("n", "gR", "<cmd>Trouble lsp_references<cr>", opts)

  buf_set_keymap("n", "gt", "<cmd>TroubleToggle<cr>", opts)
  buf_set_keymap("n", "<leader>d", "<cmd>Trouble lsp_document_diagnostics<cr>", opts)

  -- Set some keybinds conditional on server capabilities
  if client ~= nil and client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client ~= nil and client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end

  -- Format on save
  if
    bufnr ~= nil and
    client ~= nil and
    formatting_supported(client) and
    vim.tbl_contains(autoformat_fts, vim.api.nvim_buf_get_option(bufnr, "filetype"))
  then
    vim.cmd([[aug lsp_autoformat]])
    vim.cmd([[autocmd! * <buffer=]]..tostring(bufnr)..[[>]])
    -- 5000 is the timeout - metals takes a few seconds to format
    vim.cmd([[autocmd BufWritePre <buffer=]]..tostring(bufnr)..[[> lua vim.lsp.buf.formatting_sync(nil, 5000)]])
    vim.cmd([[aug END]])
  end

  illuminate.on_attach(client)
  lsp_status.on_attach(client)
  lsp_signature.on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    handler_opts = {
      border = "single"
    }
  })
end

-- https://github.com/hrsh7th/nvim-compe/issues/302
-- Expand function signature as a snippet
local Helper = require "compe.helper"
Helper.convert_lsp_orig = Helper.convert_lsp
Helper.convert_lsp = function(args)
  local response = args.response or {}
  local items = response.items or response
  for _, item in ipairs(items) do
    -- 2: method
    -- 3: function
    -- 4: constructor
    if item.insertText == nil and (item.kind == 2 or item.kind == 3 or item.kind == 4) then
      item.insertText = item.label .. "(${1})"
      item.insertTextFormat = 2
    end
  end
  return Helper.convert_lsp_orig(args)
end

local M = {}

M.get_status = function()
  if #vim.lsp.buf_get_clients() > 0 then
    return require('lsp-status').status()
  end

  return ''
end

lspconfig.tsserver.setup{on_attach=on_attach}
lspconfig.ccls.setup{on_attach=on_attach}
lspconfig.html.setup{on_attach=on_attach}
lspconfig.cssls.setup{
  on_attach = on_attach,
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

metals_config = metals.bare_config
metals_config.init_options.statusBarProvider = 'on'
metals_config.settings = {
  showImplicitArguments = true,
  showInferredType = true,
  showImplicitConversionsAndClasses = true,
  superMethodLensesEnabled = true,
}
metals_config.on_attach = on_attach

M.initialize_metals = function()
  metals.initialize_or_attach(metals_config)
end

return M
