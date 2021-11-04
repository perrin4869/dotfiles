require('telescope').setup {
  pickers = {
    find_files = {
      hidden = true
    }
  }
}


require('telescope').load_extension('fzf')
require('telescope').load_extension('dap')

-- Mappings.
local keymap = vim.api.nvim_set_keymap
local opts = { noremap=true, silent=true }

keymap('n', '<C-p>', [[<cmd>lua require('telescope.builtin').find_files()<CR>]], opts)

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with hop.nvim
-- so here the prefix is gs
keymap('n', 'g<space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], opts)
keymap('n', 'gsf', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], opts)
keymap('n', 'gsb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], opts)
keymap('n', 'gsh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], opts)
keymap('n', 'gst', [[<cmd>lua require('telescope.builtin').tags()<CR>]], opts)
keymap('n', 'gsd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], opts)
keymap('n', 'gsp', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], opts)
keymap('n', 'gso', [[<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>]], opts)
keymap('n', 'g?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], opts)
