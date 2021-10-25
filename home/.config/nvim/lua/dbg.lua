local dap = require("dap")

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = {os.getenv('HOME') .. '/.local/bin/nodeDebug.js'},
}

dap.configurations.javascript = {
  {
    type = 'node2',
    request = 'launch',
    program = '${workspaceFolder}/${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    console = 'integratedTerminal',
  },
}

dap.configurations.scala = {
  {
    type = "scala",
    request = "launch",
    name = "Run",
    metals = {
      runType = "run",
    },
  },
  {
    type = "scala",
    request = "launch",
    name = "Test File",
    metals = {
      runType = "testFIle",
    },
  },
  {
    type = "scala",
    request = "launch",
    name = "Test Target",
    metals = {
      runType = "testTarget",
    },
  },
}


vim.fn.sign_define('DapBreakpoint', {text='🟥', texthl='', linehl='', numhl=''})
vim.fn.sign_define('DapBreakpointRejected', {text='🟦', texthl='', linehl='', numhl=''})
vim.fn.sign_define('DapStopped', {text='⭐️', texthl='', linehl='', numhl=''})

-- nvim-dap-virtual-text. Show virtual text for current frame
vim.g.dap_virtual_text = true

-- Mappings.
local keymap = vim.api.nvim_set_keymap
local opts = { noremap=true, silent=true }

keymap('n', '<leader>dc', '<cmd>lua require"dap".continue()<CR>', opts)
keymap('n', '<leader>dsv', '<cmd>lua require"dap".step_over()<CR>', opts)
keymap('n', '<leader>dsi', '<cmd>lua require"dap".step_into()<CR>', opts)
keymap('n', '<leader>dso', '<cmd>lua require"dap".step_out()<CR>', opts)
keymap('n', '<leader>dtb', '<cmd>lua require"dap".toggle_breakpoint()<CR>', opts)
keymap('n', '<leader>dsbr', '<cmd>lua require"dap".set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', opts)
keymap('n', '<leader>dsbm', '<cmd>lua require"dap".set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>', opts)
keymap('n', '<leader>dro', '<cmd>lua require"dap".repl.open()<CR>', opts)
keymap('n', '<leader>drl', '<cmd>lua require"dap".repl.run_last()<CR>', opts)

-- nvim-dap-ui
require("dapui").setup()
keymap('n', '<leader>dq', '<cmd>lua require"dapui".toggle()<CR>', opts)

-- telescope-dap
keymap('n', '<leader>dcc', '<cmd>lua require"telescope".extensions.dap.commands{}<CR>', opts)
keymap('n', '<leader>dco', '<cmd>lua require"telescope".extensions.dap.configurations{}<CR>', opts)
keymap('n', '<leader>dlb', '<cmd>lua require"telescope".extensions.dap.list_breakpoints{}<CR>', opts)
keymap('n', '<leader>dv', '<cmd>lua require"telescope".extensions.dap.variables{}<CR>', opts)
keymap('n', '<leader>df', '<cmd>lua require"telescope".extensions.dap.frames{}<CR>', opts)
