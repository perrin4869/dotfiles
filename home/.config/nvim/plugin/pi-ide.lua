local yall = require('yall')
yall.pack('pi-ide', 'pi-ide.nvim')
yall.setup('pi-ide')
-- pi only autoconnects to a server that is already listening when it starts
yall.very_lazy('pi-ide')

local diff_review = false

-- pi-ide has no option to skip review (ldelossa/pi-ide.nvim#1), so answer with the accepted proposal instead
yall.on_load('pi-ide', function()
	local diff = require('pi-ide.diff')
	local open_blocking = diff.open_blocking
	diff.open_blocking = function(params)
		if diff_review then
			return open_blocking(params)
		end
		return {
			content = { { type = 'text', text = 'FILE_SAVED' }, { type = 'text', text = params.new_file_contents } },
		}
	end

	-- pi-ide reports any named buffer, so entering a pi terminal would replace the last code selection
	local selection = require('pi-ide.selection')
	local update = selection.update
	selection.update = function()
		if vim.bo.buftype ~= '' then
			return
		end
		update()
	end
end)

local function set_diff_review(enabled)
	diff_review = enabled
	vim.notify('pi-ide diff review ' .. (enabled and 'enabled' or 'disabled'), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('PiDiffEnable', function()
	set_diff_review(true)
end, { desc = 'Review pi edits in a diff before they are applied' })
vim.api.nvim_create_user_command('PiDiffDisable', function()
	set_diff_review(false)
end, { desc = 'Apply pi edits without a diff review' })
vim.api.nvim_create_user_command('PiDiffToggle', function()
	set_diff_review(not diff_review)
end, { desc = 'Toggle diff review of pi edits' })
