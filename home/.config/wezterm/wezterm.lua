-- Pull in the wezterm API
local wezterm = require 'wezterm'

local config = wezterm.config_builder()
config.font = wezterm.font 'Fira Code'
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
