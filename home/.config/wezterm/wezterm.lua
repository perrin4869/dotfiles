-- Pull in the wezterm API
local wezterm = require('wezterm')

local config = wezterm.config_builder()

-- config.font = wezterm.font("Fira Code")

config.font = wezterm.font({ -- Normal text
	family = 'Iosevka Term',
	-- family = "Iosevka Term",
	-- dlig - Discretionary ligations (it is the superset of calt, the default)
	harfbuzz_features = { 'dlig' },
})

-- https://github.com/githubnext/monaspace/issues/133
-- config.font = wezterm.font({ -- Normal text
-- 	family = "Monaspace Krypton",
-- 	harfbuzz_features = { "calt", "liga", "dlig", "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08" },
-- 	stretch = "UltraCondensed", -- This doesn't seem to do anything
-- })

-- config.font_rules = {
-- 	{ -- Italic
-- 		intensity = "Normal",
-- 		italic = true,
-- 		font = wezterm.font({
-- 			-- family="Monaspace Radon",  -- script style
-- 			family = "Monaspace Xenon", -- courier-like
-- 			style = "Italic",
-- 		}),
-- 	},

-- 	{ -- Bold
-- 		intensity = "Bold",
-- 		italic = false,
-- 		font = wezterm.font({
-- 			family = "Monaspace Krypton",
-- 			-- weight='ExtraBold',
-- 			weight = "Bold",
-- 		}),
-- 	},

-- 	{ -- Bold Italic
-- 		intensity = "Bold",
-- 		italic = true,
-- 		font = wezterm.font({
-- 			family = "Monaspace Xenon",
-- 			style = "Italic",
-- 			weight = "Bold",
-- 		}),
-- 	},
-- }

config.font_size = 16.0
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.color_scheme = 'Gruvbox dark, pale (base16)'

config.window_background_opacity = 0.8
config.enable_tab_bar = false

return config
