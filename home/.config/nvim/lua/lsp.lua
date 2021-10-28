local config = require('lspconfig')
local status = require('lsp-status')
local signature = require('lsp_signature')
local metals = require('metals')

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
  buf_set_keymap('n', 'K', "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  buf_set_keymap('n', '<leader>ca', "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  buf_set_keymap('n', 'gr', "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- buf_set_keymap('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  -- buf_set_keymap('n', '<leader>ws', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  -- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
  buf_set_keymap('n', '<leader>ds', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)
  buf_set_keymap('n', '<leader>ws', [[<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>]], opts)
  -- https://github.com/nvim-telescope/telescope.nvim/issues/964
  -- uses dynamic because most language servers return an empty list on an empty query

  buf_set_keymap('i', '<C-q>', '<cmd>lua require("lsp_signature").toggle_float_win()<CR>', opts)

  if client ~= nil and client.resolved_capabilities.code_lens then
    vim.cmd([[aug lsp_codelens]])
    vim.cmd([[autocmd! * <buffer=]]..tostring(bufnr)..[[>]])
    vim.cmd([[autocmd BufEnter,CursorHold,InsertLeave <buffer=]]..tostring(bufnr)..[[> lua vim.lsp.codelens.refresh()]])
    vim.cmd([[aug END]])
    buf_set_keymap("n", "<leader>cl", "<Cmd>lua vim.lsp.codelens.run()<CR>", opts)
  end

  buf_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>", opts)
  buf_set_keymap("n", "<leader>xw", "<cmd>Trouble lsp_workspace_diagnostics<cr>", opts)
  buf_set_keymap("n", "<leader>xd", "<cmd>Trouble lsp_document_diagnostics<cr>", opts)
  buf_set_keymap("n", "<leader>xl", "<cmd>Trouble loclist<cr>", opts)
  buf_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>", opts)
  buf_set_keymap("n", "gR", "<cmd>Trouble lsp_references<cr>", opts)

  buf_set_keymap("n", "gt", "<cmd>TroubleToggle<cr>", opts)

  -- Set some keybinds conditional on server capabilities
  if client ~= nil and client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client ~= nil and client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end

  if client ~= nil and client.resolved_capabilities.document_highlight then
    vim.cmd([[aug lsp_document_highlight]])
    vim.cmd([[autocmd! * <buffer=]]..tostring(bufnr)..[[>]])
    vim.cmd([[autocmd CursorHold,CursorHoldI <buffer=]]..tostring(bufnr)..[[> lua vim.lsp.buf.document_highlight()]])
    vim.cmd([[autocmd CursorMoved <buffer=]]..tostring(bufnr)..[[> lua vim.lsp.buf.clear_references()]])
    vim.cmd([[aug END]])
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

  status.on_attach(client)
  signature.on_attach({
    floating_window_above_first = true, -- do not hide pum, etc
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    handler_opts = {
      border = "shadow"
    },
  }, bufnr)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)

status.register_progress()

require("trouble").setup {}

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

config.vimls.setup{}
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
    commands = {
      Format = {
        function()
          vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
        end
      }
    }
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
