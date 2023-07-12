local persistence = require("persistence")
local utils = require'utils'

persistence.setup()

local opts = { noremap=true,silent=true }
local get_opts = utils.create_get_opts(opts)

-- restore the session for the current directory
vim.keymap.set("n", "<leader>qs", persistence.load, get_opts({ desc='persistence.load' }))

-- restore the last session
vim.keymap.set("n", "<leader>ql", function () persistence.load({ last = true }) end,
  get_opts({ desc='persistence.load_last' }))

-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", persistence.stop, get_opts({ desc='persistence.stop' }))
