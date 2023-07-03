COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

HOME ?= ${HOME}
XDG_CONFIG_HOME ?= ${HOME}/.config
XDG_DATA_HOME ?= ${HOME}/.local/share
PREFIX ?= ${HOME}/.local

PYTHON := python3
PYTHON_SITE_PACKAGES := $(shell $(PYTHON) -m site --user-site)

CMAKE := cmake

DEPS = ./deps
DCONF = ./dconf
FONTS = ./home/.local/share/fonts

MPV_MPRIS_ROOT = $(DEPS)/mpv-mpris
XWINWRAP_ROOT = $(DEPS)/xwinwrap
CCLS_ROOT = $(DEPS)/ccls
FIRACODE_ROOT = $(DEPS)/FiraCode
POWERLINE_ROOT = $(DEPS)/powerline
GRIP_ROOT = $(DEPS)/grip
GITFLOW_ROOT = $(DEPS)/gitflow
ESLINT_D_ROOT = $(DEPS)/eslint_d
VSCODE_JS_DEBUG = $(DEPS)/vscode-js-debug
FZF_ROOT = $(DEPS)/fzf
FZY_ROOT = $(DEPS)/fzy
LUA_LANGUAGE_SERVER_ROOT = $(DEPS)/lua-language-server
NERD_FONTS = $(FONTS)/NerdFontsSymbolsOnly
TREESITTER_ROOT = ./home/.local/share/nvim/site/pack/default/start/nvim-treesitter
TELESCOPE_FZF_NATIVE_ROOT = ./home/.local/share/nvim/site/pack/default/start/telescope-fzf-native.nvim
VIM_JSDOC_ROOT = ./home/.vim/pack/default/start/vim-jsdoc

submodules-paths = $(shell cat .gitmodules | grep "path =" | cut -d ' ' -f3)
submodules-deps = $(addsuffix /.git, $(submodules-paths))

# Accept as an argument the submodule relative to .git/modules directory
# $(call git_submodule,variable_prefix,module_path,repo_path)
define git_submodule
	$(eval $1_head = $(shell cat .git/modules/$2/HEAD))
	$(eval $1_head_file = $(if $(findstring ref:,$($1_head)),\
		.git/modules/$2/$(lastword $($1_head)),\
		.git/modules/$2/HEAD))

# init submodule if necessary
$($1_head_file): $3/.git
endef

all: mpv-mpris xwinwrap ccls fzf fzy telescope-fzf-native vscode_js_debug vim_jsdoc eslint_d firacode nerd_fonts lua-language-server

$(submodules-deps) &:
	git submodule update --init --recursive
# Alternatively, to initialize individually (notice we are replacing /.git with an empty string):
# $(submodules-deps):
# 	git submodule update --init --recursive $(@:/.git=)
submodules: $(submodules-deps)

mpv-mpris_target = $(MPV_MPRIS_ROOT)/mpris.so
$(eval $(call git_submodule,mpv-mpris,mpv-mpris,$(MPV_MPRIS_ROOT)))
$(mpv-mpris_target): $(mpv-mpris_head_file)
	$(MAKE) -C $(MPV_MPRIS_ROOT)
mpv-mpris: $(mpv-mpris_target)

xwinwrap_target = $(XWINWRAP_ROOT)/xwinwrap
$(eval $(call git_submodule,xwinwrap,xwinwrap,$(XWINWRAP_ROOT)))
$(xwinwrap_target): $(xwinwrap_head_file)
	$(MAKE) -C $(XWINWRAP_ROOT)
xwinwrap: $(xwinwrap_target)

ccls_target = $(CCLS_ROOT)/Release/ccls
$(eval $(call git_submodule,ccls,ccls,$(CCLS_ROOT)))
$(ccls_target): $(ccls_head_file)
	cd $(CCLS_ROOT) && \
		$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release && \
		$(CMAKE) --build Release
ccls: $(ccls_target)

nerd_fonts_target = $(NERD_FONTS)/SymbolsNerdFont-Regular.ttf \
										$(NERD_FONTS)/SymbolsNerdFontMono-Regular.ttf
$(nerd_fonts_target) &: $(NERD_FONTS).tar.xz
	tar xvJf $(NERD_FONTS).tar.xz --one-top-level -C $(FONTS) -m
nerd_fonts: $(nerd_fonts_target)

