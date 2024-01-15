COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

HOME ?= ${HOME}
XDG_CONFIG_HOME ?= ${HOME}/.config
XDG_DATA_HOME ?= ${HOME}/.local/share
PREFIX ?= ${HOME}/.local

PYTHON := python3
PYTHON_SITE_PACKAGES := $(shell $(PYTHON) -m site --user-site)
PIPX := $(shell command -v pipx 2> /dev/null)
ifneq ($(PIPX),)
	PIPX_LOCAL_VENVS := $(shell pipx environment -v PIPX_LOCAL_VENVS)
endif

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
FZF_ROOT = $(DEPS)/fzf
FZY_ROOT = $(DEPS)/fzy
NERD_FONTS = $(FONTS)/NerdFontsSymbolsOnly
TREESITTER_ROOT = ./home/.local/share/nvim/site/pack/default/start/nvim-treesitter
MASON_ROOT = ./home/.local/share/nvim/mason
MASON_REGISTRY_ROOT = ./home/.local/share/nvim/mason-registry
TELESCOPE_FZF_NATIVE_ROOT = ./home/.local/share/nvim/site/pack/default/start/telescope-fzf-native.nvim
VIM_JSDOC_ROOT = ./home/.vim/pack/default/start/vim-jsdoc

submodules-paths = $(shell cat .gitmodules | grep "path =" | cut -d ' ' -f3)
submodules-deps = $(addsuffix /.git, $(submodules-paths))

