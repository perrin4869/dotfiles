vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('LspAttach_typescript', {}),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client ~= nil then
			if client.name == 'tsc' then
				require('lsp').organize_imports(function()
					vim.lsp.buf.code_action({
						context = { only = { 'source.organizeImports' } },
						apply = true,
						filter = function(_, client_id)
							return client_id == client.id
						end,
					})
				end, args.buf)
			end
		end
	end,
})

local yall = require('yall')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		pattern = vim.lsp.config['tsc'].filetypes,
		callback = function()
			vim.lsp.enable('tsc')
		end,
	})
end)
