local pickers = require("pickers")
local defer = require("defer")

local function on_attach()
	local persistence = require("persistence")
	persistence.start()
	if vim.uv.fs_stat(require("persistence").current()) ~= nil then
		persistence.load()

		local wins = vim.api.nvim_list_wins()
		for _, w in ipairs(wins) do
			-- ex bufname neo-tree filesystem [1]
			local bufnr = vim.api.nvim_win_get_buf(w)
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			if bufname:match("neo%-tree filesystem") ~= nil then
				vim.api.nvim_win_close(w, true)
				vim.api.nvim_buf_delete(bufnr, { force = true })
				vim.cmd.Neotree("show")
				break
			end
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
