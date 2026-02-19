.PHONY: test-build
test-build:
	@missing=0; \
	$(foreach t,$(TARGETS), \
		if [ -z "$($(t)_target)" ]; then \
			echo "Missing target: $(t)"; \
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

.PHONY: test-ibus-config
test-ibus-config:
	@dconf dump /desktop/ibus/ | cmp ${DCONF}/ibus.dconf
	@dconf dump /org/freedesktop/ibus/ | cmp ${DCONF}/ibus-engine.dconf

.PHONY: test-neovim
test-neovim:
	# make sure neovim doesn't output errors
	[ -z "$$(nvim --headless +qa 2>&1)" ] || exit 1

.PHONY: test
test: check-submodule-mismatch test-ibus-config test-neovim
