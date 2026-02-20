define mason_package
# sometimes the $1 argument does not match the bin name, as is the case with tree-sitter-cli (tree-sitter is the binary name)
$(eval $1_package_yaml = $(MASON_REGISTRY_ROOT)/packages/$1/package.yaml)
$(eval $1_target = $(MASON_ROOT)/bin/$(shell yq ".bin|to_entries[0].key" < $($1_package_yaml)))
# https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types
$($1_target): $($1_package_yaml) | dirs
	$(call require,nvim)
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	@# avoid needing telescope-fzf-native built by disabling telescope
	( unset XDG_CONFIG_HOME && HOME=home DEFER_DISABLE_TELESCOPE=true nvim --headless -c "MasonInstall $1" -c q )
	$(if $(findstring true,$2),touch $$@,)
$1: $($1_target)
endef

submodules_paths = $(shell cat .gitmodules | grep "path =" | cut -d ' ' -f3)
submodules_target = $(addsuffix /.git, $(submodules_paths))
$(submodules_target) &:
	$(call require,git)
	git submodule update --init --recursive
# Alternatively, to initialize individually (notice we are replacing /.git with an empty string):
# $(submodules_target):
# 	git submodule update --init --recursive $(@:/.git=)

.PHONY: submodules
submodules:
	$(call require,git)
	git submodule update --init --recursive

.PHONY: mpv-mpris
mpv-mpris_target = $(MPV_MPRIS_ROOT)/mpris.so
$(eval $(call git_submodule,mpv-mpris,$(MPV_MPRIS_ROOT)))
$(mpv-mpris_target): $(mpv-mpris_head_file)
	$(MAKE) -C $(MPV_MPRIS_ROOT)
	@touch $(mpv-mpris_target)
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
	$(call require,awk)
	@awk ' \
		/^\s*cpu_temperature\s+[0-9]+\s*{/ { print; if ("$(cpu-temperature-device-file-path)" != "") printf "    $(cpu-temperature-device-file-path)"; next } \
		{ print }' \
		"$(i3status-config-template)" > "$(i3status-config)"
i3status_target = $(i3status-config)
i3status: $(i3status_target)

.PHONY: ccls
ccls_target = $(CCLS_ROOT)/Release/ccls
$(eval $(call git_submodule,ccls,$(CCLS_ROOT)))
$(ccls_target): $(ccls_head_file)
	$(call require,$(CMAKE))
	cd $(CCLS_ROOT) && \
		$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release && \
		$(CMAKE) --build Release
ccls: $(ccls_target)

nerdfonts_version = 3.4.0
nerdfonts_source = $(FONTS)/NerdFontsSymbolsOnly-$(nerdfonts_version).tar.xz
$(nerdfonts_source):
	$(call require,wget)
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v$(nerdfonts_version)/NerdFontsSymbolsOnly.tar.xz -O $(nerdfonts_source)

.PHONY: nerd_fonts
nerd_fonts_target = $(NERD_FONTS)/SymbolsNerdFont-Regular.ttf $(NERD_FONTS)/SymbolsNerdFontMono-Regular.ttf
$(nerd_fonts_target) &: $(nerdfonts_source)
	tar xvJf $< --one-top-level=$(NERD_FONTS) -m
nerd_fonts: $(nerd_fonts_target)

.PHONY: iosevka
iosevka_version = 34.1.0
iosevka_source = $(FONTS)/SuperTTC-Iosevka-$(iosevka_version).zip
$(iosevka_source):
	$(call require,wget)
	wget https://github.com/be5invis/Iosevka/releases/download/v$(iosevka_version)/SuperTTC-Iosevka-$(iosevka_version).zip -P $(FONTS)
iosevka_target = $(FONTS)/Iosevka.ttc
$(iosevka_target): $(iosevka_source)
	$(call require,unzip)
	unzip -o -d $(FONTS) $<
	@touch $@
iosevka: $(iosevka_target)

.PHONY: carapace
carapace_version = 1.6.2
CP := )
carapace_arch = $(shell case $$(uname -m) in \
	x86_64$(CP) echo amd64 ;; \
	i386|i686$(CP) echo 386 ;; \
	aarch64|arm64$(CP) echo arm64 ;; \
	*$(CP) echo unknown ;; \
esac)
carapace_archive = carapace-bin_$(carapace_version)_linux_$(carapace_arch).tar.gz
$(DEPS)/$(carapace_archive):
	$(call require,wget)
	wget https://github.com/carapace-sh/carapace-bin/releases/download/v$(carapace_version)/$(carapace_archive) -P $(DEPS)
