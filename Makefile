COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

HOME ?= ${HOME}
XDG_CONFIG_HOME ?= ${HOME}/.config
XDG_DATA_HOME ?= ${HOME}/.local/share
PREFIX ?= ${HOME}/.local

CMAKE := cmake

DEPS = deps
DCONF = dconf

MPV_MPRIS_ROOT = $(DEPS)/mpv-mpris
XWINWRAP_ROOT = $(DEPS)/xwinwrap
CCLS_ROOT = $(DEPS)/ccls
FIRACODE_ROOT = $(DEPS)/FiraCode
GITFLOW_ROOT = $(DEPS)/gitflow
ESLINT_D_ROOT = $(DEPS)/eslint_d
FZF_ROOT = $(DEPS)/fzf
FZY_ROOT = $(DEPS)/fzy
NERD_FONTS = $(FONTS)/NerdFontsSymbolsOnly
COURSIER_ROOT = $(DEPS)/coursier
METALS_ROOT = $(DEPS)/metals

ZEN_DIR := $(HOME)/.zen
ZEN_PROFILES_INI := $(ZEN_DIR)/profiles.ini
NATSUMI_BROWSER := $(DEPS)/natsumi-browser
NATSUMI_BROWSER_FILES := \
  userChrome.css \
  natsumi-config.css \
  natsumi \
  userContent.css

FONTS = home/.local/share/fonts
NVIM_DATA_DIRECTORY = home/.local/share/nvim
TREESITTER_ROOT = $(NVIM_DATA_DIRECTORY)/site/pack/default/start/nvim-treesitter
MASON_ROOT = $(NVIM_DATA_DIRECTORY)/mason
MASON_REGISTRY_ROOT = $(NVIM_DATA_DIRECTORY)/mason-registry
TELESCOPE_FZF_NATIVE_ROOT = $(NVIM_DATA_DIRECTORY)/site/pack/default/start/telescope-fzf-native.nvim
VIM_JSDOC_ROOT = home/.vim/pack/default/start/vim-jsdoc

submodules-paths = $(shell cat .gitmodules | grep "path =" | cut -d ' ' -f3)
submodules-deps = $(addsuffix /.git, $(submodules-paths))

helptags-paths = $(shell find $(NVIM_DATA_DIRECTORY)/site/pack/default/start -maxdepth 2 -mindepth 2 -type d -name doc)
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
$($1_head_file): $2/.git
endef

define mason_package
# sometimes the $1 argument does not match the bin name, as is the case with tree-sitter-cli (tree-sitter is the binary name)
$(eval $1_package_yaml = $(MASON_REGISTRY_ROOT)/packages/$1/package.yaml)
$(eval $1_target = $(MASON_ROOT)/bin/$(shell yq ".bin|to_entries[0].key" < $($1_package_yaml)))
# https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types
$($1_target): $($1_package_yaml) $(telescope-fzf-native) | dirs
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	( unset XDG_CONFIG_HOME && HOME=home nvim --headless -c "MasonInstall $1" -c q )
	$(if $(findstring true,$2),touch $$@,)
$1: $($1_target)
endef

.PHONY: all
all: mpv-mpris xwinwrap ccls fzf fzy telescope-fzf-native vim_jsdoc eslint_d helptags firacode nerd_fonts iosevka i3status treesitter

.PHONY: submodules
$(submodules-deps) &:
	git submodule update --init --recursive
# Alternatively, to initialize individually (notice we are replacing /.git with an empty string):
# $(submodules-deps):
# 	git submodule update --init --recursive $(@:/.git=)
submodules: $(submodules-deps)

.PHONY: mpv-mpris
mpv-mpris_target = $(MPV_MPRIS_ROOT)/mpris.so
$(eval $(call git_submodule,mpv-mpris,$(MPV_MPRIS_ROOT)))
$(mpv-mpris_target): $(mpv-mpris_head_file)
	$(MAKE) -C $(MPV_MPRIS_ROOT)
mpv-mpris: $(mpv-mpris_target)

.PHONY: xwinwrap
xwinwrap_target = $(XWINWRAP_ROOT)/xwinwrap
$(eval $(call git_submodule,xwinwrap,$(XWINWRAP_ROOT)))
$(xwinwrap_target): $(xwinwrap_head_file)
	$(MAKE) -C $(XWINWRAP_ROOT)