helptags-paths = $(shell find ./home/.local/share/nvim/site/pack/default/start -maxdepth 2 -mindepth 2 -type d -name doc)
helptags-deps = $(addsuffix /*.txt, $(helptags-paths))
helptags = $(addsuffix /tags, $(helptags-paths))

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

define meson_package
$(eval $1-target = $(MASON_ROOT)/bin/$1)
$($1-target): $(MASON_REGISTRY_ROOT)/packages/$1/package.yaml
	HOME=./home nvim --headless -c "MasonInstall $1" -c q
	$(if $(findstring true,$2),touch $(MASON_ROOT)/bin/$1,)
$1: $($1-target)
endef

all: mpv-mpris xwinwrap ccls fzf fzy telescope-fzf-native vim_jsdoc eslint_d helptags firacode nerd_fonts iosevka treesitter

.PHONY: submodules
$(submodules-deps) &:
	git submodule update --init --recursive
# Alternatively, to initialize individually (notice we are replacing /.git with an empty string):
# $(submodules-deps):
# 	git submodule update --init --recursive $(@:/.git=)
submodules: $(submodules-deps)

.PHONY: mpv-mpris
mpv-mpris_target = $(MPV_MPRIS_ROOT)/mpris.so
$(eval $(call git_submodule,mpv-mpris,mpv-mpris,$(MPV_MPRIS_ROOT)))
$(mpv-mpris_target): $(mpv-mpris_head_file)
	$(MAKE) -C $(MPV_MPRIS_ROOT)
mpv-mpris: $(mpv-mpris_target)

.PHONY: xwinwrap
xwinwrap_target = $(XWINWRAP_ROOT)/xwinwrap
$(eval $(call git_submodule,xwinwrap,xwinwrap,$(XWINWRAP_ROOT)))
$(xwinwrap_target): $(xwinwrap_head_file)
	$(MAKE) -C $(XWINWRAP_ROOT)
xwinwrap: $(xwinwrap_target)

.PHONY: ccls
ccls_target = $(CCLS_ROOT)/Release/ccls
$(eval $(call git_submodule,ccls,ccls,$(CCLS_ROOT)))
$(ccls_target): $(ccls_head_file)
	cd $(CCLS_ROOT) && \
		$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release && \
		$(CMAKE) --build Release
ccls: $(ccls_target)

.PHONY: nerd_fonts
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

.PHONY: iosevka
iosevka_target = $(FONTS)/Iosevka.ttc
$(iosevka_target): $(FONTS)/SuperTTC-Iosevka-28.0.5.zip
	unzip -o -d $(FONTS) $<
	touch $@
iosevka: $(iosevka_target)

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

.PHONY: helptags
$(helptags)&: $(helptags-deps)
	HOME=./home nvim --headless -c "helptags ALL" -c q
helptags: $(helptags)

.PHONY: treesitter
# print in neovim prints to stderr
treesitter-langs = bash c cpp css graphql haskell html javascript json jsonc latex lua regex scala svelte typescript yaml kotlin vim vimdoc
treesitter-langs-params = $(subst $(SPACE),$(COMMA),$(foreach lang,$(treesitter-langs),'$(lang)'))
treesitter-targets = $(addprefix $(TREESITTER_ROOT)/parser/, $(addsuffix .so, $(treesitter-langs)))
# installing treesitter requires that all neovim config has been installed into rtp (home task)
$(treesitter-targets) &: $(TREESITTER_ROOT)/lockfile.json
	@# https://github.com/nvim-treesitter/nvim-treesitter/issues/2533
	@# rm -f $(treesitter-targets)
	HOME=./home nvim --headless \
			 -c "lua require('nvim-treesitter.install').ensure_installed_sync({ $(treesitter-langs-params) })" \
			 -c "lua require('nvim-treesitter.install').update({ with_sync = true })({ $(treesitter-langs-params) })" \
			 -c q
	touch $(treesitter-targets)
	@# nvim --headless +TSUpdateSync +qa exits immediately
treesitter: $(treesitter-targets)

PHONY: luacheck stylua prettier jsonlint typescript-language-server kotlin-language-server kotlin-debug-adapter sqlls lua-language-server js-debug-adapter
$(eval $(call meson_package,luacheck))
$(eval $(call meson_package,stylua,true))
$(eval $(call meson_package,prettier))
$(eval $(call meson_package,jsonlint))
$(eval $(call meson_package,js-debug-adapter))
$(eval $(call meson_package,typescript-language-server))
$(eval $(call meson_package,kotlin-language-server,true))
$(eval $(call meson_package,kotlin-debug-adapter,true))
$(eval $(call meson_package,sqlls,true))
$(eval $(call meson_package,lua-language-server))
# the mdate on kotlin-debug-adapter executable file dates back to 2021 - update it to avoid rebuilding

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

.PHONY: gitflow
gitflow: $(GITFLOW_ROOT)/.git
	$(MAKE) -C$(GITFLOW_ROOT) prefix=$(PREFIX) install

ifdef PIPX_LOCAL_VENVS
powerline = $(PIPX_LOCAL_VENVS)/powerline-status/bin/powerline-daemon
else
powerline = $(PYTHON_SITE_PACKAGES)/powerline-status.egg-link
endif
$(eval $(call git_submodule,powerline,powerline,$(POWERLINE_ROOT)))
$(powerline): $(powerline_head_file)
ifdef PIPX_LOCAL_VENVS
	pipx install $(POWERLINE_ROOT)
else
	pip install --user --editable=$(POWERLINE_ROOT)
endif
powerline: $(powerline)

ifdef PIPX_LOCAL_VENVS
grip = $(PIPX_LOCAL_VENVS)/grip/bin/grip
else
grip = $(PYTHON_SITE_PACKAGES)/grip.egg-link
endif
$(eval $(call git_submodule,grip,grip,$(GRIP_ROOT)))
$(grip): $(grip_head_file)
ifdef PIPX_LOCAL_VENVS
	pipx install $(GRIP_ROOT)
else
	pip install --user --editable=$(GRIP_ROOT)
endif
grip: $(grip)

.PHONY: dconf
dconf:
	@# dconf dump /desktop/ibus > ibus.dconf
	dconf load /desktop/ibus/ < ${DCONF}/ibus.dconf
	@# dconf dump /org/freedesktop/ibus/ > ibus-engine.dconf
	dconf load /org/freedesktop/ibus/ < ${DCONF}/ibus-engine.dconf # anthy should input hiragana by default

.PHONY: dirs
dirs = $(XDG_CONFIG_HOME) $(XDG_DATA_HOME) $(XDG_DATA_HOME)/icons $(XDG_DATA_HOME)/themes $(PREFIX)/bin
$(dirs):
	mkdir -p $@
dirs: $(dirs)

# By default stow stows to `../$(pwd)`, so in CI we need to be more precise
.PHONY: home
home: dirs
	stow -v home -t $(HOME)

.PHONY: fonts
fonts: home
	# Refresh fonts
	fc-cache -f

.PHONY: install
install: home luacheck stylua prettier jsonlint typescript-language-server kotlin-language-server kotlin-debug-adapter lua-language-server js-debug-adapter sqlls fonts gitflow dconf grip powerline

.PHONY: fzf fzy vim_jsdoc telescope-fzf-native firacode powerline grip
