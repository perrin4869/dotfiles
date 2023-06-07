local utils = require'utils'

local opts = { noremap=true,silent=true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set('n', '<space>d', require'dropbar.api'.pick, get_opts({ desc="dropbar.pick" }))

vim.api.nvim_create_augroup("dropbar", {})
vim.api.nvim_clear_autocmds({ group="dropbar" })
vim.api.nvim_create_autocmd("FileType", {
  group = "dropbar",
  pattern = "dropbar_menu",
  callback = function() vim.keymap.set("n", "q", function() vim.cmd("close!") end, opts) end
})