xwinwrap: $(xwinwrap_target)

i3status-config-template := home/.config/i3status/config.template
i3status-config          := home/.config/i3status/config
amd-cpu-temperature-path := /sys/class/hwmon/hwmon2/temp1_input

.PHONY: i3status
# Check if on amd
ifeq ($(wildcard $(amd-cpu-temperature-path)),)
cpu-temperature-device-file-path :=
else
cpu-temperature-device-file-path := path = \"$(amd-cpu-temperature-path)\"\n
endif
$(i3status-config): $(i3status-config-template)
	@awk ' \
		/^\s*cpu_temperature\s+[0-9]+\s*{/ { print; if ("$(cpu-temperature-device-file-path)" != "") printf "    $(cpu-temperature-device-file-path)"; next } \
		{ print }' \
		"$(i3status-config-template)" > "$(i3status-config)"
i3status: $(i3status-config)

.PHONY: ccls
ccls_target = $(CCLS_ROOT)/Release/ccls
$(eval $(call git_submodule,ccls,$(CCLS_ROOT)))
$(ccls_target): $(ccls_head_file)
	cd $(CCLS_ROOT) && \
		$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release && \
		$(CMAKE) --build Release
ccls: $(ccls_target)

nerdfonts_version = 3.4.0
nerdfonts_source = $(FONTS)/NerdFontsSymbolsOnly-$(nerdfonts_version).tar.xz
$(nerdfonts_source):
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v$(nerdfonts_version)/NerdFontsSymbolsOnly.tar.xz -O $(nerdfonts_source)

.PHONY: nerd_fonts
nerd_fonts_target = $(NERD_FONTS)/SymbolsNerdFont-Regular.ttf \
										$(NERD_FONTS)/SymbolsNerdFontMono-Regular.ttf
$(nerd_fonts_target) &: $(nerdfonts_source)
	tar xvJf $< --one-top-level=$(NERD_FONTS) -m
nerd_fonts: $(nerd_fonts_target)

