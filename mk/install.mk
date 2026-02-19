$(eval $(call has_cmd,dconf))
$(eval $(call has_cmd,stow))
$(eval $(call has_cmd,crontab))
$(eval $(call has_cmd,fc-cache))

ifdef PIPX_LOCAL_VENVS
qmk_cli = $(PIPX_LOCAL_VENVS)/qmk/bin/qmk
else
qmk_cli = $(PYTHON_SITE_PACKAGES)/qmk.egg-link
endif
$(eval $(call git_submodule,qmk_cli,$(QMK_CLI_ROOT)))
$(qmk_cli): $(qmk_cli_head_file)
ifdef PIPX_LOCAL_VENVS
	[ -e $(qmk_cli) ] && pipx upgrade qmk || pipx install $(QMK_CLI_ROOT)
else
	pip install --user --editable=$(QMK_CLI_ROOT)
endif
qmk_cli: $(qmk_cli)

ifdef PIPX_LOCAL_VENVS
zmk_cli = $(PIPX_LOCAL_VENVS)/zmk/bin/zmk
else
zmk_cli = $(PYTHON_SITE_PACKAGES)/zmk.egg-link
endif
$(eval $(call git_submodule,zmk_cli,$(ZMK_CLI_ROOT)))
$(zmk_cli): $(zmk_cli_head_file)
ifdef PIPX_LOCAL_VENVS
	[ -e $(zmk_cli) ] && pipx upgrade zmk || pipx install $(ZMK_CLI_ROOT)
else
	pip install --user --editable=$(ZMK_CLI_ROOT)
endif
zmk_cli: $(zmk_cli)

.PHONY: gitflow
$(eval $(call git_submodule,gitflow,$(GITFLOW_ROOT)))
gitflow_target = $(PREFIX)/bin/git-flow
$(gitflow_target): $(gitflow_head_file)
	$(MAKE) -C$(GITFLOW_ROOT) prefix=$(PREFIX) install
gitflow: $(gitflow_target)

logrotate_target = $(LOGROTATE_DIR)/xsession.conf
$(logrotate_target): $(LOGROTATE_DIR)/xsession.conf.in
	sed 's|@XDG_STATE_HOME@|$(XDG_STATE_HOME)|g' $< > $@
logrotate: $(logrotate_target)

CRONTAB_STAMP := .crontab.installed
$(CRONTAB_STAMP): $(CRONTAB_SRC)
	$(call require,crontab)
	@if crontab -l 2>/dev/null | cmp -s - $(CRONTAB_SRC); then \
		touch $@; \
	else \
		crontab $(CRONTAB_SRC); \
		touch $@; \
	fi
cron: $(CRONTAB_STAMP)

.PHONY: dconf
dconf:
	$(call require,dconf)
# Check if the variable is set AND if the socket path actually exists
ifneq ($(DBUS_SESSION_BUS_ADDRESS),)
	@# dconf dump /desktop/ibus/ > ibus.dconf
	@dconf load /desktop/ibus/ < ${DCONF}/ibus.dconf
	@# dconf dump /org/freedesktop/ibus/ > ibus-engine.dconf
	@dconf load /org/freedesktop/ibus/ < ${DCONF}/ibus-engine.dconf # anthy should input hiragana by default
else
	@echo "⚠️  D-Bus session address not found in environment. Skipping dconf load."
	@exit 1
endif

.PHONY: dirs
dirs = $(XDG_CONFIG_HOME) $(XDG_DATA_HOME) $(XDG_DATA_HOME)/icons $(XDG_DATA_HOME)/themes $(BINDIR) $(LIBEXECDIR) $(HOME)/.luarocks $(XDG_CONFIG_HOME)/logrotate
$(dirs):
	mkdir -p $@
dirs: $(dirs)

# By default stow stows to `../$(pwd)`, so in CI we need to be more precise
.PHONY: home
home: | dirs
	$(call require,stow)
	stow -v home -t $(HOME)

.PHONY: fonts
fonts: home
	$(call require,fc-cache)
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
ZEN_PROFILE_TASKS := $(foreach pair,$(ZEN_PROFILE_PAIRS),zen-catppuccin-$(firstword $(subst :, ,$(pair))))

$(foreach pair,$(ZEN_PROFILE_PAIRS),\
  $(eval ZEN_PROFILE_NAME := $(firstword $(subst :, ,$(pair))))\
  $(eval ZEN_PROFILE_PATH := $(subst +, ,$(word 2,$(subst :, ,$(pair)))))\
  $(eval ZEN_PROFILE_PATH_ESCAPED := $(subst +,\ ,$(word 2,$(subst :, ,$(pair)))))\
  $(eval $(ZEN_PROFILE_NAME)-files := $(foreach file,$(ZEN_CATPPUCCIN_FILES),$(ZEN_DIR)/$(ZEN_PROFILE_PATH_ESCAPED)/chrome/$(file)))\
  $(eval zen-catppuccin-$(ZEN_PROFILE_NAME): $($(ZEN_PROFILE_NAME)-files))\
  $(eval $($(ZEN_PROFILE_NAME)-files) &: ; \
    @echo "Setting up profile: $(ZEN_PROFILE_NAME) at path: $(ZEN_PROFILE_PATH)" && \
    mkdir -p "$(ZEN_DIR)/$(ZEN_PROFILE_PATH)/chrome" && \
    $(foreach file,$(ZEN_CATPPUCCIN_FILES), \
      ln -sf "$(abspath $(ZEN_CATPPUCCIN))/$(file)" "$(ZEN_DIR)/$(ZEN_PROFILE_PATH)/chrome/$(file)"; \
    )\
  )\
  $(eval .PHONY: zen-catppuccin-$(ZEN_PROFILE_NAME))\
)

.PHONY: install
install: home fonts gitflow dconf qmk_cli zmk_cli cron $(ZEN_PROFILE_TASKS)
