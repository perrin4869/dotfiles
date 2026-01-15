local M = {}

local OPTS = { silent = true, noremap = true }
--- create a map function that has defaults across the repo
--- @param opts? {desc:string,desc_separator?:string,buffer?:integer|boolean,opts?:vim.keymap.set.Opts,mode?:string|string[],rhs?:fun(arg:any):function}
--- @return function
function M.create(opts)
	opts = opts or {}
	opts.opts = opts.opts or OPTS
	opts.desc_separator = opts.desc_separator or '.'

	if opts.buffer ~= nil then
		opts.opts = vim.tbl_extend('force', opts.opts, { buffer = opts.buffer })
	end

	local function map(mode, lhs, rhs, o)
		o = o or {}
		if type(o) == 'string' then
			o = { desc = o }
		end

		if not o.desc then
			if type(rhs) == 'string' then
				o.desc = rhs
			elseif type(rhs) == 'table' and type(rhs[1]) == 'string' then
				o.desc = rhs[1]
			else
				o.desc = lhs
			end
		end

		local desc = opts.desc and { desc = opts.desc .. opts.desc_separator .. o.desc } or {}

		if opts.rhs then
			rhs = opts.rhs(rhs)
		end

		vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', opts.opts, o, desc))
	end

	if opts.mode then
		return function(lhs, rhs, o)
			map(opts.mode, lhs, rhs, o)
		end
	else
		return function(mode, lhs, rhs, o)
			map(mode, lhs, rhs, o)
		end
	end
end

M.map = M.create()

return M
