# This file is part of luax.
#
# luax is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# luax is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with luax.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about luax you can visit
# http://cdelord.fr/luax

# Default encryption key for the Lua chunks in compiled applications
CRYPT_KEY ?= Luax

BUILD = .build
ZIG_CACHE = $(BUILD)/zig-cache
ZIG_INSTALL = .zig

RELEASE = release-small

# Linux
RUNTIMES += $(BUILD)/lrun-x86_64-linux-musl
RUNTIMES += $(BUILD)/lrun-i386-linux-musl
RUNTIMES += $(BUILD)/lrun-aarch64-linux-musl

# Windows
RUNTIMES += $(BUILD)/lrun-x86_64-windows-gnu.exe
RUNTIMES += $(BUILD)/lrun-i386-windows-gnu.exe

# MacOS
RUNTIMES += $(BUILD)/lrun-x86_64-macos-gnu
RUNTIMES += $(BUILD)/lrun-aarch64-macos-gnu

LUAX_BINARIES := $(patsubst $(BUILD)/lrun-%,$(BUILD)/luax-%,$(RUNTIMES))

LUA = $(BUILD)/lua
LUA_SOURCES := $(sort $(wildcard lua/*))

LUAX_SOURCES := $(sort $(shell find src -name "*.[ch]"))

LUAX_RUNTIME := $(sort $(shell find src -name "*.lua"))
LUAX_RUNTIME_ARGS := $(patsubst %x.lua,-autoexec %x.lua,$(LUAX_RUNTIME)) # autoexec *x.lua only
LUAX_RUNTIME_BUNDLE := $(BUILD)/lua_runtime_bundle.inc
LUAX_CONFIG := $(BUILD)/luax_config.h

ARCH := $(shell uname -m)
OS   := $(shell uname -s | tr A-Z a-z)
ifeq ($(OS),linux)
LIBC := musl
else
LIBC := gnu
endif
ifeq ($(OS),windows)
EXT := .exe
else
EXT :=
endif

.DEFAULT_GOAL := test

###############################################################################
# Help
###############################################################################

RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

red   = printf "${RED}[%s]${RESET} %s\n" "$1" "$2"
green = printf "${GREEN}[%s]${RESET} %s\n" "$1" "$2"
blue  = printf "${BLUE}[%s]${RESET} %s\n" "$1" "$2"
cyan  = printf "${CYAN}[%s]${RESET} %s\n" "$1" "$2"

COMMAND := ${YELLOW}
TARGET  := ${GREEN}
TEXT    := ${YELLOW}

TARGET_MAX_CHAR_NUM = 20

## Show this help
help:
	@echo '${CYAN}Lua${RESET} e${CYAN}X${RESET}tended'
	@echo 'Copyright (C) 2021-2022 Christophe Delord (http://cdelord.fr/luax)'
	@echo ''
	@echo '${CYAN}luax${RESET} is a Lua interpretor and REPL based on Lua 5.4.4, augmented with some useful packages.'
	@echo '${CYAN}luax${RESET} can also produces standalone executables from Lua scripts.'
	@echo ''
	@echo '${CYAN}luax${RESET} runs on several platforms with no dependency:'
	@echo ''
	@echo '- Linux (x86_64, i386, aarch64)'
	@echo '- MacOS (x86_64, aarch64)'
	@echo '- Windows (x86_64, i386)'
	@echo ''
	@echo '${CYAN}luax${RESET} can cross-compile scripts from and to any of these platforms.'
	@echo ''
	@echo 'Usage:'
	@echo '  ${COMMAND}make${RESET} ${TARGET}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${TARGET}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${TEXT}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

###############################################################################
# All
###############################################################################

.SECONDARY:

## Compile LuaX for Linux, MacOS and Windows
all: $(RUNTIMES)
all: $(LUAX_BINARIES)
all: $(BUILD)/luax.tar.xz
all: test

## Delete the build directory
clean:
	rm -rf $(BUILD)

## Delete the build directory and the downloaded Zig compiler
mrproper: clean
	rm -rf $(ZIG_INSTALL)

###############################################################################
# Installation
###############################################################################

INSTALL_PATH := $(firstword $(wildcard $(PREFIX) $(HOME)/.local/bin $(HOME)/bin))
INSTALLED_LUAX_BINARIES := $(patsubst $(BUILD)/%,$(INSTALL_PATH)/%,$(LUAX_BINARIES))

## Install LuaX (for the host only)
install: $(INSTALL_PATH)/luax$(EXT)

## Install LuaX for Linux, MacOS and Windows
install-all: install
install-all: $(INSTALLED_LUAX_BINARIES)

$(INSTALL_PATH)/luax: $(INSTALL_PATH)/luax-$(ARCH)-$(OS)-$(LIBC)
	@$(call cyan,"SYMLINK",$< -> $@)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	@cd $(dir $@) && ln -sf $(notdir $<) $(notdir $@)

$(INSTALL_PATH)/luax.exe: $(INSTALL_PATH)/luax-$(ARCH)-$(OS)-$(LIBC).exe
	@$(call cyan,"SYMLINK",$< -> $@)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	@install $< $@

$(INSTALL_PATH)/luax-%: $(BUILD)/luax-%
	@$(call cyan,"INSTALL",$@)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	@install $< $@

###############################################################################
# Search for or install a zig compiler
###############################################################################

ifeq ($(shell which zig 2>/dev/null),)
ZIG := $(ZIG_INSTALL)/zig
else
ZIG := $(shell which zig)
endif

ZIG_VERSION = 0.9.1
ZIG_URL = https://ziglang.org/download/$(ZIG_VERSION)/zig-$(OS)-$(ARCH)-$(ZIG_VERSION).tar.xz
ZIG_ARCHIVE = $(BUILD)/$(notdir $(ZIG_URL))

$(ZIG_INSTALL)/zig: $(ZIG_ARCHIVE)
	@$(call cyan,"EXTRACT",$^)
	@mkdir -p $(dir $@)
	@test -x $@ || tar xJf $(ZIG_ARCHIVE) -C $(dir $@) --strip-components 1
	@touch $@

$(ZIG_ARCHIVE):
	@$(call cyan,"DOWNLOAD",$@)
	@mkdir -p $(dir $@)
	@test -f $@ || wget $(ZIG_URL) -O $@

###############################################################################
# Native Lua interpretor
###############################################################################

# avoid being polluted by user definitions
export LUA_PATH := ./?.lua

$(LUA): $(ZIG) $(LUA_SOURCES) build-lua.zig
	@$(call cyan,"ZIG",$@)
	@$(ZIG) build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -D$(RELEASE) --build-file build-lua.zig
	@touch $@

###############################################################################
# Code generation
###############################################################################

CRYPT_KEY_HASH := $(shell echo $(CRYPT_KEY) | sha512sum | cut -d" " -f1 | sed 's/\(..\)/\\x\1/g')

$(LUAX_CONFIG): $(wildcard .git/refs/tags) $(wildcard .git/index) $(LUA) tools/bundle.lua
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                                                \
	    echo "#pragma once";                                                                    \
	    echo "#define LUAX_VERSION \"`git describe --tags || echo undefined`\"";                \
	    echo "#define LUAX_CRYPT_KEY \"$(CRYPT_KEY_HASH)\"";                                    \
	    $(LUA) -e "print(('#define MAGIC 0x%016XULL'):format(require 'tools/bundle'.magic))"    \
	) > $@.tmp
	@mv $@.tmp $@

$(LUAX_RUNTIME_BUNDLE): $(LUA) $(LUAX_RUNTIME) tools/bundle.lua
	@$(call cyan,"BUNDLE",$(LUAX_RUNTIME))
	@$(LUA) tools/bundle.lua -nomain -ascii $(LUAX_RUNTIME_ARGS) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD)/lrun-%.exe: $(ZIG) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG) build-run.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -D$(RELEASE) --build-file build-run.zig -Dtarget=$(patsubst $(BUILD)/lrun-%.exe,%,$@)
	@mv $(BUILD)/lrun.exe $@
	@touch $@

$(BUILD)/lrun-%: $(ZIG) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG) build-run.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -D$(RELEASE) --build-file build-run.zig -Dtarget=$(patsubst $(BUILD)/lrun-%,%,$@)
	@mv $(BUILD)/lrun $@
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES := tools/luax.lua tools/bundle.lua

$(BUILD)/luax-%: $(BUILD)/lrun-% $(LUAX_PACKAGES) tools/bundle.lua
	@$(call cyan,"BUNDLE",$@)
	@( cat $(word 1,$^); $(LUA) tools/bundle.lua $(LUAX_PACKAGES) ) > $@.tmp
	@mv $@.tmp $@
	@chmod +x $@

###############################################################################
# Archive
###############################################################################

$(BUILD)/luax.tar.xz: README.md $(LUAX_BINARIES)
	@$(call cyan,"ARCHIVE",$@)
	@tar cJf $@ \
		README.md \
		-C $(abspath $(BUILD)) $(notdir $(LUAX_BINARIES))

###############################################################################
# Tests (native only)
###############################################################################

.PHONY: test

TEST_SOURCES := tests/main.lua $(sort $(filter-out test/main.lua,$(wildcard tests/*.lua)))

## Run LuaX tests
test: $(BUILD)/test.ok

$(BUILD)/test.ok: $(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",$^)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) $< Lua is great
	@touch $@

$(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT): $(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(TEST_SOURCES)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -o $@ $(TEST_SOURCES)
