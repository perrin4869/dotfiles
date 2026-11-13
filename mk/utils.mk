COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

# Accept as an argument the submodule relative to .git/modules directory
# $(call git_submodule,variable_prefix,module_path,repo_path)
define git_submodule
$(eval $1_head = $(shell cat .git/modules/$2/HEAD))
$(eval $1_head_file = $(if $(findstring ref:,$($1_head)),\
	.git/modules/$2/$(lastword $($1_head)),\
	.git/modules/$2/HEAD))
endef

define require
@if ! command -v $(1) >/dev/null 2>&1; then \
    echo "Skipping $@: missing dependency: $(1)"; \
    exit 0; \
fi
endef

# A PyPI package installed through pipx, or through pip's --user layout where pipx is unavailable.
# $(1) names both the pipx venv and the installed binary, $(2) is the spec to install (extras included).
# $(call pipx_package,name,spec)
define pipx_package
ifeq ($(strip $(PIPX_LOCAL_VENVS)),)
$1_target = $(BINDIR)/$1
$$($1_target):
	$(call require,pip)
	pip install --user $(2)
else
$1_target = $(PIPX_LOCAL_VENVS)/$1/bin/$1
$$($1_target):
	$(call require,pipx)
	[ -e $$@ ] && pipx upgrade $1 || pipx install $(2)
endif
.PHONY: $1
$1: $$($1_target)
endef

OP := (
CP := )

# zen-profile paths have parentheses, such as `$HOME/.zen/hewsesre.Default (release)/chrome/userChrome.css`
escape_par = $(subst $(OP),\$(OP),$(subst $(CP),\$(CP),$1))
