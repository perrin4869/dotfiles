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
					local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
					params.context = {
						only = { 'source.organizeImports' },
						diagnostics = {},
					}

					vim.lsp.buf_request(args.buf, 'textDocument/codeAction', params, function(err, result)
						if err or not result or vim.tbl_isempty(result) then
							return
						end

						local action = result[1]

						if action.edit then
							vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
						end

						if action.command then
							client:exec_cmd(action.command)
						end
					end)
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
