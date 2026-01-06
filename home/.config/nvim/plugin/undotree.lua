local utils = require("utils")
local defer = require("defer")
defer.pack("undotree")

local with_undotree = defer.with("undotree")
local call = defer.call

local get_opts = utils.create_get_opts({ noremap = true, silent = true })
local map = function(mode, lhs, fname)
	vim.keymap.set(mode, lhs, with_undotree(call(fname)), get_opts({ desc = "undotree." .. fname }))
end

map("n", "<leader>tu", "toggle")
map("n", "<leader>uo", "open")
map("n", "<leader>uc", "close")

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
