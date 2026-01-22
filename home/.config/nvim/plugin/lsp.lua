local defer = require('defer')

defer.on_load('lsp', function()
	local lsp = require('lsp')

	vim.api.nvim_create_autocmd('LspAttach', {
		group = vim.api.nvim_create_augroup('LspAttach_general', { clear = true }),
		callback = function(args)
			if not (args.data and args.data.client_id) then
				return
			end

			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local bufnr = args.buf

			vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

			-- Mappings.
			local map = require('map').create({ mode = 'n', desc = 'lsp', buffer = bufnr })

			map('gD', vim.lsp.buf.declaration, 'declaration')
			map('gd', vim.lsp.buf.definition, 'definition')
			map('K', require('lsp').hover, 'hover')
			map('grk', require('lsp').signature_help, 'signature_help')
			map('<leader>wa', vim.lsp.buf.add_workspace_folder, 'add_workspace_folder')
			map('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'remove_workspace_folder')
			map('<leader>wl', require('lsp').list_workspace_folders, 'list_workspace_folders')
			-- map('<leader>ds', vim.lsp.buf.document_symbol, "document_symbol")
			-- map('<leader>ws', vim.lsp.buf.workspace_symbol, "workspace_symbol")

			-- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
			local pickers = require('pickers')
			pickers.map('<leader>ds', 'lsp_document_symbols')
			pickers.map('<leader>ws', 'lsp_dynamic_workspace_symbols')
			-- https://github.com/nvim-telescope/telescope.nvim/issues/964
			-- uses dynamic because most language servers return an empty list on an empty query

			if client ~= nil then
				vim.diagnostic.config({
					underline = true,
					virtual_text = false,
					virtual_lines = { current_line = true },
					signs = true,
					update_in_insert = false,
				}, vim.lsp.diagnostic.get_namespace(client.id))
			end

			if client ~= nil and client.server_capabilities.inlayHintProvider then
				map(vim.g.toggle_prefix .. 'i', function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
				end, 'inlayhints.toggle')
				-- this is too verbose, so do not enable this by default
				-- vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			if client ~= nil and client:supports_method('textDocument/codeLens', bufnr) then
				local group = vim.api.nvim_create_augroup('lsp_codelens', { clear = false })
				vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
				-- https://github.com/LunarVim/LunarVim/pull/2600
				vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
					group = group,
					buffer = bufnr,
					callback = function()
						vim.lsp.codelens.refresh({ bufnr = bufnr })
					end,
				})

				map('grc', vim.lsp.codelens.run, 'codelens.run')
			end
		end,
	})

	vim.lsp.config('*', {
		capabilities = lsp.get_capabilities(),
	})

	vim.lsp.enable({
		'bashls',
		'vimls',
		'html',
		'kotlin_lsp',
		'cssls',
		'jsonls',
		'sqlls',
	})
end)
defer.deps('lsp', { 'lspconfig', 'mason' })
defer.on_bufreadpost('lsp')
defer.pack('lspconfig', 'nvim-lspconfig')
defer.on_bufreadpre('lspconfig')
