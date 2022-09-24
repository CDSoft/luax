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
CRYPT_KEY ?= LuaX

BUILD = .build
ZIG_CACHE = $(BUILD)/zig-cache
ZIG_INSTALL = .zig

RELEASE = release-small

# Linux
TARGETS += x86_64-linux-musl
TARGETS += i386-linux-musl
TARGETS += aarch64-linux-musl

# Windows
TARGETS += x86_64-windows-gnu
TARGETS += i386-windows-gnu

# MacOS
TARGETS += x86_64-macos-gnu
TARGETS += aarch64-macos-gnu

RUNTIMES = $(patsubst %-windows-gnu,%-windows-gnu.exe,$(patsubst %,$(BUILD)/lrun-%,$(TARGETS)))
LUAX_BINARIES := $(patsubst $(BUILD)/lrun-%,$(BUILD)/luax-%,$(RUNTIMES))

LUA = $(BUILD)/lua
LUA_SOURCES := $(sort $(wildcard lua/*))

LUAX_SOURCES := $(sort $(shell find src -name "*.[ch]"))

LUAX_RUNTIME := $(sort $(shell find src -name "*.lua"))
LUAX_RUNTIME_BUNDLE := $(BUILD)/lua_runtime_bundle.dat
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
	@echo '${CYAN}luax${RESET} is a Lua interpretor and REPL based on Lua 5.4.4'
	@echo 'augmented with some useful packages.'
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

.PHONY: all

## Compile LuaX for Linux, MacOS and Windows
all: test
all: $(RUNTIMES)
all: $(LUAX_BINARIES)
all: $(BUILD)/luax.tar.xz

## Delete the build directory
clean:
	rm -rf $(BUILD)

## Delete the build directory and the downloaded Zig compiler
mrproper: clean
	rm -rf $(ZIG_INSTALL)

###############################################################################
# Package updates
###############################################################################

.PHONY: update
.PHONY: update-lua
.PHONY: update-lcomplex
.PHONY: update-limath
.PHONY: update-lqmath
.PHONY: update-lmathx
.PHONY: update-linenoise
.PHONY: update-luasocket
.PHONY: update-lpeg
.PHONY: update-inspect
.PHONY: update-tinycrypt
.PHONY: update-lz4

LUA_VERSION = 5.4.4
LUA_ARCHIVE = lua-$(LUA_VERSION).tar.gz
LUA_URL = https://www.lua.org/ftp/$(LUA_ARCHIVE)

LCOMPLEX_ARCHIVE = lcomplex-100.tar.gz
LCOMPLEX_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LCOMPLEX_ARCHIVE)

LIMATH_ARCHIVE = limath-104.tar.gz
LIMATH_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LIMATH_ARCHIVE)

LQMATH_ARCHIVE = lqmath-104.tar.gz
LQMATH_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LQMATH_ARCHIVE)

LMATHX_ARCHIVE = lmathx.tar.gz
LMATHX_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/5.3/$(LMATHX_ARCHIVE)

LINENOISE_VERSION = master
LINENOISE_ARCHIVE = linenoise-$(LINENOISE_VERSION).zip
LINENOISE_URL = https://github.com/antirez/linenoise/archive/refs/heads/$(LINENOISE_VERSION).zip

LUASOCKET_VERSION = 3.1.0
LUASOCKET_ARCHIVE = luasocket-$(VERSION).zip
LUASOCKET_URL = https://github.com/lunarmodules/luasocket/archive/refs/tags/v$(LUASOCKET_VERSION).zip

LPEG_VERSION = 1.0.2
LPEG_ARCHIVE = lpeg-$(LPEG_VERSION).tar.gz
LPEG_URL = http://www.inf.puc-rio.br/~roberto/lpeg/$(LPEG_ARCHIVE)

INSPECT_VERSION = master
INSPECT_ARCHIVE = inspect-$(INSPECT_VERSION).zip
INSPECT_URL = https://github.com/kikito/inspect.lua/archive/refs/heads/$(INSPECT_VERSION).zip

TINYCRYPT_VERSION = master
TINYCRYPT_ARCHIVE = tinycrypt-$(TINYCRYPT_VERSION).zip
TINYCRYPT_URL = https://github.com/intel/tinycrypt/archive/refs/heads/$(TINYCRYPT_VERSION).zip

LZ4_VERSION = release
LZ4_ARCHIVE = lz4-$(LZ4_VERSION).zip
LZ4_URL = https://github.com/lz4/lz4/archive/refs/heads/$(LZ4_VERSION).zip

## Update the source code of third party packages
update: update-lua
update: update-lcomplex
update: update-limath
update: update-lqmath
update: update-lmathx
update: update-linenoise
update: update-luasocket
update: update-lpeg
update: update-inspect
update: update-tinycrypt
update: update-lz4

## Update Lua sources
update-lua: $(BUILD)/$(LUA_ARCHIVE)
	rm -rf lua
	mkdir lua
	tar -xzf $< -C lua --exclude=Makefile --strip-components=2 "lua-$(LUA_VERSION)/src"

$(BUILD)/$(LUA_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LUA_URL) -O $@

## Update lcomplex sources
update-lcomplex: $(BUILD)/$(LCOMPLEX_ARCHIVE)
	rm -rf src/complex/lcomplex-*
	tar -xzf $< -C src/complex --exclude=Makefile --exclude=test.lua

$(BUILD)/$(LCOMPLEX_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LCOMPLEX_URL) -O $@

## Update limath sources
update-limath: $(BUILD)/$(LIMATH_ARCHIVE)
	rm -rf src/imath/limath-*
	tar -xzf $< -C src/imath --exclude=Makefile --exclude=test.lua
	sed -i 's@"imath.h"@"src/imath.h"@' src/imath/$(shell basename $(LIMATH_ARCHIVE) .tar.gz)/limath.c

$(BUILD)/$(LIMATH_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LIMATH_URL) -O $@

## Update lqmath sources
update-lqmath: $(BUILD)/$(LQMATH_ARCHIVE)
	rm -rf src/qmath/lqmath-*
	tar -xzf $< -C src/qmath --exclude=Makefile --exclude=test.lua
	sed -i 's@"imrat.h"@"src/imrat.h"@' src/qmath/$(shell basename $(LQMATH_ARCHIVE) .tar.gz)/lqmath.c

$(BUILD)/$(LQMATH_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LQMATH_URL) -O $@

## Update lmathx sources
update-lmathx: $(BUILD)/$(LMATHX_ARCHIVE)
	rm -rf src/mathx/mathx
	tar -xzf $< -C src/mathx --exclude=Makefile --exclude=test.lua

$(BUILD)/$(LMATHX_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LMATHX_URL) -O $@

## Update linenoise sources
update-linenoise: $(BUILD)/$(LINENOISE_ARCHIVE)
	rm -rf src/linenoise/linenoise
	mkdir src/linenoise/linenoise
	unzip -j $< -x '*/.gitignore' '*/Makefile' '*/example.c' -d src/linenoise/linenoise
	sed -i -e 's/case ENTER:/case ENTER: case 10:/'                         \
	       -e 's/malloc(/safe_malloc(/'                                     \
	       -e 's/realloc(/safe_realloc(/'                                   \
	       -e 's/\(#include "linenoise.h"\)/\1\n\n#include "tools.h"/'      \
	       src/linenoise/linenoise/linenoise.c

$(BUILD)/$(LINENOISE_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LINENOISE_URL) -O $@

## Update luasocket sources
update-luasocket: $(BUILD)/$(LUASOCKET_ARCHIVE)
	rm -rf src/socket/luasocket
	mkdir src/socket/luasocket
	unzip -j $< 'luasocket-$(LUASOCKET_VERSION)/src/*' -d src/socket/luasocket

$(BUILD)/$(LUASOCKET_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LUASOCKET_URL) -O $@

## Update lpeg sources
update-lpeg: $(BUILD)/$(LPEG_ARCHIVE)
	rm -rf src/lpeg/lpeg-*
	tar xzf $< -C src/lpeg --exclude=HISTORY --exclude=*.gif --exclude=*.html --exclude=makefile --exclude=test.lua

$(BUILD)/$(LPEG_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LPEG_URL) -O $@

## Update inspect sources
update-inspect: $(BUILD)/$(INSPECT_ARCHIVE)
	rm -f src/inspect/inspect.lua
	unzip -j $< '*/inspect.lua' -d src/inspect

$(BUILD)/$(INSPECT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(INSPECT_URL) -O $@

## Update tinycrypt sources
update-tinycrypt: $(BUILD)/$(TINYCRYPT_ARCHIVE)
	rm -rf src/crypt/tinycrypt
	mkdir src/crypt/tinycrypt
	unzip -j $< -x '*/.gitignore' '*/README' '*/Makefile' '*/*.mk' '*/*.rst' '*/tests/*' -d src/crypt/tinycrypt
	find src/crypt/tinycrypt/*.[ch] -exec sed -i 's#<\(tinycrypt/.*\)>#"\1"#' {} \;
	mkdir -p src/crypt/tinycrypt/tinycrypt
	mv src/crypt/tinycrypt/*.h src/crypt/tinycrypt/tinycrypt/

$(BUILD)/$(TINYCRYPT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(TINYCRYPT_URL) -O $@

## Update LZ4 sources
update-lz4: $(BUILD)/$(LZ4_ARCHIVE)
	rm -rf src/lz4/lz4
	mkdir src/lz4/lz4
	unzip -j $< '*/lib/*.[ch]' '*/lib/LICENSE' -d src/lz4/lz4

$(BUILD)/$(LZ4_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LZ4_URL) -O $@

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

$(INSTALL_PATH)/luax$(EXT): $(INSTALL_PATH)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"SYMLINK",$< -> $@)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	@cd $(dir $@) && ln -sf $(notdir $<) $(notdir $@)

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
	@$(ZIG) build \
		--cache-dir $(ZIG_CACHE) \
		--prefix $(dir $@) --prefix-exe-dir "" \
		-D$(RELEASE) \
		-Dtarget=$(ARCH)-$(OS)-$(LIBC) \
		--build-file build-lua.zig
	@touch $@

###############################################################################
# Code generation
###############################################################################

CRYPT_KEY_HASH := $(shell echo -n $(CRYPT_KEY) | sha512sum -b | cut -d" " -f1 | sed 's/\(..\)/\\x\1/g')

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

$(BUILD)/targets.lua:
	@$(call cyan,"GEN",$@)
	@echo "return ('$(sort $(TARGETS))'):words()" > $@.tmp
	@mv $@.tmp $@

$(LUAX_RUNTIME_BUNDLE): $(LUA) $(LUAX_RUNTIME) tools/bundle.lua tools/build_bundle_args.lua
	@$(call cyan,"BUNDLE",$(@))
	@$(LUA) tools/bundle.lua -nomain -ascii $(shell $(LUA) tools/build_bundle_args.lua $(LUAX_RUNTIME)) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD)/lrun-%: $(ZIG) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG) build-run.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build \
		--cache-dir $(ZIG_CACHE) \
		--prefix $(dir $@) --prefix-exe-dir "" \
		-D$(RELEASE) \
		-Dtarget=$(patsubst %.exe,%,$(patsubst $(BUILD)/lrun-%,%,$@)) \
		--build-file build-run.zig
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES := tools/luax.lua tools/bundle.lua $(BUILD)/targets.lua

$(BUILD)/luax-%: $(BUILD)/lrun-% $(LUAX_PACKAGES) tools/bundle.lua
	@$(call cyan,"BUNDLE",$@)
	@( cat $(word 1,$^) && $(LUA) tools/bundle.lua $(LUAX_PACKAGES) ) > $@.tmp
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
