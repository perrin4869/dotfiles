local defer = require('defer')
defer.on_load('nvim-autopairs', function()
	local npairs = require('nvim-autopairs')
	local Rule = require('nvim-autopairs.rule')
	local cond = require('nvim-autopairs.conds')

	npairs.setup({
		-- https://github.com/windwp/nvim-autopairs/issues/314
		enable_abbr = true,
		check_ts = true,
		fast_wrap = {
			map = '<M-e>',
			chars = { '{', '[', '(', '"', "'" },
			pattern = [=[[%'%"%>%]%)%}%,]]=],
			end_key = '$',
			keys = 'qwertyuiopzxcvbnmasdfghjkl',
			check_comma = true,
			manual_position = true,
			highlight = 'Search',
			highlight_grey = 'Comment',
		},
	})

	local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
	npairs.add_rules({
		Rule(' ', ' ')
			:with_pair(cond.done())
			:replace_endpair(function(opts)
				local pair = opts.line:sub(opts.col - 1, opts.col)
				if vim.tbl_contains({ '()', '{}', '[]' }, pair) then
					return ' ' -- it return space here
				end
				return '' -- return empty
			end)
			:with_move(cond.none())
			:with_cr(cond.none())
			:with_del(function(opts)
				local col = vim.api.nvim_win_get_cursor(0)[2]
				local context = opts.line:sub(col - 1, col + 2)
				return vim.tbl_contains({ '(  )', '{  }', '[  ]' }, context)
			end),
	})
	for _, bracket in pairs(brackets) do
		Rule('', ' ' .. bracket[2])
			:with_pair(cond.none())
			:with_move(function(opts)
				return opts.char == bracket[2]
			end)
			:with_cr(cond.none())
			:with_del(cond.none())
			:use_key(bracket[2])
	end
end)
defer.very_lazy('nvim-autopairs')
