vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_typescript", {}),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client ~= nil and client.name == "vtsls" then
			local bufnum = args.buf
			local opts = { noremap = true, silent = true, buffer = bufnum }

			vim.keymap.set("n", require("lsp").keymaps.organize_imports, function()
				require("vtsls").commands.organize_imports(bufnum)
			end, opts)
			vim.api.nvim_buf_create_user_command(bufnum, "OR", "VtsExec organize_imports", { nargs = 0 })
		end
		-- TODO: add organize imports for tsgo
		-- https://github.com/microsoft/typescript-go/issues/1615
	end,
})
