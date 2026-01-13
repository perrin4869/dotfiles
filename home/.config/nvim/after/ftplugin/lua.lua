vim.api.nvim_create_user_command("OsvLaunch", function()
	require("osv").launch({ port = 8086 })
end, { desc = "Launch osv" })

vim.api.nvim_create_user_command("OsvStop", require("osv").stop, { desc = "Stop osv" })

local map = require("config").create_map({
	desc = "execute lua",
	desc_separator = " ",
	buffer = true,
})
map("n", "<leader>.x", function()
	vim.cmd(".source")
end, "lua")
map("n", "<leader>.X", function()
	vim.cmd("source %")
end, "file")
map("x", "<leader>.", function()
	vim.cmd("'<'>source")
end, "visual")
