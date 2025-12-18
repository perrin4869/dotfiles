local M = {}

M.capabilities = require("cmp_nvim_lsp").default_capabilities()
M.keymaps = {}
M.keymaps.organize_imports = "gro"

return M
