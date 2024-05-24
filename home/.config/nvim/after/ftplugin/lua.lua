vim.api.nvim_create_user_command("OsvLaunch", function()
	require("osv").launch({ port = 8086 })
end, { desc = "Launch osv" })

vim.api.nvim_create_user_command("OsvStop", require("osv").stop, { desc = "Stop osv" })
