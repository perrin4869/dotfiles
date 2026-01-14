local defer = require("defer")
local M = {}

M.get_capabilities = defer.lazy(function()
	return defer.require("cmp_nvim_lsp").default_capabilities()
end)

--- setup organize_imports mappings and user command
--- @param organize_imports function
--- @param buffer integer
function M.organize_imports(organize_imports, buffer)
	require("map").map("n", "gro", organize_imports, { buffer = buffer, desc = "lsp.organize_imports" })
	vim.api.nvim_buf_create_user_command(buffer, "LspOrganizeImports", organize_imports, { nargs = 0 })
end

function M.hover()
	vim.lsp.buf.hover({ border = require("config").border })
end

function M.signature_help()
	vim.lsp.buf.signature_help({ border = require("config").border })
end

function M.list_workspace_folders()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end

return M
