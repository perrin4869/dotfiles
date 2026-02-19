COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

# the check-submodule-mismatch recipe includes some redirection that requires bash
SHELL := /bin/bash
CMAKE := cmake

HOME ?= ${HOME}
PREFIX ?= ${HOME}/.local
BINDIR  ?= $(PREFIX)/bin
LIBEXECDIR ?= ${PREFIX}/libexec
XDG_DATA_HOME ?= ${PREFIX}/share
XDG_STATE_HOME ?= ${PREFIX}/state
XDG_CONFIG_HOME ?= ${HOME}/.config

PYTHON := python3

PYTHON_SITE_PACKAGES := $(shell $(PYTHON) -m site --user-site)
PIPX := $(shell command -v pipx 2> /dev/null)
ifneq ($(PIPX),)
	# pipx --value shorthand changed from -v -> -V somewhere between 1.3.1 and 1.5.0
	PIPX_LOCAL_VENVS := $(shell pipx environment --value PIPX_LOCAL_VENVS)
endif

DEPS = deps
DCONF = dconf
CRON = cron
FONTS = home/.local/share/fonts

.PHONY: all
all: build

include mk/utils.mk
include mk/build.mk
include mk/install.mk
include mk/tests.mk
