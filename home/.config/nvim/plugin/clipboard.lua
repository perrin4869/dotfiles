local type_map = { char = "v", line = "V", block = "\22" }

local function yank_osc52(m, op_type)
	local s_mark, e_mark, sel_type

	if m == "visual" then
		sel_type = vim.fn.mode()
		-- Sync marks: Exit visual mode synchronously before reading marks
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "nx", true)
		s_mark, e_mark = "'<", "'>"
	elseif m == "op" then
		s_mark, e_mark = "'[", "']"
		sel_type = type_map[op_type] or op_type
	elseif m == "line" then
		s_mark, e_mark, sel_type = ".", ".", "V"
	end

	local region = vim.fn.getregion(vim.fn.getpos(s_mark), vim.fn.getpos(e_mark), { type = sel_type })

	if #region > 0 then
		local osc52 = require("vim.ui.clipboard.osc52")
		local text = table.concat(region, "\n")
		osc52.copy("+")({ text })
		print(string.format("OSC52: Yanked %d line%s", #region, #region > 1 and "s" or ""))
	end
end

local function create_osc52(mode)
	-- Mapping Neovim's operator names to getregion's expected mode characters

	if mode == "op" then
		_G.osc_callback = function(t)
			yank_osc52("op", t)
		end
		return function()
			vim.opt.opfunc = "v:lua.osc_callback"
			return "g@"
		end
	elseif mode == "visual" then
		return function()
			yank_osc52("visual")
		end
	elseif mode == "line" then
		return function()
			yank_osc52("line")
		end
	end
end

local map = require("map").create({
	desc = "OSC52",
	desc_separator = " ",
})
-- The Mappings
map("n", "<leader>c", create_osc52("op"), { expr = true, desc = "Operator" })
map("n", "<leader>cc", create_osc52("line"), "Yank Line")
map("v", "<leader>c", create_osc52("visual"), "Yank Visual")
