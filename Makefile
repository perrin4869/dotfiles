XDG_CONFIG_HOME ?= ${HOME}/.config
XDG_DATA_HOME ?= ${HOME}/.local/share
PREFIX ?= ${HOME}/.local

PYTHON := python3
PYTHON_SITE_PACKAGES := $(shell $(PYTHON) -m site --user-site)

CMAKE := cmake

DEPS = ./deps
DCONF = ./dconf

MPV_MPRIS_ROOT = $(DEPS)/mpv-mpris
XWINWRAP_ROOT = $(DEPS)/xwinwrap
CCLS_ROOT = $(DEPS)/ccls
POWERLINE_ROOT = $(DEPS)/powerline
GRIP_ROOT = $(DEPS)/grip
GITFLOW_ROOT = $(DEPS)/gitflow
FZF_ROOT = $(DEPS)/fzf
COC_ROOT = $(XDG_CONFIG_HOME)/coc

submodules-paths = $(shell cat .gitmodules | grep "path =" | cut -d ' ' -f3)
submodules-deps = $(submodules-paths:=/.git)

all: mpv-mpris xwinwrap ccls

mpv-mpris = $(MPV_MPRIS_ROOT)/mpv-mpris.so
$(mpv-mpris): $(MPV_MPRIS_ROOT)/.git
	$(MAKE) -C $(MPV_MPRIS_ROOT)
mpv-mpris: $(mpv-mpris)

xwinwrap = $(XWINWRAP_ROOT)/xwinwrap
$(xwinwrap): $(XWINWRAP_ROOT)/.git
	$(MAKE) -C $(XWINWRAP_ROOT)
xwinwrap: $(xwinwrap)

ccls = $(CCLS_ROOT)/Release/ccls
$(ccls): $(CCLS_ROOT)/.git
	cd $(CCLS_ROOT) && \
		$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release && \
		$(CMAKE) --build Release
ccls: $(ccls)

gitflow: $(GITFLOW_ROOT)/.git
	$(MAKE) -C$(GITFLOW_ROOT) prefix=$(PREFIX) install

fzf = $(FZF_ROOT)/bin/fzf
$(fzf): $(FZF_ROOT)/.git
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
fzf: $(fzf)

coc = $(COC_ROOT)/extensions/package-lock.json
$(coc):
	cd $(COC_ROOT)/extensions && npm install
coc: $(coc)

$(submodules-deps) &:
	git submodule update --init --recursive
# Alternatively, to initialize individually (notice we are replacing /.git with an empty string):
# $(submodules-deps):
# 	git submodule update --init --recursive $(@:/.git=)
submodules: $(submodules-deps)

powerline = $(PYTHON_SITE_PACKAGES)/powerline-status.egg-link
$(powerline): $(POWERLINE_ROOT)/.git
	pip install --user --editable=$(POWERLINE_ROOT)
powerline: $(powerline)

grip = $(PYTHON_SITE_PACKAGES)/grip.egg-link
$(grip): $(GRIP_ROOT)/.git
	pip install --user --editable=$(GRIP_ROOT)
grip: $(grip)

dconf:
	@# dconf dump /desktop/ibus > ibus.dconf
	dconf load /desktop/ibus/ < ${DCONF}/ibus.dconf
	@# dconf dump /org/freedesktop/ibus/ > ibus-engine.dconf
	dconf load /org/freedesktop/ibus/ < ${DCONF}/ibus-engine.dconf # anthy should input hiragana by default

dirs = $(XDG_CONFIG_HOME) $(XDG_DATA_HOME) $(PREFIX)/bin
$(dirs):
	mkdir -p $@
dirs: $(dirs)

install: dirs gitflow powerline grip dconf
	stow -v home
	# Refresh fonts
	fc-cache -f

.PHONY: install coc fzf gitflow mpv-mpris xwinwrap ccls powerline grip dirs submodules dconf
