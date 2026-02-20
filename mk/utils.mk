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
