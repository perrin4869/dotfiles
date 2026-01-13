local defer = require("defer")
defer.pack("undotree")

local with_undotree = defer.with("undotree")
local call = defer.call

local map = require("config").create_map({
	mode = "n",
	desc = "undotree",
	rhs = function(fname)
		return with_undotree(call(fname))
	end,
})

map("<leader>tu", "toggle")
map("<leader>uo", "open")
map("<leader>uc", "close")

vim.api.nvim_create_user_command("Undotree", function(opts)
	local args = opts.fargs
	local cmd = args[1]

	if cmd == "toggle" then
		defer.require("undotree").toggle()
	elseif cmd == "open" then
		defer.require("undotree").open()
	elseif cmd == "close" then
		defer.require("undotree").close()
	else
		vim.notify("Invalid subcommand: " .. (cmd or ""), vim.log.levels.ERROR)
	end
end, {
	nargs = 1,
	complete = function(_, line)
		local subcommands = { "toggle", "open", "close" }
		local input = vim.split(line, "%s+")
		local prefix = input[#input]

		return vim.tbl_filter(function(cmd)
			return vim.startswith(cmd, prefix)
		end, subcommands)
	end,
	desc = "Undotree command with subcommands: toggle, open, close",
})
