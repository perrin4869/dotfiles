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
FIRACODE_ROOT = $(DEPS)/FiraCode
SPOT_ROOT = $(DEPS)/spot
POWERLINE_ROOT = $(DEPS)/powerline
GRIP_ROOT = $(DEPS)/grip
GITFLOW_ROOT = $(DEPS)/gitflow
VSCODE_NODE_DEBUG2_ROOT = $(DEPS)/vscode-node-debug2
FZF_ROOT = $(DEPS)/fzf
FZY_ROOT = $(DEPS)/fzy
TELESCOPE_FZF_NATIVE_ROOT = $(XDG_DATA_HOME)/nvim/site/pack/default/start/telescope-fzf-native.nvim
VIM_JSDOC_ROOT = ${HOME}/.vim/pack/default/start/vim-jsdoc
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

all: mpv-mpris xwinwrap ccls fzf fzy telescope-fzf-native coc vscode_node_debug2 vim_jsdoc

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

firacode_target = $(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Regular.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Light.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Bold.ttf
$(eval $(call git_submodule,FiraCode,deps/FiraCode,$(FIRACODE_ROOT)))
$(firacode_target): $(firacode_head_file)
	cd $(FIRACODE_ROOT) && $(MAKE) # make -C does't work here
firacode: $(firacode_target)

spot_target = $(PREFIX)/bin/spot
$(eval $(call git_submodule,spot,deps/spot,$(SPOT_ROOT)))
$(spot_target): $(spot_head_file)
	cd $(SPOT_ROOT) && \
		meson target -Dbuildtype=release -Doffline=false --prefix=$(PREFIX) && \
		ninja install -C target
spot: $(spot_target)

fzf = $(FZF_ROOT)/bin/fzf
$(eval $(call git_submodule,fzf,fzf,$(FZF_ROOT)))
$(fzf): $(fzf_head_file)
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
fzf: $(fzf)

fzy = $(FZF_ROOT)/bin/fzy
$(eval $(call git_submodule,fzy,deps/fzy,$(FZY_ROOT)))
$(fzy): $(fzy_head_file)
	$(MAKE) -C $(FZY_ROOT)
fzy: $(fzy)

TELESCOPE_FZF_NATIVE_MODULE_PATH=home/.local/share/nvim/site/pack/default/start/telescope-fzf-native.nvim
telescope-fzf-native = $(TELESCOPE_FZF_NATIVE_ROOT)/build/libfzf.so
$(eval $(call git_submodule,telescope-fzf-native,$(TELESCOPE_FZF_NATIVE_MODULE_PATH),$(TELESCOPE_FZF_NATIVE_ROOT)))
$(telescope-fzf-native): $(telescope-fzf-native_head_file)
	$(MAKE) -C $(TELESCOPE_FZF_NATIVE_ROOT)
telescope-fzf-native: $(telescope-fzf-native)

coc = $(COC_ROOT)/extensions/package-lock.json
$(coc):
	cd $(COC_ROOT)/extensions && npm install
coc: $(coc)

vscode_node_debug2 = $(VSCODE_NODE_DEBUG2_ROOT)/out/src/nodeDebug.js
$(eval $(call git_submodule,vscode_node_debug2,deps/vscode-node-debug2,$(VSCODE_NODE_DEBUG2_ROOT)))
$(vscode_node_debug2): $(vscode_node_debug2_head_file)
	cd $(VSCODE_NODE_DEBUG2_ROOT) && npm ci && gulp build
vscode_node_debug2: $(vscode_node_debug2)

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

home: dirs
	stow -v home

fonts: home
	# Refresh fonts
	fc-cache -f

install: home fonts spot gitflow powerline grip dconf

.PHONY: install coc fzf gitflow mpv-mpris xwinwrap ccls powerline grip dirs submodules dconf home fonts
