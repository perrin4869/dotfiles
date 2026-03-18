local defer = require('defer')

defer.on_load('lualine', function()
	local lualine = require('lualine')
	local function paste()
		if vim.o.paste then
			return 'PASTE'
		end
		return ''
	end

	vim.api.nvim_create_autocmd('OptionSet', {
		pattern = 'paste',
		callback = function()
			require('lualine').refresh()
		end,
	})

	local function vimtex()
		local status = ''

		local buf = vim.api.nvim_get_current_buf()
		local vt_local = vim.b[buf].vimtex_local or {}

		if next(vt_local) ~= nil then
			if vt_local.active then
				status = status .. 'l'
			else
				status = status .. 'm'
			end
		end

		local viewer = (vim.b[buf].vimtex or {}).viewer or {}
		if viewer.xwin_id then
			status = status .. 'v'
		end

		local compiler = (vim.b[buf].vimtex or {}).compiler or {}
		if next(compiler) ~= nil then
			-- compiler.is_running is a vimscript function, in lua it returned as vim.NIL
			-- this does not work: vim.api.nvim_call_dict_function(compiler, "is_running", {})
			if vim.api.nvim_eval('b:vimtex.compiler.is_running()') == 1 then
				if compiler.continuous then
					status = status .. 'c'
				else
					status = status .. 'c₁'
				end
			end
		end

		if status ~= '' then
			status = '{' .. status .. '}'
		end

		return status
	end

	local function diff_source()
		local gitsigns = vim.b.gitsigns_status_dict
		if gitsigns then
			return {
				added = gitsigns.added,
				modified = gitsigns.changed,
				removed = gitsigns.removed,
			}
		end
	end

	local noice = defer.with('noice')(function()
		local noice = require('noice')
		if noice.api.status.mode.has() then
			return noice.api.status.mode.get()
		end
		return ''
	end)

	local progress = defer.with('lsp-progress')(function()
		return require('lsp-progress').progress()
	end)

	-- https://github.com/nvim-lualine/lualine.nvim/pull/1227
	vim.api.nvim_create_autocmd('RecordingEnter', {
		callback = function()
			lualine.refresh()
		end,
	})

	-- The register does not clean up immediately after
	-- recording stops, so we wait a bit (50ms) before refreshing.
	vim.api.nvim_create_autocmd('RecordingLeave', {
		callback = function()
			local timer = vim.loop.new_timer()
			timer:start(
				50,
				0,
				vim.schedule_wrap(function()
					lualine.refresh()
				end)
			)
		end,
	})

	lualine.setup({
		sections = {
			lualine_a = { 'mode', paste },
			lualine_b = {
				{
					'project',

					-- Can be:
					-- - `'short'`         - Only shows the basename of the project root directory (default)
					-- - `'full'`          - Shows the full path but without expanding the home directory
					-- - `'full_expanded'` - Shows the full, expanded path
					format = 'short',

					-- Text to display when no project root is found (set to `nil` or empty string to disable)
					no_project = 'N/A',

					-- The separator
					-- separator = ' ',

					-- Optional table of two strings set as enclosing characters.
					-- Set to `nil` to disable it
					--
					-- e.g. `enclose_pair = { '(', ')' }` ==> `(<YOUR_PROJECT>)`
					--      `enclose_pair = { '<', ']' }` ==> `<<YOUR_PROJECT>]`
					--      `enclose_pair = { nil, 'a' }` ==> `<YOUR_PROJECT>a`
					enclose_pair = nil,
				},
				{
					'b:gitsigns_head', -- "branch" external source
					icon = '',
					fmt = function(s)
						if #s > 0 then
							return s .. '⚡'
						end
						return s
					end,
				},
				{ 'diff', source = diff_source },
				{ 'diagnostics', sources = { 'nvim_diagnostic', 'nvim_lsp' } },
			},
			lualine_c = {
				progress,
				'g:metals_status',
				'g:bsp_status',
				vimtex,
				{
					'filename',
					fmt = function(s)
						if #s > 0 and vim.bo.readonly and vim.bo.ft ~= 'help' then
							return '' .. s
						end
						return s
					end,
				},
			},
			lualine_x = { noice, 'encoding', 'fileformat', 'filetype' },
			lualine_y = { 'progress' },
			lualine_z = { 'location' },
		},
		extensions = { 'fugitive', 'mason', 'neo-tree', 'oil', 'quickfix', 'trouble', 'nvim-dap-ui' },
	})
end)

defer.very_lazy('lualine')
