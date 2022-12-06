local dap = require'dap'
local telescope = require'telescope'.extensions.dap
local utils = require'utils'

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = {os.getenv('HOME') .. '/.local/bin/nodeDebug.js'},
}

dap.configurations.javascript = {
  {
    name = 'Launch',
    type = 'node2',
    request = 'launch',
    program = '${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    console = 'integratedTerminal',
  },
  {
    -- For this to work you need to make sure the node process is started with the `--inspect` flag.
    name = 'Attach to process',
    type = 'node2',
    request = 'attach',
    processId = require'dap.utils'.pick_process,
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
local opts = { noremap=true,silent=true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set('n', '<leader>dt', dap.toggle_breakpoint, get_opts({ desc="dap.toggle_breakpoint" }))
vim.keymap.set('n', '<leader>dH', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
  get_opts({ desc="dap.set_breakpoint" }))
vim.keymap.set('n', '<c-k>', dap.step_out, get_opts({ desc="dap.step_out" }))
vim.keymap.set('n', '<c-l>', dap.step_into, get_opts({ desc="dap.step_into" }))
vim.keymap.set('n', '<c-j>', dap.step_over, get_opts({ desc="dap.step_over" }))
vim.keymap.set('n', '<c-h>', dap.continue, get_opts({ desc="dap.continue" }))
vim.keymap.set('n', '<leader>dk', dap.up, get_opts({ desc="dap.up" }))
vim.keymap.set('n', '<leader>dj', dap.down, get_opts({ desc="dap.down" }))
vim.keymap.set('n', '<leader>dd', function() dap.disconnect({ terminateDebuggee = true }); dap.close() end,
  get_opts({ desc="dap.disconnect" }))
vim.keymap.set('n', '<leader>dr', function() dap.repl.toggle({}, 'vsplit'); vim.cmd('wincmd h') end,
  get_opts({ desc="dap.repl.toggle" }))
vim.keymap.set('n', '<leader>de', function() dap.set_exception_breakpoints({'all'}) end,
  get_opts({ desc="dap.set_exception_breakpoints" }))
vim.keymap.set('n', '<leader>di', function()
  require'dap.ui.widgets'.hover(require('dap.utils').get_visual_selection_text())
end, get_opts({ desc="dap.ui.widgets.hover" }))
vim.keymap.set('n', '<leader>d?', function()
  require'dap.ui.widgets'.cursor_float(require'dap.ui.widgets'.scopes)
end, get_opts({ desc="dap.ui.widgets.scopes" }))

-- Map K to hover while session is active.
local keymap_restore = {}
dap.listeners.after['event_initialized']['me'] = function()
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == "K" then
        table.insert(keymap_restore, keymap)
        vim.api.nvim_buf_del_keymap(buf, 'n', 'K')
      end
    end
  end

  vim.keymap.set('n', 'K', require'dap.ui.widgets'.hover, { silent = true })
end

dap.listeners.after['event_terminated']['me'] = function()
  for _, keymap in pairs(keymap_restore) do
    local rhs = keymap.callback ~= nil and keymap.callback or keymap.rhs
    vim.keymap.set(
      keymap.mode,
      keymap.lhs,
      rhs,
      { buffer = keymap.buffer, silent = keymap.silent == 1 }
    )
  end
  keymap_restore = {}
end

-- autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>
vim.api.nvim_create_augroup("dap_float", {})
vim.api.nvim_clear_autocmds({ group="dap_float" })
vim.api.nvim_create_autocmd("FileType", {
  group = "dap_float",
  pattern = "dap-float",
  callback = function() vim.keymap.set("n", "q", function() vim.cmd("close!") end, opts) end
})


vim.api.nvim_create_augroup("dap_repl", {})
vim.api.nvim_clear_autocmds({ group="dap_repl" })
vim.api.nvim_create_autocmd("FileType", {
  group = "dap_repl",
  pattern = "dap-repl",
  callback = function() vim.cmd("set nobuflisted") end
})
-- autocmd FileType dap-repl set nobuflisted

require('nvim-dap-virtual-text').setup()

-- nvim-dap-ui
require('dapui').setup()
vim.keymap.set('n', '<leader>du', require'dapui'.toggle, get_opts({ desc="dapui.toggle" }))

-- telescope-dap
vim.keymap.set('n', '<leader>dc', telescope.commands, get_opts({ desc="telescope.dap.commands" }))
vim.keymap.set('n', '<leader>db', telescope.list_breakpoints, get_opts({ desc="telescope.dap.list_breakpoints" }))
vim.keymap.set('n', '<leader>dv', telescope.variables, get_opts({ desc="telescope.dap.variables" }))
vim.keymap.set('n', '<leader>df', telescope.frames, get_opts({ desc="telescope.dap.frames" }))