carapace_target = $(DEPS)/carapace/carapace
$(carapace_target): $(DEPS)/$(carapace_archive)
	mkdir -p $(DEPS)/carapace
	tar xvzf $< -C $(DEPS)/carapace
	@touch $@
carapace: $(carapace_target)

.PHONY: atuin
atuin_target = $(ATUIN_ROOT)/target/release/atuin
$(eval $(call git_submodule,atuin,$(ATUIN_ROOT)))
$(atuin_target): $(atuin_head_file)
	$(call require,cargo)
	cargo build --manifest-path $(ATUIN_ROOT)/crates/atuin/Cargo.toml --release
	@touch $(atuin_target)
atuin: $(atuin_target)

.PHONY: coursier
coursier_version = 2.1.24
coursier_builder = $(COURSIER_ROOT)/coursier-builder-$(coursier_version)
$(coursier_builder):
	$(call require,wget)
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
metals_version = 1.6.5
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

fzf_target = $(FZF_ROOT)/bin/fzf
$(eval $(call git_submodule,fzf,$(FZF_ROOT)))
$(fzf_target): $(fzf_head_file)
	@# Officially:
	@# $DEPS_DIR/fzf/install --all
	@# Manually download executable
	$(FZF_ROOT)/install --no-update-rc --no-bash --no-zsh --no-completion --no-key-bindings
	@touch $(fzf_target)
fzf: $(fzf_target)

.PHONY: fzy
fzy_target = $(FZY_ROOT)/fzy
$(eval $(call git_submodule,fzy,$(FZY_ROOT)))
$(fzy_target): $(fzy_head_file)
	$(MAKE) -C $(FZY_ROOT) clean # TODO: cannot rebuild without clean first
	$(MAKE) -C $(FZY_ROOT)
fzy: $(fzy_target)

.PHONY: telescope-fzf-native
telescope-fzf-native_target = $(TELESCOPE_FZF_NATIVE_ROOT)/build/libfzf.so
$(eval $(call git_submodule,telescope-fzf-native,$(TELESCOPE_FZF_NATIVE_ROOT)))
$(telescope-fzf-native_target): $(telescope-fzf-native_head_file)
	$(MAKE) -C $(TELESCOPE_FZF_NATIVE_ROOT)
	@touch $(telescope-fzf-native_target)
telescope-fzf-native: $(telescope-fzf-native_target)

lsps = luacheck stylua prettier jsonlint json-lsp html-lsp css-lsp bash-language-server typescript-language-server vtsls tsgo kotlin-lsp kotlin-debug-adapter sqlls lua-language-server js-debug-adapter tree-sitter-cli
.PHONY: $(lsps)
$(eval $(call mason_package,luacheck))
$(eval $(call mason_package,stylua,true))
$(eval $(call mason_package,prettier))
$(eval $(call mason_package,jsonlint))
$(eval $(call mason_package,json-lsp))
$(eval $(call mason_package,html-lsp))
$(eval $(call mason_package,css-lsp))
$(eval $(call mason_package,js-debug-adapter))
$(eval $(call mason_package,vtsls)) # TODO: remove once tsgo is stable
$(eval $(call mason_package,typescript-language-server)) # TODO: remove once tsgo is stable
$(eval $(call mason_package,tsgo))
$(eval $(call mason_package,bash-language-server))
$(eval $(call mason_package,kotlin-lsp,true))
$(eval $(call mason_package,kotlin-debug-adapter,true))
$(eval $(call mason_package,sqlls,true))
$(eval $(call mason_package,lua-language-server))
$(eval $(call mason_package,tree-sitter-cli,true))
# the mdate on kotlin-debug-adapter executable file dates back to 2021 - update it to avoid rebuilding

