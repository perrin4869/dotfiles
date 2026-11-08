FAIL := ❌
PASS := ✅

define test_targets
@missing=0; \
$(foreach t,$(1), \
	if [ -z "$($(t)_target)" ]; then \
		echo "$(FAIL) Missing target variable: $(t)_target"; \
		missing=1; \
	fi; \
	for f in $(call escape_par,$($(t)_target)); do \
		if [ ! -e "$$f" ]; then \
			echo "$(FAIL) Missing: $(t) - $$f"; \
			missing=1; \
		else \
			echo "$(PASS) Found: $(t) - $$f"; \
		fi; \
	done; ) \
exit $$missing
endef

.PHONY: test-build
test-build: $(TARGETS)
	$(call test_targets,$^)

.PHONY: test-install-targets
test-install-targets: $(INSTALL_TARGETS)
	$(call test_targets,$^)

.PHONY: check-submodule-mismatch
check-submodule-mismatch:
	@mismatch=0; \
	while read -r key path; do \
		name=$$(echo "$$key" | cut -d. -f2- | rev | cut -d. -f2- | rev); \
		if [ "$$name" != "$$path" ]; then \
			echo "Mismatch: Name='$$name' != Path='$$path'"; \
			mismatch=1; \
		fi; \
	done < <(git config --file .gitmodules --get-regexp '\.path'); \
	if [ "$$mismatch" -ne 0 ]; then exit 1; fi
	@echo "$(PASS) no .gitmodules path mismatch"

.PHONY: test-ibus-config
test-ibus-config:
	@dconf dump /desktop/ibus/ | cmp -s - ${DCONF}/ibus.dconf
	@dconf dump /org/freedesktop/ibus/ | cmp -s - ${DCONF}/ibus-engine.dconf
	@echo "$(PASS) ibus configuration present"

test-cron:
	@if ! crontab -l 2>/dev/null | cmp -s - $(CRONTAB_SRC); then \
		echo "$(FAIL) cron contents do not match"; \
		exit 1; \
	fi
	@echo "$(PASS) crontab matches"

.PHONY: test-dirs
test-dirs:
	@missing=0; \
	for dir in $(dirs); do \
		if [ ! -d "$$dir" ]; then \
			echo "$(FAIL) dir $$dir does not exist or is not a directory"; \
			missing=1; \
		else \
			echo "$(PASS) dir $$dir exists"; \
		fi; \
	done; \
	exit $$missing

.PHONY: test-fonts
test-fonts:
	@fc-list | grep -qi Iosevka.ttc || { \
		echo "$(FAIL) Iosevka not found in fontconfig cache"; \
		exit 1; \
	}
	@echo "$(PASS) Iosevka present"

.PHONY: test-neovim
test-neovim:
	@# make sure neovim doesn't output errors
	@err=$$(NVIM_NOEXRC=1 nvim --headless +qa 2>&1); \
	if [ -n "$$err" ]; then \
	    echo "$$err"; exit 1; \
	else \
	    echo "$(PASS) neovim boots cleanly"; \
	fi

.PHONY: test-neovim-cmds
test-neovim-cmds:
	@NVIM_NOEXRC=1 nvim --headless --cmd 'luafile $(UTILS)/test_nvim_cmds.lua' \
		&& echo "$(PASS) lazy-loaded commands match their plugins"

.PHONY: test-nvim-spec
# busted and nlua stay in ./.luarocks (luarocks init --local), never installed system-wide
test-nvim-spec:
	$(call require,luarocks)
	@test -f .luarocks/config-5.1.lua || luarocks init --local --lua-version 5.1
	@eval "$$(luarocks path)" && luarocks test --prepare && echo "$(PASS) the nvim specs pass"

.PHONY: test-lua-types
# .emmyrc.check.json lists the library that lazydev provides per file in the editor; with HOME set to
# the repo's home, Neovim reports this checkout's pack dir rather than the installed one
test-lua-types: $(emmylua_check_target)
	@eval "$$(unset XDG_DATA_HOME && HOME=$(CURDIR)/home nvim -l $(UTILS)/lua_check_paths.lua)" && \
		$(emmylua_check_target) home/.config/nvim -c .emmyrc.check.json --severity warn --warnings-as-errors \
		&& echo "$(PASS) emmylua_check finds no type problems"

.PHONY: test-pi
test-pi:
	@$(UTILS)/test_pi $(abspath $(pi_target)) && echo "$(PASS) pi starts cleanly with its packages"

.PHONY: test
test: \
	check-submodule-mismatch \
	test-dirs \
	test-install-targets \
	test-ibus-config \
	test-cron \
	test-fonts \
	test-neovim \
	test-neovim-cmds \
	test-nvim-spec \
	test-lua-types \
	test-pi
