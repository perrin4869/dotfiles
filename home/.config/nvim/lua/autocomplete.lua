require("compe").setup {
  enabled = true,
  autocomplete = true,
  source = {
    path = true,
    buffer = true,
    calc = true,
    nvim_lsp = true,
    nvim_lua = true,
    vsnip = true,
    emoji = true,
    tmux = true,
  },
}

-- https://github.com/hrsh7th/nvim-compe/issues/302
-- Expand function signature as a snippet
local Helper = require "compe.helper"
Helper.convert_lsp_orig = Helper.convert_lsp
Helper.convert_lsp = function(args)
  local response = args.response or {}
  local items = response.items or response
  for _, item in ipairs(items) do
    -- 2: method
    -- 3: function
    -- 4: constructor
    if item.insertText == nil and (item.kind == 2 or item.kind == 3 or item.kind == 4) then
      item.insertText = item.label .. "(${1})"
      item.insertTextFormat = 2
    end
  end
  return Helper.convert_lsp_orig(args)
end
