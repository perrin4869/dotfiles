local config = require'lspconfig'
local typescript = require'typescript'
local lsp = require'lsp'
local utils = require'utils'

vim.api.nvim_create_augroup("LspAttach_general", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttach_general",
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf=bufnr })

    -- Mappings.
    local opts = { silent=true, buffer=bufnr }
    local get_opts = utils.create_get_opts(opts)

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
    -- buf_set_keymap('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
    -- buf_set_keymap('n', '<leader>ws', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
    -- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
    vim.keymap.set('n', '<leader>ds', require('telescope.builtin').lsp_document_symbols,
      get_opts({ desc="telescope.lsp_document_symbols" }))
    vim.keymap.set('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols,
      get_opts({ desc="telescope.lsp_dynamic_workspace_symbols" }))
    -- https://github.com/nvim-telescope/telescope.nvim/issues/964
    -- uses dynamic because most language servers return an empty list on an empty query

    vim.lsp.buf.inlay_hint(bufnr, true)
    vim.keymap.set('n', '<leader>i', function()
      vim.lsp.buf.inlay_hint(bufnr)
    end, { silent=true, buffer=bufnr, desc="lsp.inlayhints.toggle" })

    if client ~= nil and client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_augroup("lsp_codelens",  { clear=false })
      vim.api.nvim_clear_autocmds({ buffer=bufnr, group="lsp_codelens" })
      vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
        group = "lsp_codelens",
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh
      })

      vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
    end


    -- Set some keybinds conditional on server capabilities
    if client ~= nil and lsp.formatting_supported(client) then
      vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format{async=true} end, get_opts({ desc="lsp.format" }))
    end

    if client ~= nil and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_augroup("lsp_document_highlight",  { clear=false })
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
  end,
})

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

require("neodev").setup({})

local capabilities = lsp.capabilities

config.vimls.setup{capabilities=capabilities}
config.ccls.setup{capabilities=capabilities}
config.html.setup{capabilities=capabilities}
config.kotlin_language_server.setup{capabilities=capabilities}

config.cssls.setup{
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
  capabilities=capabilities,
  cmd={"sql-language-server", "up", "--method", "stdio"}
}

typescript.setup{
  server = {
    capabilities=capabilities,
    settings = {
      javascript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
        },
      },
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
        },
      },
    },
  }
}

config.lua_ls.setup({
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace"
      }
    }
  }
})
