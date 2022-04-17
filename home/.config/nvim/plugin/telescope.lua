require('telescope').setup {
  pickers = {
    find_files = {
      hidden = true
    }
  }
}


require('telescope').load_extension('fzf')
require('telescope').load_extension('dap')
require('telescope').load_extension('neoclip')

local project_files = function()
  local opts = {} -- define here if you want to define something
  local ok = pcall(require'telescope.builtin'.git_files, opts)
  if not ok then require'telescope.builtin'.find_files(opts) end
end

-- Mappings.
local opts = { silent=true }

vim.keymap.set('n', '<C-p>', require('utils').project_files, opts)

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with hop.nvim
-- so here the prefix is gs
vim.keymap.set('n', 'gsf', require('telescope.builtin').find_files, opts)
vim.keymap.set('n', 'gsj', require('telescope.builtin').current_buffer_fuzzy_find, opts)
vim.keymap.set('n', 'gsh', require('telescope.builtin').help_tags, opts)
vim.keymap.set('n', 'gst', require('telescope.builtin').tags, opts)
vim.keymap.set('n', 'gsd', require('telescope.builtin').grep_string, opts)
vim.keymap.set('n', 'gsp', require('telescope.builtin').live_grep, opts)
vim.keymap.set('n', 'gsk', require('telescope.builtin').keymaps, opts)
vim.keymap.set('n', 'gso', function() require('telescope.builtin').tags{ only_current_buffer = true } end, opts)
vim.keymap.set('n', 'gb', require('telescope.builtin').buffers, opts)
vim.keymap.set('n', 'g?', require('telescope.builtin').oldfiles, opts)

vim.keymap.set('n', 'gsc', require('telescope').extensions.neoclip.default, opts)

-- git
vim.keymap.set('n', 'gsb', require('telescope.builtin').git_branches, opts)
vim.keymap.set('n', 'gsg', require('telescope.builtin').git_commits, opts)
vim.keymap.set('n', 'gss', require('telescope.builtin').git_status, opts)
