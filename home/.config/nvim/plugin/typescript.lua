vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('LspAttach_typescript', {}),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client ~= nil then
			if client.name == 'vtsls' then
				require('lsp').organize_imports(function()
					require('vtsls').commands.organize_imports(args.buf)
				end, args.buf)
			elseif client.name == 'tsgo' then
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

		-- TODO: add organize imports for tsgo
		-- https://github.com/microsoft/typescript-go/issues/1615
	end,
})

local typescript_lsp = 'tsserver'
if vim.env.LSP_TYPESCRIPT ~= 'tsserver' then
	if vim.env.LSP_TYPESCRIPT == 'vtsls' then
		typescript_lsp = 'vtsls'
	else
		typescript_lsp = 'tsgo' -- TODO: remove tsserver and vtsls once tsgo is stable
	end
end

local defer = require('defer')
defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		pattern = vim.lsp.config[typescript_lsp].filetypes,
		callback = function()
			if typescript_lsp == 'vtsls' then
				vim.cmd.packadd('nvim-vtsls')
			end
			vim.lsp.enable(typescript_lsp)
		end,
	})
end)