.PHONY: helptags
helptags-paths = $(shell find $(NVIM_DATA_DIRECTORY)/site/pack/default/start $(NVIM_DATA_DIRECTORY)/site/pack/default/opt -maxdepth 2 -mindepth 2 -type d -name doc)
helptags-deps = $(addsuffix /*.txt, $(helptags-paths))
helptags_target = $(addsuffix /tags, $(helptags-paths))
$(helptags_target)&: $(helptags-deps) $(telescope-fzf-native)
	$(call require,nvim)
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	( unset XDG_CONFIG_HOME && HOME=home nvim --headless \
			-c "set runtimepath+=$(NVIM_DATA_DIRECTORY)/site/pack/default/opt/*" \
			-c "helptags ALL" -c q )
helptags: $(helptags_target)

.PHONY: treesitter
# print in neovim prints to stderr
treesitter-langs = bash c cpp css graphql haskell html javascript json jsonc latex lua regex scala java svelte typescript yaml kotlin vim vimdoc sql markdown markdown_inline
treesitter-langs-params = $(subst $(SPACE),$(COMMA),$(foreach lang,$(treesitter-langs),'$(lang)'))
treesitter_target = $(addprefix $(TREESITTER_PARSERS)/, $(addsuffix .so, $(treesitter-langs)))
# installing treesitter requires that all neovim config has been installed into rtp (home task)
# also, some parsers depend on the tree-sitter-cli (latex), so make sure it is installed too
$(treesitter_target) &: $(TREESITTER_ROOT)/lua/nvim-treesitter/parsers.lua $(telescope-fzf-native) $(tree-sitter-cli_target)
	$(call require,nvim)
	@# https://github.com/nvim-treesitter/nvim-treesitter/issues/2533
	@# rm -f $(treesitter-targets)
	@# XDG_CONFIG_HOME may be set and take precedence over HOME
	( unset XDG_CONFIG_HOME && HOME=home nvim --headless \
			 -c "lua require('nvim-treesitter').install({ $(treesitter-langs-params) }):wait(30000000)" \
			 -c "lua require('nvim-treesitter').update({ $(treesitter-langs-params) }):wait(30000000)" \
			 -c q )
	@touch $(treesitter_target)
treesitter: $(treesitter_target)

.PHONY: eslint_d
eslint_d_target = $(ESLINT_D_ROOT)/node_modules
$(eval $(call git_submodule,eslint_d,$(ESLINT_D_ROOT)))
$(eslint_d_target): $(eslint_d_head_file)
	npm --prefix $(ESLINT_D_ROOT) ci --omit=dev --ignore-scripts
eslint_d: $(eslint_d_target)

.PHONY: difftastic_nvim
difftastic_nvim_target = $(NVIM_DIFFTASTIC_ROOT)/target/release/libdifftastic_nvim.so
$(eval $(call git_submodule,difftastic_nvim,$(NVIM_DIFFTASTIC_ROOT)))
$(difftastic_nvim_target): $(difftastic_nvim_head_file)
	$(call require,cargo)
	cd $(NVIM_DIFFTASTIC_ROOT) && cargo build --release
	@touch $(difftastic_nvim_target)
difftastic_nvim: $(difftastic_nvim_target)

.PHONY: vim_jsdoc
vim_jsdoc_target = $(VIM_JSDOC_ROOT)/lib/lehre
$(eval $(call git_submodule,vim_jsdoc,$(VIM_JSDOC_ROOT)))
$(vim_jsdoc_target): $(vim_jsdoc_head_file)
	$(MAKE) -C$(VIM_JSDOC_ROOT) clean && $(MAKE) -C$(VIM_JSDOC_ROOT) install
	@touch $(vim_jsdoc_target)
	git -C $(VIM_JSDOC_ROOT) restore lib/yarn.lock
vim_jsdoc: $(vim_jsdoc_target)

logrotate_target = $(LOGROTATE_DIR)/xsession.conf
$(logrotate_target): $(LOGROTATE_DIR)/xsession.conf.in
	sed 's|@XDG_STATE_HOME@|$(XDG_STATE_HOME)|g' $< > $@
logrotate: $(logrotate_target)

# --keep-going: -k ensures independent branches continue even if one fails.
# MAKEFLAGS += -k
TARGETS = \
	mpv-mpris \
	xwinwrap \
	ccls \
	fzf \
	fzy \
	telescope-fzf-native \
	vim_jsdoc \
	eslint_d \
	helptags \
	nerd_fonts \
	iosevka \
	carapace \
	i3status \
	treesitter \
	atuin \
	coursier \
	metals \
	difftastic_nvim \
	logrotate \
	$(lsps)

.PHONY: build
$(TARGETS): | $(submodules_target) # order-only dependency
build: $(TARGETS)
