HOME ?= ${HOME}
PREFIX ?= ${HOME}/.local
BINDIR  ?= $(PREFIX)/bin
LIBEXECDIR ?= ${PREFIX}/libexec
XDG_DATA_HOME ?= ${PREFIX}/share
XDG_STATE_HOME ?= ${PREFIX}/state
XDG_CONFIG_HOME ?= ${HOME}/.config

PYTHON_SITE_PACKAGES := $(shell $(PYTHON) -m site --user-site)
ifeq ($(shell command -v pipx >/dev/null 2>&1 && echo yes || echo no),yes)
	# pipx --value shorthand changed from -v -> -V somewhere between 1.3.1 and 1.5.0
	PIPX_LOCAL_VENVS = $(shell pipx environment --value PIPX_LOCAL_VENVS)
endif

DEPS = deps
DCONF = dconf
CRON = cron
FONTS = home/.local/share/fonts

MPV_MPRIS_ROOT = $(DEPS)/mpv-mpris
XWINWRAP_ROOT = $(DEPS)/xwinwrap
CCLS_ROOT = $(DEPS)/ccls
ATUIN_ROOT = $(DEPS)/atuin
QMK_CLI_ROOT = $(DEPS)/qmk_cli
ZMK_CLI_ROOT = $(DEPS)/zmk-cli
ESLINT_D_ROOT = $(DEPS)/eslint_d
FZF_ROOT = $(DEPS)/fzf
FZY_ROOT = $(DEPS)/fzy
NERD_FONTS = $(FONTS)/NerdFontsSymbolsOnly
COURSIER_ROOT = $(DEPS)/coursier
METALS_ROOT = $(DEPS)/metals

NVIM_DATA_DIRECTORY = home/.local/share/nvim
TREESITTER_ROOT = $(NVIM_DATA_DIRECTORY)/site/pack/default/start/nvim-treesitter
TREESITTER_PARSERS = $(NVIM_DATA_DIRECTORY)/site/parser
MASON_ROOT = $(NVIM_DATA_DIRECTORY)/mason
MASON_REGISTRY_ROOT = $(NVIM_DATA_DIRECTORY)/mason-registry
TELESCOPE_FZF_NATIVE_ROOT = $(NVIM_DATA_DIRECTORY)/site/pack/default/start/telescope-fzf-native.nvim
NVIM_DIFFTASTIC_ROOT = $(NVIM_DATA_DIRECTORY)/site/pack/default/opt/difftastic.nvim
VIM_JSDOC_ROOT = home/.vim/pack/default/start/vim-jsdoc

GITFLOW_ROOT = $(DEPS)/gitflow
CRONTAB_SRC := $(CRON)/crontab
LOGROTATE_DIR := home/.config/logrotate

ZEN_DIR := $(HOME)/.zen
ZEN_PROFILES_INI := $(ZEN_DIR)/profiles.ini
ZEN_CATPPUCCIN := $(DEPS)/catppuccin/zen-browser/themes/Macchiato/Flamingo
ZEN_CATPPUCCIN_FILES := \
  userChrome.css \
  userContent.css \
  zen-logo-macchiato.svg
