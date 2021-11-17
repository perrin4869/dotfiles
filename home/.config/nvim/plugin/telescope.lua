require('telescope').setup {
  pickers = {
    find_files = {
      hidden = true
    }
  }
}


require('telescope').load_extension('fzf')
require('telescope').load_extension('dap')

local project_files = function()
  local opts = {} -- define here if you want to define something
  local ok = pcall(require'telescope.builtin'.git_files, opts)
  if not ok then require'telescope.builtin'.find_files(opts) end
end

-- Mappings.
local keymap = vim.api.nvim_set_keymap
local opts = { noremap=true, silent=true }

keymap('n', '<C-p>', [[<cmd>lua require('utils').project_files()<CR>]], opts)

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with hop.nvim
-- so here the prefix is gs
keymap('n', 'gsf', [[<cmd>lua require('telescope.builtin').find_files()<CR>]], opts)
keymap('n', 'gsj', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], opts)
keymap('n', 'gsh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], opts)
keymap('n', 'gst', [[<cmd>lua require('telescope.builtin').tags()<CR>]], opts)
keymap('n', 'gsd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], opts)
keymap('n', 'gsp', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], opts)
keymap('n', 'gsk', [[<cmd>lua require('telescope.builtin').keymaps()<CR>]], opts)
keymap('n', 'gso', [[<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>]], opts)
keymap('n', 'gb', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], opts)
keymap('n', 'g?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], opts)

-- git
keymap('n', 'gsb', [[<cmd>lua require('telescope.builtin').git_branches()<CR>]], opts)
keymap('n', 'gsc', [[<cmd>lua require('telescope.builtin').git_commits()<CR>]], opts)
keymap('n', 'gss', [[<cmd>lua require('telescope.builtin').git_status()<CR>]], opts)
