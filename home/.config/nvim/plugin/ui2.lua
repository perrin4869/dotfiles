require('vim._core.ui2').enable({
	enable = true,
	msg = {
		targets = 'msg',
		-- targets = {
		-- 	[''] = 'msg',
		-- 	progress = 'pager',
		-- },
	},
})
vim.opt.winborder = 'rounded'
vim.opt.completeopt:append('popup')

-- alternative to fidget.nvim, but I like the ui of fidget better now
-- vim.api.nvim_create_autocmd('LspProgress', {
-- 	callback = function(ev)
-- 		local value = ev.data.params.value
-- 		vim.api.nvim_echo({ { value.message or 'done' } }, false, {
-- 			id = 'lsp.' .. ev.data.client_id,
-- 			kind = 'progress',
-- 			source = 'vim.lsp',
-- 			title = value.title,
-- 			status = value.kind ~= 'end' and 'running' or 'success',
-- 			percent = value.percentage,
-- 		})
-- 	end,
-- })

-- https://www.reddit.com/r/neovim/comments/1sfmgkb/comment/oeyrgua/?context=3&share_id=vqpfjzy9qK_XYcfjDfCYD&utm_medium=ios_app&utm_name=ioscss&utm_source=share&utm_term=1
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'msg',
	callback = function()
		local ui2 = require('vim._core.ui2')
		local win = ui2.wins and ui2.wins.msg
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_set_option_value(
				'winhighlight',
				'Normal:NormalFloat,FloatBorder:FloatBorder',
				{ scope = 'local', win = win }
			)
		end
	end,
})

local ui2 = require('vim._core.ui2')
local msgs = require('vim._core.ui2.messages')
local orig_set_pos = msgs.set_pos
msgs.set_pos = function(tgt)
	orig_set_pos(tgt)
	if (tgt == 'msg' or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.msg) then
		pcall(vim.api.nvim_win_set_config, ui2.wins.msg, {
			relative = 'editor',
			anchor = 'NE',
			row = 2,
			col = vim.o.columns - 1,
			-- border = 'rounded',
		})
	end
end
