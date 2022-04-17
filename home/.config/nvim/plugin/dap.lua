local dap = require'dap'
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

-- Mappings.
local opts = { silent=true }

vim.keymap.set('n', '<leader>dh', dap.toggle_breakpoint, opts)
vim.keymap.set('n', '<leader>dH', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, opts)
vim.keymap.set('n', '<c-k>', dap.step_out, opts)
vim.keymap.set('n', '<c-l>', dap.step_into, opts)
vim.keymap.set('n', '<c-j>', dap.step_over, opts)
vim.keymap.set('n', '<c-h>', dap.continue, opts)
vim.keymap.set('n', '<leader>dk', dap.up, opts)
vim.keymap.set('n', '<leader>dj', dap.down, opts)
vim.keymap.set('n', '<leader>dd', function() dap.disconnect({ terminateDebuggee = true }); dap.close() end, opts)
vim.keymap.set('n', '<leader>dr', function() dap.repl.toggle({}, 'vsplit'); api.nvim_command('wincmd l') end, opts)
vim.keymap.set('n', '<leader>de', function() dap.set_exception_breakpoints({'all'}) end, opts)
vim.keymap.set('n', '<leader>di', function()
  require'dap.ui.widgets'.hover(require('dap.utils').get_visual_selection_text())
end, opts)
vim.keymap.set('n', '<leader>d?', function()
  require'dap.ui.widgets'.cursor_float(require'dap.ui.widgets'.scopes)
end, opts)

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

  vim.keymap.set('n', 'K', require'dap.ui.widgets'.hover, { silent = true })
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

require('nvim-dap-virtual-text').setup()

-- nvim-dap-ui
require('dapui').setup()
vim.keymap.set('n', '<leader>du', require'dapui'.toggle, opts)

-- telescope-dap
vim.keymap.set('n', '<leader>dc', function() require'telescope'.extensions.dap.commands{} end, opts)
vim.keymap.set('n', '<leader>db', function() require'telescope'.extensions.dap.list_breakpoints{} end, opts)
vim.keymap.set('n', '<leader>dv', function() require'telescope'.extensions.dap.variables{} end, opts)
vim.keymap.set('n', '<leader>df', function() require'telescope'.extensions.dap.frames{} end, opts)
