local telescope = require'telescope'
local builtin = require'telescope.builtin'
local utils = require'utils'

telescope.setup{
  pickers = {
    find_files = {
      hidden = true
    }
  }
}


telescope.load_extension'fzf'
telescope.load_extension'dap'
telescope.load_extension'neoclip'
telescope.load_extension'file_browser'

local project_files = function()
  local opts = {} -- define here if you want to define something
  local ok = pcall(require'telescope.builtin'.git_files, opts)
  if not ok then require'telescope.builtin'.find_files(opts) end
end

-- Mappings.
local opts = { noremap=true,silent=true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set('n', '<C-p>', project_files, opts)

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with hop.nvim
-- so here the prefix is gt
vim.keymap.set('n', 'gtf', builtin.find_files, get_opts({ desc="telescope.find_files" }))
vim.keymap.set('n', 'gtj', builtin.current_buffer_fuzzy_find, get_opts({ desc="telescope.find_files" }))
vim.keymap.set('n', 'gth', builtin.help_tags, get_opts({ desc="telescope.help_tags" }))
vim.keymap.set('n', 'gtt', builtin.tags, get_opts({ desc="telescope.tags" }))
vim.keymap.set('n', 'gtd', builtin.grep_string, get_opts({ desc="telescope.grep_string" }))
vim.keymap.set('n', 'gtp', builtin.live_grep, get_opts({ desc="telescope.live_grep" }))
vim.keymap.set('n', 'gtk', builtin.keymaps, get_opts({ desc="telescope.keymaps" }))
vim.keymap.set('n', 'gto', function() builtin.tags{ only_current_buffer = true } end,
  get_opts({ desc="telescope.tags" }))
vim.keymap.set('n', 'gb', builtin.buffers, get_opts({ desc="telescope.buffers" }))
vim.keymap.set('n', 'g?', builtin.oldfiles, get_opts({ desc="telescope.oldfiles" }))

vim.keymap.set('n', 'gtc', telescope.extensions.neoclip.default, get_opts({ desc="telescope.neoclip" }))
vim.keymap.set('n', 'gtt', telescope.extensions.file_browser.file_browser, get_opts({ desc="telescope.file_browser" }))

-- git
vim.keymap.set('n', 'gtb', builtin.git_branches, get_opts({ desc="telescope.git_branches" }))
vim.keymap.set('n', 'gtg', builtin.git_commits, get_opts({ desc="telescope.git_commits" }))
vim.keymap.set('n', 'gts', builtin.git_status, get_opts({ desc="telescope.git_status" }))
