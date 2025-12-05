local cmp = require("cmp")
local lspkind = require("lspkind")

cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` user.
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		-- help complete_CTRL-Y
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

		["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-j>"] = cmp.mapping.select_next_item(),
	}),
	formatting = {
		format = lspkind.cmp_format({ mode = "symbol_text" }),
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "nvim_lua" },
		{ name = "treesitter" },
		{ name = "vsnip" },
		{ name = "path" },
		{ name = "tmux" },
		{ name = "calc" },
		{ name = "emoji" },
		{ name = "spell" },
		{ name = "render-markdown" },
		{ name = "lazydev", group_index = 0 }, -- set group index to 0 to skip loading LuaLS completions
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	experimental = {
		ghost_text = true,
	},
})

cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "git" },
	}, {
		{ name = "buffer" },
	}),
})

local cmdline_mappings = cmp.mapping.preset.cmdline({
	-- to preserve C-n and C-p behavior, only apply the mappings if an item is already selected
	-- you can select an item if none has been selected yet by using `Tab`
	["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
	["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
	["<C-n>"] = cmp.mapping(function(fallback)
		if cmp.visible() and cmp.get_selected_entry() then
			return cmp.select_next_item()
		end
		fallback()
	end, { "i", "c" }),
	["<C-p>"] = cmp.mapping(function(fallback)
		if cmp.visible() and cmp.get_selected_entry() then
			return cmp.select_prev_item()
		end
		fallback()
	end, { "i", "c" }),
	["<CR>"] = cmp.mapping(function(fallback)
		if cmp.visible() and cmp.get_selected_entry() then
			return cmp.confirm()
		end
		fallback()
	end, { "i", "c" }),
})

-- cmdline mappings are too troublesome (at least currently)
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmdline_mappings,
	sources = {
		{ name = "buffer" },
	},
})

-- https://github.com/hrsh7th/nvim-cmp/issues/1680
cmp.setup.cmdline(":", {
	mapping = cmdline_mappings,
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})

local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

-- https://github.com/andymass/vim-matchup/pull/382
-- https://github.com/hrsh7th/nvim-cmp/issues/1269
-- https://github.com/hrsh7th/nvim-cmp/issues/1940
cmp.event:on("menu_opened", function()
	vim.b.matchup_matchparen_enabled = false
	-- vim.g.matchup_enabled = false
end)
cmp.event:on("menu_closed", function()
	vim.b.matchup_matchparen_enabled = true
	-- vim.g.matchup_enabled = true
end)
