local trouble = require('trouble')

trouble.setup{}

vim.api.nvim_create_augroup("LspAttach_trouble", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttach_trouble",
  callback = function(args)
    if not (args.data and args.data.client_id) then
      return
    end

    local bufopts = { silent=true, buffer=args.buf }
    local function get_opts(right)
      local merged = {}
      for k,v in pairs(bufopts) do merged[k] = v end
      for k,v in pairs(right) do merged[k] = v end
      return merged
    end

    vim.keymap.set("n", "<leader>xx", trouble.open, get_opts({ desc="trouble.open" }))
    vim.keymap.set("n", "<leader>xw", function() trouble.open('workspace_diagnostics') end,
      get_opts({ desc="trouble.workspace_diagnostics" }))
    vim.keymap.set("n", "<leader>xd", function() trouble.open('document_diagnostics') end,
      get_opts({ desc="trouble.document_diagnostics" }))
    vim.keymap.set("n", "<leader>xl", function() trouble.open('loclist') end,
      get_opts({ desc="trouble.loclist" }))
    vim.keymap.set("n", "<leader>xq", function() trouble.open('quickfix') end,
      get_opts({ desc="trouble.quickfix" }))
    vim.keymap.set("n", "gR", function() trouble.open('lsp_references') end,
      get_opts({ desc="trouble.lsp_references" }))

    vim.keymap.set("n", "gt", trouble.toggle, get_opts({ desc="trouble.toggle" }))
  end,
})
