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

all: mpv-mpris xwinwrap ccls fzf coc

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

fzf = $(FZF_ROOT)/bin/fzf
$(eval $(call git_submodule,fzf,fzf,$(FZF_ROOT)))
$(fzf): $(fzf_head_file)
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
fzf: $(fzf)

coc = $(COC_ROOT)/extensions/package-lock.json
$(coc):
	cd $(COC_ROOT)/extensions && npm install
coc: $(coc)

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

dirs = $(XDG_CONFIG_HOME) $(XDG_DATA_HOME) $(PREFIX)/bin
$(dirs):
	mkdir -p $@
dirs: $(dirs)

home:
	stow -v home

fonts:
	# Refresh fonts
	fc-cache -f

install: dirs gitflow powerline grip dconf home fonts

.PHONY: install coc fzf gitflow mpv-mpris xwinwrap ccls powerline grip dirs submodules dconf home fonts
