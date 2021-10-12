local cmp = require'cmp'
local lspkind = require'lspkind'

-- reduce flickers in custom menu
-- https://github.com/hrsh7th/nvim-cmp/issues/231#issuecomment-940196930
vim.api.nvim_set_option('lazyredraw', true)

cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` user.
    end,
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  formatting = {
    format = lspkind.cmp_format({with_text = false})
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'calc' },
    { name = 'emoji' },
  },
}
