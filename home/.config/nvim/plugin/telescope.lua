local yall = require('yall')
local pickers = require('pickers')

yall.setup('telescope', {
	pickers = {
		find_files = { hidden = true },
	},
})
yall.on_load('telescope', function()
	-- Load extensions only after telescope itself is initialized
	local extensions = { 'fzf', 'neoclip', 'file_browser', 'git_grep' }
	for _, ext in ipairs(extensions) do
		require('telescope').load_extension(ext)
	end
end)
yall.pack('telescope', 'telescope.nvim')
yall.cmd('Telescope', 'telescope')

-- Mappings.
pickers.map('<C-p>', pickers.project_files, 'project_files')

local prefix = pickers.prefix

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with flash.nvim (easymotion)
pickers.map(prefix .. 'f', 'find_files')
pickers.map(prefix .. 'j', 'current_buffer_fuzzy_find')
pickers.map(prefix .. 'h', 'help_tags')
pickers.map(prefix .. 't', 'tags')
pickers.map(prefix .. 's', 'grep_string')
pickers.map(prefix .. 'r', 'live_grep')
pickers.map(prefix .. 'k', 'keymaps')
pickers.map(prefix .. 'a', 'autocommands')
pickers.map(prefix .. 'b', 'buffers')
pickers.map(prefix .. '"', 'registers')

pickers.map(prefix .. '?', 'oldfiles')

pickers.map(prefix .. 'o', function()
	require('telescope.builtin').tags({ only_current_buffer = true })
end, { desc = 'tags' })
pickers.map(prefix .. 'c', function()
	require('telescope').extensions.neoclip.default()
end, { desc = 'neoclip' })
pickers.map(prefix .. '.', function()
	require('telescope').extensions.file_browser.file_browser()
end, { desc = 'file_browser' })

-- git
local git_grep_conditional = function()
	-- if called outside a git directory it returns a non-zero exit code
	vim.fn.system(string.format('git -C %s rev-parse --show-toplevel', vim.fn.expand('%:p:h')))
	if vim.v.shell_error == 0 then
		require('git_grep').live_grep()
	else
		require('telescope.builtin').live_grep()
	end
end

pickers.map(prefix .. 'p', git_grep_conditional, 'git_grep')
pickers.map(prefix .. 'gb', 'git_branches')
pickers.map(prefix .. 'gc', 'git_commits')
pickers.map(prefix .. 'gs', 'git_status')
