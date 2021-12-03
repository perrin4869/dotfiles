local cmp = require'cmp'
local lspkind = require'lspkind'

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
    ['<CR>'] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
  },
  formatting = {
    format = lspkind.cmp_format({with_text = false})
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'treesitter' },
    { name = 'vsnip' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'tmux' },
    { name = 'calc' },
    { name = 'emoji' },
    { name = 'zsh' },
    { name = 'spell' },
  },
}
