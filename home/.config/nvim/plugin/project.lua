local pickers = require("pickers")
local defer = require("defer")

local function on_attach()
	local persistence = require("persistence")
	persistence.start()
	if vim.uv.fs_stat(require("persistence").current()) ~= nil then
		persistence.load()

		local wins = vim.api.nvim_list_wins()
		for _, w in ipairs(wins) do
			local bufnr = vim.api.nvim_win_get_buf(w)
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			require("restore").get_buf_matches():each(function(m, r)
				if bufname:match(m) ~= nil then
					vim.api.nvim_win_close(w, true)
					vim.api.nvim_buf_delete(bufnr, { force = true })
					r()
				end
			end)
		end
	else
		pickers.project_files()
	end
end

defer.on_load("project", function()
	require("project").setup({
		-- first argument is the workspace name
		manual_mode = true,
		before_attach = function(target_dir)
			local persistence = require("persistence")
			if persistence.active() then
				local cwd = vim.uv.cwd()
				if cwd and vim.fs.normalize(cwd) ~= vim.fs.normalize(target_dir) then
					persistence.save()
				end
				persistence.stop()
			end
		end,
		on_attach = on_attach,
	})
	--
	-- dont autoload if nvim start with arg
	if vim.fn.argc(-1) > 0 then
		return
	end

	local root, method = require("project").get_project_root()
	if not root then
		return
	end

	if vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h") == root then
		on_attach()
		return
	end

	require("project.api").set_pwd(root, method)

	defer.on_postload("telescope", function()
		require("telescope").load_extension("projects")
	end)

	pickers.map(pickers.prefix .. "w", function(telescope)
		telescope.extensions.projects.projects()
	end, { desc = "projects" })
end)

-- it's possible to lazy load because in manual mode we don't set "BufEnter" aucmds
defer.on_event("project", "VimEnter", { nested = true })

vim.api.nvim_create_autocmd("QuitPre", {
	callback = function()
		local tree_wins = {}
		local floating_wins = {}
		-- consider also trying vim.fn.winlayout()
		local wins = vim.api.nvim_list_wins()
		for _, w in ipairs(wins) do
			local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
			if require("restore").ft(ft) then
				table.insert(tree_wins, w)
			end
			if vim.api.nvim_win_get_config(w).relative ~= "" then
				table.insert(floating_wins, w)
			end
		end
		if 1 == #wins - #floating_wins - #tree_wins then
			-- save the session before closing the windows, otherwise the tree state does not get saved
			local persistence = require("persistence")
			if persistence.active() then
				persistence.save()
				persistence.stop()
			end

			-- Should quit, so we close all invalid windows.
			for _, w in ipairs(tree_wins) do
				vim.api.nvim_win_close(w, true)
			end
		end
	end,
})
