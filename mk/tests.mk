define test_targets
@missing=0; \
$(foreach t,$(1), \
	if [ -z "$($(t)_target)" ]; then \
		echo "Missing target variable: $(t)_target"; \
		missing=1; \
	fi; \
	for f in $($(t)_target); do \
		if [ ! -e "$$f" ]; then \
			echo "Missing: $(t) - $$f"; \
			missing=1; \
		else \
			echo "Found: $(t) - $$f"; \
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
	@echo "✓ no .gitmodules path mismatch"

.PHONY: test-ibus-config
test-ibus-config:
	@dconf dump /desktop/ibus/ | cmp -s - ${DCONF}/ibus.dconf
	@dconf dump /org/freedesktop/ibus/ | cmp -s - ${DCONF}/ibus-engine.dconf
	@echo "✓ ibus configuration present"

test-cron:
	@if ! crontab -l 2>/dev/null | cmp -s - $(CRONTAB_SRC); then \
		echo "❌ cron contents do not match"; \
		exit 1; \
	fi
	@echo "✓ crontab matches"

.PHONY: test-dirs
test-dirs:
	@missing=0; \
	for dir in $(dirs); do \
		if [ ! -d "$$dir" ]; then \
			echo "❌ dir $$dir does not exist or is not a directory"; \
			missing=1; \
		else \
			echo "✅ dir $$dir exists"; \
		fi; \
	done; \
	exit $$missing

.PHONY: test-fonts
test-fonts:
	@fc-list | grep -qi Iosevka.ttc || { \
		echo "❌ Iosevka not found in fontconfig cache"; \
		exit 1; \
	}
	@echo "✓ Iosevka present"

.PHONY: test-neovim
test-neovim:
	@# make sure neovim doesn't output errors
	@[ -z "$$(nvim --headless +qa 2>&1)" ] || exit 1
	@echo "✓ neovim boots cleanly"

.PHONY: test
test: check-submodule-mismatch test-dirs test-install-targets test-ibus-config test-cron test-fonts test-neovim
