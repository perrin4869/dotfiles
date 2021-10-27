local dap = require("dap")
local api = vim.api

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = {os.getenv('HOME') .. '/.local/bin/nodeDebug.js'},
}

dap.configurations.javascript = {
  {
    name = "Run",
    type = 'node2',
    request = 'launch',
    program = '${workspaceFolder}/${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    console = 'integratedTerminal',
  },
  {
    name = "Attach",
    type = 'node2',
    request = 'attach',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    skipFiles = {'<node_internals>/**/*.js'},
  },
}

dap.configurations.typescript = dap.configurations.javascript

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
local keymap = api.nvim_set_keymap
local opts = { noremap=true, silent=true }

keymap('n', '<leader>dh', ':lua require"dap".toggle_breakpoint()<CR>', opts)
keymap('n', '<leader>dH', ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", opts)
keymap('n', '<c-k>', ':lua require"dap".step_out()<CR>', opts)
keymap('n', '<c-l>', ':lua require"dap".step_into()<CR>', opts)
keymap('n', '<c-j>', ':lua require"dap".step_over()<CR>', opts)
keymap('n', '<c-h>', ':lua require"dap".continue()<CR>', opts)
keymap('n', '<leader>dk', ':lua require"dap".up()<CR>', opts)
keymap('n', '<leader>dj', ':lua require"dap".down()<CR>', opts)
keymap('n', '<leader>dd', ':lua require"dap".disconnect({ terminateDebuggee = true });require"dap".close()<CR>', opts)
keymap('n', '<leader>dr', ':lua require"dap".repl.toggle({}, "vsplit")<CR><C-w>l', opts)
keymap('n', '<leader>di', ':lua require"dap.ui.variables".visual_hover()<CR>', opts)
keymap('n', '<leader>d?', ':lua require"dap.ui.variables".scopes()<CR>', opts)
keymap('n', '<leader>de', ':lua require"dap".set_exception_breakpoints({"all"})<CR>', opts)

-- Map K to hover while session is active.
local keymap_restore = {}
dap.listeners.after['event_initialized']['me'] = function()
  for _, buf in pairs(api.nvim_list_bufs()) do
    local keymaps = api.nvim_buf_get_keymap(buf, 'n')
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == "K" then
        table.insert(keymap_restore, keymap)
        api.nvim_buf_del_keymap(buf, 'n', 'K')
      end
    end
  end
  api.nvim_set_keymap(
    'n', 'K', '<Cmd>lua require("dap.ui.variables").hover()<CR>', { silent = true })
end

dap.listeners.after['event_terminated']['me'] = function()
  for _, keymap in pairs(keymap_restore) do
    api.nvim_buf_set_keymap(
      keymap.buffer,
      keymap.mode,
      keymap.lhs,
      keymap.rhs,
      { silent = keymap.silent == 1 }
    )
  end
  keymap_restore = {}
end

-- nvim-dap-ui
require("dapui").setup()
keymap('n', '<leader>du', '<cmd>lua require"dapui".toggle()<CR>', opts)

-- telescope-dap
keymap('n', '<leader>dc', '<cmd>lua require"telescope".extensions.dap.commands{}<CR>', opts)
keymap('n', '<leader>db', '<cmd>lua require"telescope".extensions.dap.list_breakpoints{}<CR>', opts)
keymap('n', '<leader>dv', '<cmd>lua require"telescope".extensions.dap.variables{}<CR>', opts)
keymap('n', '<leader>df', '<cmd>lua require"telescope".extensions.dap.frames{}<CR>', opts)
