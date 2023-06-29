vim.opt.foldmethod="expr"
vim.opt.foldexpr="nvim_treesitter#foldexpr()"
-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
vim.opt.foldlevelstart=99

-- https://alpha2phi.medium.com/neovim-101-tree-sitter-usage-fa3e8bed921a
local swap_next, swap_prev = (function()
  local swap_objects = {
    p = "@parameter.inner",
    f = "@function.outer",
    c = "@class.outer",
  }

  local n, p = {}, {}
  for key, obj in pairs(swap_objects) do
    n[string.format("<A-n><A-%s>", key)] = obj
    p[string.format("<A-p><A-%s>", key)] = obj
  end

  return n, p
end)()

require'nvim-treesitter.configs'.setup {
  -- ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  -- This is handled by the Makefile
  -- ensure_installed = require('treesitter').langs,
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  matchup = {
    enable = true,              -- mandatory, false will disable the whole extension
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<M-w>', -- alternatives: gnn, <CR>
      scope_incremental = '<M-e>', -- alternatives: grc, <CR>
      node_incremental = '<M-w>', -- alternatives: grn, <TAB>
      node_decremental = '<M-C-w>', -- alternatives: grm, <S-TAB>
    }
  },
  indent = { enable = true },
  playground = {
    enable = true,
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
  },
  rainbow = {
    enable = true,
    query = {
      'rainbow-parens',
      html = 'rainbow-tags'
    },
  },
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner"
      },
    },
    swap = {
      enable = true,
      swap_next = swap_next,
      swap_previous = swap_prev,
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer'
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer'
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer'
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer'
      },
    }
  },
  context_commentstring = {enable = true},
}
