local treesitter_install = require("nvim-treesitter.install")

local M = {}

M.ensure_installed = function(langs)
	treesitter_install.ensure_installed_sync(langs)
	treesitter_install.update({ with_sync = true })(langs)
end

return M