firacode_target = $(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Regular.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Light.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Bold.ttf
$(eval $(call git_submodule,firacode,deps/FiraCode,$(FIRACODE_ROOT)))
$(firacode_target): $(firacode_head_file)
	cd $(FIRACODE_ROOT) && $(MAKE) # make -C does't work here
firacode: $(firacode_target)

fzf = $(FZF_ROOT)/bin/fzf
$(eval $(call git_submodule,fzf,fzf,$(FZF_ROOT)))
$(fzf): $(fzf_head_file)
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
fzf: $(fzf)

fzy = $(FZY_ROOT)/fzy
$(eval $(call git_submodule,fzy,deps/fzy,$(FZY_ROOT)))
$(fzy): $(fzy_head_file)
	$(MAKE) -C $(FZY_ROOT) clean # TODO: cannot rebuild without clean first
	$(MAKE) -C $(FZY_ROOT)
fzy: $(fzy)

TELESCOPE_FZF_NATIVE_MODULE_PATH=home/.local/share/nvim/site/pack/default/start/telescope-fzf-native.nvim
telescope-fzf-native = $(TELESCOPE_FZF_NATIVE_ROOT)/build/libfzf.so
$(eval $(call git_submodule,telescope-fzf-native,$(TELESCOPE_FZF_NATIVE_MODULE_PATH),$(TELESCOPE_FZF_NATIVE_ROOT)))
$(telescope-fzf-native): $(telescope-fzf-native_head_file)
	$(MAKE) -C $(TELESCOPE_FZF_NATIVE_ROOT)
telescope-fzf-native: $(telescope-fzf-native)

# print in neovim prints to stderr
treesitter-langs = bash c cpp css graphql haskell html javascript json jsonc latex lua regex scala svelte typescript yaml kotlin vim vimdoc
treesitter-targets = $(addprefix $(TREESITTER_ROOT)/parser/, $(addsuffix .so, $(treesitter-langs)))
# installing treesitter requires that all neovim config has been installed into rtp (home task)
$(treesitter-targets) &: home $(TREESITTER_ROOT)/lockfile.json
# 	@# https://github.com/nvim-treesitter/nvim-treesitter/issues/2533
# 	@# rm -f $(treesitter-targets)
	nvim --headless -c "lua require('treesitter').ensure_installed({ $(subst $(SPACE),$(COMMA),$(foreach lang,$(treesitter-langs),'$(lang)')) })" -c q
# 	@# nvim --headless +TSUpdateSync +qa exits immediately
treesitter: $(treesitter-targets)

vscode_js_debug = $(VSCODE_JS_DEBUG)/out/src/vsDebugServer.js
$(eval $(call git_submodule,vscode_js_debug,deps/vscode-js-debug,$(VSCODE_JS_DEBUG)))
$(vscode_js_debug): $(vscode_js_debug_head_file)
	npm --prefix $(VSCODE_JS_DEBUG) ci --legacy-peer-deps
	@# --prefix doesn't seem to work for npm exec
	@# https://github.com/npm/cli/issues/1368
	cd $(VSCODE_JS_DEBUG) && npm exec gulp vsDebugServerBundle
	@#https://github.com/mxsdev/nvim-dap-vscode-js/issues/34
	rm -rf $(VSCODE_JS_DEBUG)/out
	mv $(VSCODE_JS_DEBUG)/dist $(VSCODE_JS_DEBUG)/out
vscode_js_debug: $(vscode_js_debug)

lua-language-server = $(LUA_LANGUAGE_SERVER_ROOT)/bin/lua-language-server
$(eval $(call git_submodule,lua-language-server,deps/lua-language-server,$(LUA_LANGUAGE_SERVER_ROOT)))
$(lua-language-server): $(lua-language-server_head_file)
	( cd $(LUA_LANGUAGE_SERVER_ROOT) && ./make.sh )
lua-language-server: $(lua-language-server)

eslint_d = $(ESLINT_D_ROOT)/node_modules
$(eval $(call git_submodule,eslint_d,deps/eslint_d,$(ESLINT_D_ROOT)))
$(eslint_d): $(eslint_d_head_file)
	npm --prefix $(ESLINT_D_ROOT) ci --omit=dev --ignore-scripts
eslint_d: $(eslint_d)

vim_jsdoc = $(VIM_JSDOC_ROOT)/lib/lehre
$(eval $(call git_submodule,vim_jsdoc,vim/bundle/vim-jsdoc,$(VIM_JSDOC_ROOT)))
$(vim_jsdoc): $(vim_jsdoc_head_file)
	$(MAKE) -C$(VIM_JSDOC_ROOT) clean && $(MAKE) -C$(VIM_JSDOC_ROOT) install
vim_jsdoc: $(vim_jsdoc)

gitflow: $(GITFLOW_ROOT)/.git
	$(MAKE) -C$(GITFLOW_ROOT) prefix=$(PREFIX) install

powerline = $(PYTHON_SITE_PACKAGES)/powerline-status.egg-link
$(eval $(call git_submodule,powerline,powerline,$(POWERLINE_ROOT)))
$(powerline): $(powerline_head_file)
	pip install --user --editable=$(POWERLINE_ROOT)
powerline: $(powerline)

grip = $(PYTHON_SITE_PACKAGES)/grip.egg-link
$(eval $(call git_submodule,grip,grip,$(GRIP_ROOT)))
$(grip): $(grip_head_file)
	pip install --user --editable=$(GRIP_ROOT)
grip: $(grip)

dconf:
	@# dconf dump /desktop/ibus > ibus.dconf
	dconf load /desktop/ibus/ < ${DCONF}/ibus.dconf
	@# dconf dump /org/freedesktop/ibus/ > ibus-engine.dconf
	dconf load /org/freedesktop/ibus/ < ${DCONF}/ibus-engine.dconf # anthy should input hiragana by default

dirs = $(XDG_CONFIG_HOME) $(XDG_DATA_HOME) $(XDG_DATA_HOME)/icons $(XDG_DATA_HOME)/themes $(PREFIX)/bin
$(dirs):
	mkdir -p $@
dirs: $(dirs)

# By default stow stows to `../$(pwd)`, so in CI we need to be more precise
home: dirs
	stow -v home -t $(HOME)

fonts: home
	# Refresh fonts
	fc-cache -f

install: home treesitter fonts gitflow powerline grip dconf

.PHONY: install fzf fzy gitflow mpv-mpris xwinwrap ccls powerline vim_jsdoc vscode_js_debug telescope-fzf-native treesitter firacode grip dirs submodules dconf home fonts nerd_fonts lua-language-server