.PHONY: firacode
firacode_target = $(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Regular.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Light.ttf \
									$(FIRACODE_ROOT)/distr/ttf/Fira\ Code/FiraCode-Bold.ttf
$(eval $(call git_submodule,firacode,$(FIRACODE_ROOT)))
$(firacode_target): $(firacode_head_file)
	cd $(FIRACODE_ROOT) && $(MAKE) # make -C does't work here
firacode: $(firacode_target)

.PHONY: iosevka
iosevka_version = 33.2.7
iosevka_source = $(FONTS)/SuperTTC-Iosevka-$(iosevka_version).zip
$(iosevka_source):
	wget https://github.com/be5invis/Iosevka/releases/download/v$(iosevka_version)/SuperTTC-Iosevka-$(iosevka_version).zip -P $(FONTS)
iosevka_target = $(FONTS)/Iosevka.ttc
$(iosevka_target): $(iosevka_source)
	unzip -o -d $(FONTS) $<
	touch $@
iosevka: $(iosevka_target)

.PHONY: coursier
coursier_version = 2.1.24
coursier_builder = $(COURSIER_ROOT)/coursier-builder-$(coursier_version)
$(coursier_builder):
	mkdir -p $(dir $(coursier_builder))
	wget https://github.com/coursier/coursier/releases/download/v$(coursier_version)/coursier -O $(coursier_builder)
	chmod +x $(coursier_builder)
coursier_target = $(COURSIER_ROOT)/coursier
$(coursier_target): $(coursier_builder)
	mkdir -p $(COURSIER_ROOT)/cache
	COURSIER_CACHE="$(COURSIER_ROOT)/cache" sh $(coursier_builder) bootstrap \
		       "io.get-coursier::coursier-cli:$(coursier_version)" \
		       --no-default \
		       -r central \
		       -r typesafe:ivy-releases \
		       -f -o "$(coursier_target)" \
		       --standalone
coursier: $(coursier_target)

.PHONY: metals
metals_version = 1.6.1
metals_target = $(METALS_ROOT)/metals-$(metals_version)
metals_bin = home/.local/bin/metals
$(metals_target): $(coursier_target)
	mkdir -p $(METALS_ROOT)
	$(coursier_target) bootstrap \
		--java-opt -XX:+UseG1GC \
		--java-opt -XX:+UseStringDeduplication  \
		--java-opt -Xss4m \
		--java-opt -Xms100m \
		org.scalameta:metals_2.13:$(metals_version) -o $(metals_target) -f
	chmod +x $(metals_target)
$(metals_bin): $(metals_target)
	ln -sf ../../../$(metals_target) $(metals_bin)
metals: $(metals_bin)

fzf = $(FZF_ROOT)/bin/fzf
$(eval $(call git_submodule,fzf,$(FZF_ROOT)))
$(fzf): $(fzf_head_file)
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
fzf: $(fzf)

.PHONY: fzy
fzy = $(FZY_ROOT)/fzy
$(eval $(call git_submodule,fzy,$(FZY_ROOT)))
$(fzy): $(fzy_head_file)
	$(MAKE) -C $(FZY_ROOT) clean # TODO: cannot rebuild without clean first
	$(MAKE) -C $(FZY_ROOT)
fzy: $(fzy)

.PHONY: telescope-fzf-native
telescope-fzf-native = $(TELESCOPE_FZF_NATIVE_ROOT)/build/libfzf.so
$(eval $(call git_submodule,telescope-fzf-native,$(TELESCOPE_FZF_NATIVE_ROOT)))
$(telescope-fzf-native): $(telescope-fzf-native_head_file)
	$(MAKE) -C $(TELESCOPE_FZF_NATIVE_ROOT)
telescope-fzf-native: $(telescope-fzf-native)

lsps = luacheck stylua prettier jsonlint json-lsp html-lsp css-lsp bash-language-server typescript-language-server vtsls kotlin-lsp kotlin-debug-adapter sqlls lua-language-server js-debug-adapter tree-sitter-cli
PHONY: $(lsps)
$(eval $(call mason_package,luacheck))
$(eval $(call mason_package,stylua,true))
$(eval $(call mason_package,prettier))
$(eval $(call mason_package,jsonlint))
$(eval $(call mason_package,json-lsp))
$(eval $(call mason_package,html-lsp))
$(eval $(call mason_package,css-lsp))
$(eval $(call mason_package,js-debug-adapter))
$(eval $(call mason_package,vtsls))
$(eval $(call mason_package,typescript-language-server))
$(eval $(call mason_package,bash-language-server))
$(eval $(call mason_package,kotlin-lsp,true))
$(eval $(call mason_package,kotlin-debug-adapter,true))
$(eval $(call mason_package,sqlls,true))
$(eval $(call mason_package,lua-language-server))
$(eval $(call mason_package,tree-sitter-cli,true))
# the mdate on kotlin-debug-adapter executable file dates back to 2021 - update it to avoid rebuilding

.PHONY: helptags
$(helptags)&: $(helptags-deps) $(telescope-fzf-native)
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	( unset XDG_CONFIG_HOME && HOME=home nvim --headless -c "helptags ALL" -c q )
helptags: $(helptags)

.PHONY: treesitter
# print in neovim prints to stderr
treesitter-langs = bash c cpp css graphql haskell html javascript json jsonc latex lua regex scala java svelte typescript yaml kotlin vim vimdoc sql markdown markdown_inline
treesitter-langs-params = $(subst $(SPACE),$(COMMA),$(foreach lang,$(treesitter-langs),'$(lang)'))
treesitter-targets = $(addprefix $(TREESITTER_ROOT)/parser/, $(addsuffix .so, $(treesitter-langs)))
# installing treesitter requires that all neovim config has been installed into rtp (home task)
# also, some parsers depend on the tree-sitter-cli (latex), so make sure it is installed too
$(treesitter-targets) &: $(TREESITTER_ROOT)/lockfile.json $(telescope-fzf-native) $(tree-sitter-cli_target)
	@# https://github.com/nvim-treesitter/nvim-treesitter/issues/2533
	@# rm -f $(treesitter-targets)
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	( unset XDG_CONFIG_HOME && HOME=home nvim --headless \
			 -c "lua require('nvim-treesitter.install').ensure_installed_sync({ $(treesitter-langs-params) })" \
			 -c "lua require('nvim-treesitter.install').update({ with_sync = true })({ $(treesitter-langs-params) })" \
			 -c q )
	touch $(treesitter-targets)
	@# nvim --headless +TSUpdateSync +qa exits immediately
treesitter: $(treesitter-targets)

.PHONY: eslint_d
eslint_d = $(ESLINT_D_ROOT)/node_modules
$(eval $(call git_submodule,eslint_d,$(ESLINT_D_ROOT)))
$(eslint_d): $(eslint_d_head_file)
	npm --prefix $(ESLINT_D_ROOT) ci --omit=dev --ignore-scripts
eslint_d: $(eslint_d)

.PHONY: vim_jsdoc
vim_jsdoc = $(VIM_JSDOC_ROOT)/lib/lehre
$(eval $(call git_submodule,vim_jsdoc,$(VIM_JSDOC_ROOT)))
$(vim_jsdoc): $(vim_jsdoc_head_file)
	$(MAKE) -C$(VIM_JSDOC_ROOT) clean && $(MAKE) -C$(VIM_JSDOC_ROOT) install
vim_jsdoc: $(vim_jsdoc)

.PHONY: gitflow
$(eval $(call git_submodule,gitflow,$(GITFLOW_ROOT)))
gitflow = $(PREFIX)/bin/git-flow
$(gitflow): $(gitflow_head_file)
	$(MAKE) -C$(GITFLOW_ROOT) prefix=$(PREFIX) install
gitflow: $(gitflow)

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
home: | dirs
	stow -v home -t $(HOME)

.PHONY: fonts
fonts: home
	@# refresh fonts
	fc-cache -f

ifeq ($(wildcard $(ZEN_PROFILES_INI)),)
ZEN_PROFILE_PAIRS :=
else
# assume that + won't be used in the path to the profile, because makefile doesn't handle spaces in paths
ZEN_PROFILE_PAIRS := $(shell awk -F= '\
	function normalize(s) { gsub(" ", "_", s); return tolower(s); } \
	/^\[Profile[0-9]+\]/{in_profile=1; name=""; path=""; next} \
	/^\[/{in_profile=0} \
	in_profile && $$1=="Name"{name=normalize($$2)} \
	in_profile && $$1=="Path"{path=$$2} \
	name && path {gsub(" ", "+", path); print name ":" path; name=""; path=""} \
' "$(ZEN_PROFILES_INI)")
endif

# Generate make targets like zen-natsumi-personal
ZEN_PROFILE_TASKS := $(foreach pair,$(ZEN_PROFILE_PAIRS),zen-natsumi-$(firstword $(subst :, ,$(pair))))

$(foreach pair,$(ZEN_PROFILE_PAIRS),\
  $(eval ZEN_PROFILE_NAME := $(firstword $(subst :, ,$(pair))))\
  $(eval ZEN_PROFILE_PATH := $(subst +,\ ,$(word 2,$(subst :, ,$(pair)))))\
  $(eval $(ZEN_PROFILE_NAME)-files := $(foreach file,$(NATSUMI_BROWSER_FILES),$(ZEN_DIR)/$(ZEN_PROFILE_PATH)/chrome/$(file)))\
  $(eval zen-natsumi-$(ZEN_PROFILE_NAME): $($(ZEN_PROFILE_NAME)-files))\
  $(eval $($(ZEN_PROFILE_NAME)-files) &: ; \
    @echo "Setting up profile: $(ZEN_PROFILE_NAME) at path: $(ZEN_PROFILE_PATH)" && \
    mkdir -p $(ZEN_DIR)/$(ZEN_PROFILE_PATH)/chrome && \
    $(foreach file,$(NATSUMI_BROWSER_FILES), \
      ln -sf "$(abspath $(NATSUMI_BROWSER))/$(file)" $(ZEN_DIR)/$(ZEN_PROFILE_PATH)/chrome/$(file); \
    )\
  )\
  $(eval .PHONY: zen-natsumi-$(ZEN_PROFILE_NAME))\
)

.PHONY: install
install: home fonts gitflow dconf coursier metals $(lsps) $(ZEN_PROFILE_TASKS)

.PHONY: test-build
test-build:
	[ -e $(mpv-mpris_target) ] || exit 1
	[ -e $(i3status-config) ] || exit 1
	[ -x $(tree-sitter-cli_target) ] || exit 1

.PHONY: test
test:
	# test neovim
	[ -x $(lua-language-server_target) ] || exit 1
	# make sure neovim doesn't output errors
	[ -z "$$(nvim --headless +qa 2>&1)" ] || exit 1
