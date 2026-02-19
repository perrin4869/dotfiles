# the check-submodule-mismatch recipe includes some redirection that requires bash
SHELL := /bin/bash
CMAKE := cmake
PYTHON := python3

.PHONY: all
all: build

include mk/variables.mk
include mk/utils.mk
include mk/build.mk
include mk/install.mk
include mk/tests.mk
