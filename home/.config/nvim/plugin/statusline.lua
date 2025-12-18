local function paste()
	if vim.o.paste then
		return "PASTE"
	end
	return ""
end

vim.api.nvim_create_autocmd("OptionSet", {
	pattern = "paste",
	callback = function()
		require("lualine").refresh()
	end,
})

local function vimtex()
	local status = ""

	local buf = vim.api.nvim_get_current_buf()
	local vt_local = vim.b[buf].vimtex_local or {}

	if next(vt_local) ~= nil then
		if vt_local.active then
			status = status .. "l"
		else
			status = status .. "m"
		end
	end

	local viewer = (vim.b[buf].vimtex or {}).viewer or {}
	if viewer.xwin_id then
		status = status .. "v"
	end

	local compiler = (vim.b[buf].vimtex or {}).compiler or {}
	if next(compiler) ~= nil then
		-- compiler.is_running is a vimscript function, in lua it returned as vim.NIL
		-- this does not work: vim.api.nvim_call_dict_function(compiler, "is_running", {})
		if vim.api.nvim_eval("b:vimtex.compiler.is_running()") == 1 then
			if compiler.continuous then
				status = status .. "c"
			else
				status = status .. "c₁"
			end
		end
	end

	if status ~= "" then
		status = "{" .. status .. "}"
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

require("lualine").setup({
	sections = {
		lualine_a = { "mode", paste },
		lualine_b = {
			{
				"b:gitsigns_head", -- "branch" external source
				icon = "",
				fmt = function(s)
					if #s > 0 then
						return s .. "⚡"
					end
					return s
				end,
			},
			{ "diff", source = diff_source },
			{ "diagnostics", sources = { "nvim_diagnostic", "nvim_lsp" } },
		},
		lualine_c = {
			require("lsp-progress").progress,
			"g:metals_status",
			"g:bsp_status",
			vimtex,
			{
				"filename",
				fmt = function(s)
					if #s > 0 and vim.bo.readonly and vim.bo.ft ~= "help" then
						return "" .. s
					end
					return s
				end,
			},
		},
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	extensions = { "fugitive", "mason", "nvim-tree", "oil", "quickfix", "trouble", "nvim-dap-ui" },
})
