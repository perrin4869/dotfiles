local defer = require("defer")
local M = {}

M.get_capabilities = defer.lazy(function()
	return defer.require("cmp_nvim_lsp").default_capabilities()
end)
M.keymaps = {}
M.keymaps.organize_imports = "gro"

return M
