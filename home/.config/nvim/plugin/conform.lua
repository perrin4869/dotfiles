local defer = require("defer")

defer.on_load("conform", function()
	local conform = require("conform")

	local json = { "prettierd", "prettier", stop_after_first = true }
	local js = { "eslint_d" }
	conform.setup({
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = js,
			javascriptreact = js,
			typescript = js,
			typescriptreact = js,
			-- Use a sub-list to run only the first available formatter
			json = json,
			jsonc = json,
			kotlin = { lsp_format = "never" },
			["_"] = { "trim_whitespace", lsp_format = "prefer" },
		},
		default_format_opts = {
			lsp_format = "fallback",
			async = true,
		},
		format_after_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat or vim.bo[bufnr].readonly then
				return
			end

			return {
				bufnr = bufnr,
			}
		end,
	})

	local function toggle_autoformat(args)
		if args and args.bang then
			-- FormatDisable! will disable formatting just for this buffer
			vim.b.disable_autoformat = not (vim.b.disable_autoformat == nil and false or vim.b.disable_autoformat)
		else
			vim.g.disable_autoformat = not (vim.g.disable_autoformat == nil and false or vim.g.disable_autoformat)
		end
	end

	local function enable_autoformat()
		vim.b.disable_autoformat = false
		vim.g.disable_autoformat = false
	end

	local function disable_autoformat(args)
		if args and args.bang then
			-- FormatDisable! will disable formatting just for this buffer
			vim.b.disable_autoformat = true
		else
			vim.g.disable_autoformat = true
		end
	end

	local map = require("map").create({ desc = "conform" })
	map({ "n", "x" }, "<leader>ff", function()
		require("conform").format({}, function(err)
			if not err then
				local mode = vim.api.nvim_get_mode().mode
				if vim.startswith(string.lower(mode), "v") then
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
				end
			end
		end)
	end, "format")
	map("n", "<leader>tf", toggle_autoformat, "toggle_autoformat")

	vim.api.nvim_create_user_command("Format", function(args)
		local range = nil
		if args.count ~= -1 then
			local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
			range = {
				start = { args.line1, 0 },
				["end"] = { args.line2, end_line:len() },
			}
		end
		require("conform").format({ range = range })
	end, { range = true })

	vim.api.nvim_create_user_command("FormatEnable", enable_autoformat, { desc = "Re-enable autoformat-on-save" })
	vim.api.nvim_create_user_command(
		"FormatDisable",
		disable_autoformat,
		{ desc = "Disable autoformat-on-save", bang = true }
	)
	vim.api.nvim_create_user_command(
		"FormatToggle",
		toggle_autoformat,
		{ desc = "Toggle autoformat-on-save", bang = true }
	)
end)
defer.pack("conform", "conform.nvim")
defer.on_bufreadpost("conform")
