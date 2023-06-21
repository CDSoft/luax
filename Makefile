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

# magic id for LuaX chunks
LUAX_VERSION := $(shell git describe --tags || echo undefined)
LUAX_MAGIC_ID ?= LuaX

BUILD = .build
BUILD_BIN = $(BUILD)/bin
BUILD_LIB = $(BUILD)/lib
BUILD_TMP = $(BUILD)/tmp
BUILD_TEST = $(BUILD)/test
BUILD_DOC = $(BUILD)/doc
ZIG_INSTALL = .zig
ZIG_CACHE = $(ZIG_INSTALL)/zig-cache

RELEASE = release-small

# Linux
TARGETS += x86_64-linux-musl
TARGETS += x86_64-linux-gnu
TARGETS += i386-linux-musl
TARGETS += i386-linux-gnu
TARGETS += aarch64-linux-musl
TARGETS += aarch64-linux-gnu

# Windows
TARGETS += x86_64-windows-gnu
TARGETS += i386-windows-gnu

# MacOS
TARGETS += x86_64-macos-none
TARGETS += aarch64-macos-none

RUNTIMES = $(patsubst %-windows-gnu,%-windows-gnu.exe,$(TARGETS:%=$(BUILD_TMP)/luaxruntime-%))
LUAX_BINARIES := $(RUNTIMES:$(BUILD_TMP)/luaxruntime-%=$(BUILD_BIN)/luax-%)

LUA = $(BUILD_TMP)/lua
LUAX0 = $(BUILD_TMP)/lua0-$(ARCH)-$(OS)-$(LIBC)
LUA_SOURCES := $(sort $(wildcard lua/*))

LUAX_SOURCES := $(sort $(shell find src -name "*.[ch]"))

LUAX_RUNTIME := $(sort $(shell find src -name "*.lua"))
LUAX_RUNTIME_BUNDLE := $(BUILD_TMP)/lua_runtime_bundle.dat

LIB_LUAX_SOURCES += src/F/F.lua
LIB_LUAX_SOURCES += src/L/L.lua
LIB_LUAX_SOURCES += src/argparse/argparse.lua
LIB_LUAX_SOURCES += src/complex/complex.lua
LIB_LUAX_SOURCES += src/crypt/crypt.lua
LIB_LUAX_SOURCES += src/fs/fs.lua
LIB_LUAX_SOURCES += src/imath/imath.lua
LIB_LUAX_SOURCES += src/inspect/inspect.lua
LIB_LUAX_SOURCES += src/mathx/mathx.lua
LIB_LUAX_SOURCES += src/ps/ps.lua
LIB_LUAX_SOURCES += src/qmath/qmath.lua
LIB_LUAX_SOURCES += src/serpent/serpent.lua
LIB_LUAX_SOURCES += src/sh/sh.lua
LIB_LUAX_SOURCES += src/sys/sys.lua
LIB_LUAX_SOURCES += src/term/term.lua
LIB_LUAX_SOURCES += src/lz4/lz4.lua

LUAX_CONFIG_H := $(BUILD_TMP)/luax_config.h
LUAX_CONFIG_LUA := $(BUILD_TMP)/luax_config.lua

ARCH := $(shell tools/arch.sh)
OS   := $(shell tools/os.sh)
LIBC := gnu
ifeq ($(OS),windows)
EXT := .exe
else
EXT :=
endif

LUAX_LUA = $(BUILD_BIN)/luax-lua
LUAX_PANDOC = $(BUILD_BIN)/luax-pandoc

LIB_LUAX = $(BUILD_LIB)/luax.lua

.DEFAULT_GOAL := compile

# check if Pandoc is able to load shared libraries
PANDOC_DYNAMIC_LINK := $(shell (ldd `which pandoc` | grep -q "libc.so") 2>/dev/null && echo yes || echo no)

SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

###############################################################################
# Help
###############################################################################

.PHONY: help welcome

BLACK     := $(shell tput -Txterm setaf 0)
RED       := $(shell tput -Txterm setaf 1)
GREEN     := $(shell tput -Txterm setaf 2)
YELLOW    := $(shell tput -Txterm setaf 3)
BLUE      := $(shell tput -Txterm setaf 4)
PURPLE    := $(shell tput -Txterm setaf 5)
CYAN      := $(shell tput -Txterm setaf 6)
WHITE     := $(shell tput -Txterm setaf 7)
BG_BLACK  := $(shell tput -Txterm setab 0)
BG_RED    := $(shell tput -Txterm setab 1)
BG_GREEN  := $(shell tput -Txterm setab 2)
BG_YELLOW := $(shell tput -Txterm setab 3)
BG_BLUE   := $(shell tput -Txterm setab 4)
BG_PURPLE := $(shell tput -Txterm setab 5)
BG_CYAN   := $(shell tput -Txterm setab 6)
BG_WHITE  := $(shell tput -Txterm setab 7)
NORMAL    := $(shell tput -Txterm sgr0)

CMD_COLOR    := ${YELLOW}
TARGET_COLOR := ${GREEN}
TEXT_COLOR   := ${CYAN}
TARGET_MAX_LEN := 16

## show this help massage
help: welcome
	@echo ''
	@echo 'Usage:'
	@echo '  ${CMD_COLOR}make${NORMAL} ${TARGET_COLOR}<target>${NORMAL}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
	    helpMessage = match(lastLine, /^## (.*)/); \
	    if (helpMessage) { \
	        helpCommand = substr($$1, 0, index($$1, ":")-1); \
	        helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	        printf "  ${TARGET_COLOR}%-$(TARGET_MAX_LEN)s${NORMAL} ${TEXT_COLOR}%s${NORMAL}\n", helpCommand, helpMessage; \
	    } \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

red   = printf "${RED}[%s]${NORMAL} %s\n" "$1" "$2"
green = printf "${GREEN}[%s]${NORMAL} %s\n" "$1" "$2"
blue  = printf "${BLUE}[%s]${NORMAL} %s\n" "$1" "$2"
cyan  = printf "${CYAN}[%s]${NORMAL} %s\n" "$1" "$2"

welcome:
	@echo '${CYAN}Lua${NORMAL} e${CYAN}X${NORMAL}tended'
	@echo 'Copyright (C) 2021-2023 Christophe Delord (http://cdelord.fr/luax)'
	@echo ''
	@echo '${CYAN}luax${NORMAL} is a Lua interpreter and REPL based on Lua 5.4'
	@echo 'augmented with some useful packages.'
	@echo '${CYAN}luax${NORMAL} can also produce standalone executables from Lua scripts.'
	@echo ''
	@echo '${CYAN}luax${NORMAL} runs on several platforms with no dependency:'
	@echo ''
	@echo '- Linux (x86_64, i386, aarch64)'
	@echo '- MacOS (x86_64, aarch64)'
	@echo '- Windows (x86_64, i386)'
	@echo ''
	@echo '${CYAN}luax${NORMAL} can « cross-compile » scripts from and to any of these platforms.'

###############################################################################
# All
###############################################################################

.SECONDARY:

.PHONY: all
.PHONY: compile
.PHONY: test

## Compile LuaX for the host
compile: $(BUILD_BIN)/luax

## Compile LuaX for Linux, MacOS and Windows
all: $(RUNTIMES)
all: $(LUAX_BINARIES)
all: $(LUAX_LUA)
all: $(LUAX_PANDOC)
all: $(LIB_LUAX)

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
.PHONY: update-luasocket
.PHONY: update-lpeg
.PHONY: update-argparse
.PHONY: update-inspect
.PHONY: update-serpent
.PHONY: update-lz4

LUA_VERSION = 5.4.6
LUA_ARCHIVE = lua-$(LUA_VERSION).tar.gz
LUA_URL = https://www.lua.org/ftp/$(LUA_ARCHIVE)

LCOMPLEX_ARCHIVE = lcomplex-100.tar.gz
LCOMPLEX_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LCOMPLEX_ARCHIVE)

LIMATH_ARCHIVE = limath-104.tar.gz
LIMATH_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LIMATH_ARCHIVE)

LQMATH_ARCHIVE = lqmath-105.tar.gz
LQMATH_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$(LQMATH_ARCHIVE)

LMATHX_ARCHIVE = lmathx.tar.gz
LMATHX_URL = https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/5.3/$(LMATHX_ARCHIVE)

LUASOCKET_VERSION = 3.1.0
LUASOCKET_ARCHIVE = luasocket-$(LUASOCKET_VERSION).zip
LUASOCKET_URL = https://github.com/lunarmodules/luasocket/archive/refs/tags/v$(LUASOCKET_VERSION).zip

LPEG_VERSION = 1.0.2
LPEG_ARCHIVE = lpeg-$(LPEG_VERSION).tar.gz
LPEG_URL = http://www.inf.puc-rio.br/~roberto/lpeg/$(LPEG_ARCHIVE)

ARGPARSE_VERSION = master
ARGPARSE_ARCHIVE = argparse-$(ARGPARSE_VERSION).zip
ARGPARSE_URL = https://github.com/luarocks/argparse/archive/refs/heads/$(ARGPARSE_VERSION).zip

INSPECT_VERSION = master
INSPECT_ARCHIVE = inspect-$(INSPECT_VERSION).zip
INSPECT_URL = https://github.com/kikito/inspect.lua/archive/refs/heads/$(INSPECT_VERSION).zip

SERPENT_VERSION = master
SERPENT_ARCHIVE = serpent-$(SERPENT_VERSION).zip
SERPENT_URL = https://github.com/pkulchenko/serpent/archive/refs/heads/$(SERPENT_VERSION).zip

LZ4_VERSION = release
LZ4_ARCHIVE = lz4-$(LZ4_VERSION).zip
LZ4_URL = https://github.com/lz4/lz4/archive/refs/heads/$(LZ4_VERSION).zip

## Update the source code of third party packages
update: update-lua
update: update-lcomplex
update: update-limath
update: update-lqmath
update: update-lmathx
update: update-luasocket
update: update-lpeg
update: update-argparse
update: update-inspect
update: update-serpent
update: update-lz4

## Update Lua sources
update-lua: $(BUILD_TMP)/$(LUA_ARCHIVE)
	rm -rf lua
	mkdir lua
	tar -xzf $< -C lua --exclude=Makefile --strip-components=2 "lua-$(LUA_VERSION)/src"

$(BUILD_TMP)/$(LUA_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LUA_URL) -O $@

## Update lcomplex sources
update-lcomplex: $(BUILD_TMP)/$(LCOMPLEX_ARCHIVE)
	rm -rf src/complex/lcomplex-*
	tar -xzf $< -C src/complex --exclude=Makefile --exclude=test.lua

$(BUILD_TMP)/$(LCOMPLEX_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LCOMPLEX_URL) -O $@

## Update limath sources
update-limath: $(BUILD_TMP)/$(LIMATH_ARCHIVE)
	rm -rf src/imath/limath-*
	tar -xzf $< -C src/imath --exclude=Makefile --exclude=test.lua
	sed -i 's@"imath.h"@"src/imath.h"@' src/imath/$(shell basename $(LIMATH_ARCHIVE) .tar.gz)/limath.c

$(BUILD_TMP)/$(LIMATH_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LIMATH_URL) -O $@

## Update lqmath sources
update-lqmath: $(BUILD_TMP)/$(LQMATH_ARCHIVE)
	rm -rf src/qmath/lqmath-*
	tar -xzf $< -C src/qmath --exclude=Makefile --exclude=test.lua
	sed -i 's@"imrat.h"@"src/imrat.h"@' src/qmath/$(shell basename $(LQMATH_ARCHIVE) .tar.gz)/lqmath.c

$(BUILD_TMP)/$(LQMATH_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LQMATH_URL) -O $@

## Update lmathx sources
update-lmathx: $(BUILD_TMP)/$(LMATHX_ARCHIVE)
	rm -rf src/mathx/mathx
	tar -xzf $< -C src/mathx --exclude=Makefile --exclude=test.lua

$(BUILD_TMP)/$(LMATHX_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LMATHX_URL) -O $@

## Update luasocket sources
update-luasocket: $(BUILD_TMP)/$(LUASOCKET_ARCHIVE)
	rm -rf src/socket/luasocket
	mkdir src/socket/luasocket
	unzip -j $< 'luasocket-$(LUASOCKET_VERSION)/src/*' -d src/socket/luasocket
	echo "--@NAME=socket.ftp"     >> src/socket/luasocket/ftp.lua
	echo "--@NAME=socket.headers" >> src/socket/luasocket/headers.lua
	echo "--@NAME=socket.http"    >> src/socket/luasocket/http.lua
	echo "--@NAME=socket.smtp"    >> src/socket/luasocket/smtp.lua
	echo "--@NAME=socket.tp"      >> src/socket/luasocket/tp.lua
	echo "--@NAME=socket.url"     >> src/socket/luasocket/url.lua

$(BUILD_TMP)/$(LUASOCKET_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LUASOCKET_URL) -O $@

## Update lpeg sources
update-lpeg: $(BUILD_TMP)/$(LPEG_ARCHIVE)
	rm -rf src/lpeg/lpeg-*
	tar xzf $< -C src/lpeg --exclude=HISTORY --exclude=*.gif --exclude=*.html --exclude=makefile --exclude=test.lua
	echo "--@LOAD" >> src/lpeg/lpeg-1.0.2/re.lua

$(BUILD_TMP)/$(LPEG_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LPEG_URL) -O $@

## Update argparse sources
update-argparse: $(BUILD_TMP)/$(ARGPARSE_ARCHIVE)
	rm -f src/argparse/argparse.lua
	unzip -j -o $< '*/argparse.lua' -d src/argparse

$(BUILD_TMP)/$(ARGPARSE_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(ARGPARSE_URL) -O $@

## Update inspect sources
update-inspect: $(BUILD_TMP)/$(INSPECT_ARCHIVE)
	rm -f src/inspect/inspect.lua
	unzip -j $< '*/inspect.lua' -d src/inspect
	echo "--@LOAD" >> src/inspect/inspect.lua

$(BUILD_TMP)/$(INSPECT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(INSPECT_URL) -O $@

## Update serpent sources
update-serpent: $(BUILD_TMP)/$(SERPENT_ARCHIVE)
	rm -f src/serpent/serpent.lua
	unzip -j $< '*/serpent.lua' -d src/serpent
	sed -i -e 's/(loadstring or load)/load/g'                   \
	       -e '/^ *if setfenv then setfenv(f, env) end *$$/d'   \
	       src/serpent/serpent.lua
	echo "--@LOAD" >> src/serpent/serpent.lua

$(BUILD_TMP)/$(SERPENT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(SERPENT_URL) -O $@

## Update LZ4 sources
update-lz4: $(BUILD_TMP)/$(LZ4_ARCHIVE)
	rm -rf src/lz4/lz4
	mkdir src/lz4/lz4
	unzip -j $< '*/lib/*.[ch]' '*/lib/LICENSE' -d src/lz4/lz4

$(BUILD_TMP)/$(LZ4_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(LZ4_URL) -O $@

###############################################################################
# Installation
###############################################################################

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))
INSTALLED_LUAX_BINARIES := $(LUAX_BINARIES:$(BUILD_BIN)/%=$(PREFIX)/bin/%)

## Install LuaX (for the host only)
install: $(PREFIX)/bin/luax$(EXT)
install: $(PREFIX)/bin/luax-pandoc
install: $(PREFIX)/bin/luax-lua
install: $(PREFIX)/lib/luax.lua

## Install LuaX for Linux, MacOS and Windows
install-all: install
install-all: $(INSTALLED_LUAX_BINARIES)

$(PREFIX)/bin/luax$(EXT): $(PREFIX)/bin/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"SYMLINK",$< -> $@)
	@cd $(dir $@) && ln -sf $(notdir $<) $(notdir $@)

$(PREFIX)/bin/luax-%: $(BUILD_BIN)/luax-%
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@) $(dir $@)/../lib
	@install $< $@
	@find $(BUILD_LIB) -name "lib$(patsubst %.exe,%,$(notdir $<)).*" -exec cp {} $(PREFIX)/lib/ \;

$(PREFIX)/bin/luax-lua: $(LUAX_LUA)
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@)
	@install $< $@

$(PREFIX)/lib/luax.lua: $(LIB_LUAX)
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@)
	@install $< $@

$(PREFIX)/bin/luax-pandoc: $(LUAX_PANDOC)
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@)
	@install $< $@

###############################################################################
# Search for or install a zig compiler
###############################################################################

ZIG := $(ZIG_INSTALL)/zig

ZIG_VERSION = 0.10.1
ZIG_URL = https://ziglang.org/download/$(ZIG_VERSION)/zig-$(OS)-$(ARCH)-$(ZIG_VERSION).tar.xz

ZIG_ARCHIVE = $(BUILD_TMP)/$(notdir $(ZIG_URL))

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
# Native Lua interpreter
###############################################################################

# avoid being polluted by user definitions
export LUA_PATH := ./?.lua

$(LUA): $(ZIG) $(LUA_SOURCES) build-lua.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -D$(RELEASE) \
	    -Dtarget=$(ARCH)-$(OS)-$(LIBC) \
	    --build-file build-lua.zig
	@touch $@

$(LUAX0): $(ZIG) $(LUA_SOURCES) $(LUAX_SOURCES) $(LUAX_CONFIG_H) build.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@RUNTIME_NAME=lua0 RUNTIME=0 $(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -D$(RELEASE) \
	    -Dtarget=$(ARCH)-$(OS)-$(LIBC) \
	    --build-file build.zig
	@touch $@

###############################################################################
# Code generation
###############################################################################

$(BUILD_TMP)/blake3: tools/blake3.zig $(ZIG)
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build-exe $< -fsingle-threaded -fstrip --cache-dir $(ZIG_CACHE) -femit-bin=$@

$(LUAX_CONFIG_H): $(wildcard .git/refs/tags) $(wildcard .git/index) $(BUILD_TMP)/blake3
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                \
	    echo "#pragma once";                                    \
	    echo "#define LUAX_VERSION \"$(LUAX_VERSION)\"";        \
	    echo "#define LUAX_CRYPT_KEY \"`echo -n $(CRYPT_KEY) | $(BUILD_TMP)/blake3`\"";     \
	    echo "#define LUAX_MAGIC_ID \"$(LUAX_MAGIC_ID)\"";      \
	) > $@.tmp
	@mv $@.tmp $@

$(LUAX_CONFIG_LUA): $(wildcard .git/refs/tags) $(wildcard .git/index)
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                \
	    echo "--@LIB";                                          \
	    echo "return {";                                        \
	    echo "    magic_id = \"$(LUAX_MAGIC_ID)\",";            \
	    echo "    targets = {$(sort $(TARGETS:%='%',))},";      \
	    echo "}";                                               \
	) > $@.tmp
	@mv $@.tmp $@

$(LUAX_RUNTIME_BUNDLE): $(LUAX0) $(LUAX_RUNTIME) tools/bundle.lua $(LUAX_CONFIG_LUA)
	@$(call cyan,"BUNDLE",$(@))
	@mkdir -p $(dir $@)
	@LUA_PATH="$(LUA_PATH);$(dir $(LUAX_CONFIG_LUA))/?.lua" \
	$(LUAX0) tools/bundle.lua -lib -ascii $(LUAX_CONFIG_LUA) $(LUAX_RUNTIME) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD_TMP)/luaxruntime-%: $(ZIG) $(LUA_SOURCES) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG_H) build.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@) $(BUILD_LIB) $(BUILD_TMP)/lib
	@RUNTIME_NAME=luaxruntime LIB_NAME=luax RUNTIME=1 $(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -D$(RELEASE) \
	    -Dtarget=$(patsubst %.exe,%,$(patsubst $(BUILD_TMP)/luaxruntime-%,%,$@)) \
	    --build-file build.zig
	@find $(BUILD_TMP)/lib -name "*luax-$(patsubst %.exe,%,$(patsubst $(BUILD_TMP)/luaxruntime-%,%,$@))*" \
	    | while read lib; do mv "$$lib" "$(BUILD_LIB)/`basename $$lib | sed s/^luax-/libluax-/`"; done
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES := tools/luax.lua tools/bundle.lua tools/shell_env.lua $(LUAX_CONFIG_LUA)

$(BUILD_BIN)/luax: $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"CP",$@)
	@cp -f $< $@

$(BUILD_BIN)/luax-%: $(BUILD_TMP)/luaxruntime-% $(LUAX_PACKAGES) tools/bundle.lua $(LUAX0)
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@cp $< $@.tmp
	@LUA_PATH="$(LUA_PATH);$(dir $(LUAX_CONFIG_LUA))/?.lua" \
	$(LUAX0) tools/bundle.lua -binary $(LUAX_PACKAGES) >> $@.tmp
	@mv $@.tmp $@

$(LIB_LUAX): $(LUAX0) $(LIB_LUAX_SOURCES) tools/bundle.lua $(LUAX0)
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                    \
	    echo "_LUAX_VERSION = '$(LUAX_VERSION)'";                   \
	    LUA_PATH="$(LUA_PATH);$(dir $(LUAX_CONFIG_LUA))/?.lua"      \
	    $(LUAX0) tools/bundle.lua -lib -lua $(LIB_LUAX_SOURCES);    \
	) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# luax CLI (e.g. for lua or pandoc)
###############################################################################

$(LUAX_LUA): $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) tools/luax.lua $(LIB_LUAX)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t lua -o $@ tools/luax.lua

###############################################################################
# luax-pandoc
###############################################################################

$(LUAX_PANDOC): $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) tools/luax.lua $(LIB_LUAX)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t pandoc -o $@ tools/luax.lua

###############################################################################
# Tests (native only)
###############################################################################

.PHONY: test test-fast

TEST_SOURCES := $(filter-out tests/external_interpreters.lua,$(sort $(wildcard tests/*.lua)))
TEST_MAIN := tests/main.lua

test-fast: $(BUILD_TEST)/test-luax.ok

## Run LuaX tests
test: $(BUILD_TEST)/test-luax.ok
ifeq ($(LIBC),gnu)
test: $(BUILD_TEST)/test-lib.ok
endif
test: $(BUILD_TEST)/test-lua.ok
test: $(BUILD_TEST)/test-lua-luax-lua.ok
ifeq ($(OS)-$(ARCH),linux-x86_64)
test: $(BUILD_TEST)/test-pandoc-luax-lua.ok
ifeq ($(PANDOC_DYNAMIC_LINK),yes)
test: $(BUILD_TEST)/test-pandoc-luax-so.ok
endif
endif

$(BUILD_TEST)/test-luax.ok: $(BUILD_TEST)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",Luax executable: $^)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) TYPE=static \
	TEST_NUM=1 \
	$< Lua is great
	@touch $@

$(BUILD_TEST)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT): $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(TEST_SOURCES)
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -o $@ $(TEST_SOURCES)

$(BUILD_TEST)/test-lib.ok: $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC) $(TEST_SOURCES) $(LUA)
	@$(call cyan,"TEST",Shared library: $(BUILD_LIB)/libluax-$(ARCH)-$(OS)-$(LIBC))
	@mkdir -p $(dir $@)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) TYPE=dynamic LUA_CPATH="$(BUILD_LIB)/?.so" LUA_PATH="tests/?.lua" \
	TEST_NUM=2 \
	$(LUA) -l libluax-$(ARCH)-$(OS)-$(LIBC) $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-lua.ok: $(LUA) $(LIB_LUAX) $(TEST_SOURCES)
	@$(call cyan,"TEST",Plain Lua interpreter: $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="$(BUILD_LIB)/?.lua;tests/?.lua" \
	TEST_NUM=3 \
	$(LUA) -l luax $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-lua-luax-lua.ok: $(LUA) $(LUAX_LUA) $(TEST_SOURCES)
	@$(call cyan,"TEST",Plain Lua interpreter + $(notdir $(LUAX_LUA)): $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="$(BUILD_LIB)/?.lua;tests/?.lua" \
	TEST_NUM=4 \
	$(LUAX_LUA) $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-pandoc-luax-lua.ok: $(BUILD)/lib/luax.lua $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter + $(notdir $(BUILD)/lib/luax.lua): $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=pandoc LUA_PATH="$(BUILD_LIB)/?.lua;tests/?.lua" \
	TEST_NUM=5 \
	pandoc lua -l luax $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-pandoc-luax-so.ok: $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC) $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter + libluax-$(ARCH)-$(OS)-$(LIBC).so: $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) TYPE=dynamic LUA_CPATH="$(BUILD_LIB)/?.so" LUA_PATH="tests/?.lua" \
	TEST_NUM=6 \
	pandoc lua -l libluax-$(ARCH)-$(OS)-$(LIBC) $(TEST_MAIN) Lua is great
	@touch $@

# Tests of external interpreters

test: test-ext
test-ext: $(BUILD_TEST)/ext-lua.ok
test-ext: $(BUILD_TEST)/ext-lua-luax.ok
test-ext: $(BUILD_TEST)/ext-luax.ok
ifeq ($(OS)-$(ARCH),linux-x86_64)
test-ext: $(BUILD_TEST)/ext-pandoc.ok
ifeq ($(PANDOC_DYNAMIC_LINK),yes)
test-ext: $(BUILD_TEST)/ext-pandoc-luax.ok
endif
endif

$(BUILD_TEST)/ext-lua.ok: tests/external_interpreters.lua $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",luax -t lua: $<)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t lua -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) env`; \
	TARGET=lua $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-lua-luax.ok: tests/external_interpreters.lua $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",luax -t lua-luax: $<)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t lua-luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) env`; \
	TARGET=lua-luax $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-luax.ok: tests/external_interpreters.lua $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",luax -t luax: $<)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) env`; \
	TARGET=luax $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-pandoc.ok: tests/external_interpreters.lua $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) | $(PANDOC)
	@$(call cyan,"TEST",luax -t pandoc: $<)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t pandoc -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) env`; \
	TARGET=pandoc $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-pandoc-luax.ok: tests/external_interpreters.lua $(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) | $(PANDOC)
	@$(call cyan,"TEST",luax -t pandoc-luax: $<)
	@$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -q -t pandoc-luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) env`; \
	TARGET=pandoc-luax $(patsubst %.ok,%,$@) Lua is great
	@touch $@

###############################################################################
# Documentation
###############################################################################

.PHONY: doc

MARKDOWN_SOURCES = $(wildcard doc/src/*.md)
MARKDOWN_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=doc/%.md)
HTML_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=$(BUILD_DOC)/%.html)
MD_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=$(BUILD_DOC)/%.md)

IMAGES += doc/luax-banner.svg
IMAGES += doc/luax-logo.svg
IMAGES += $(BUILD)/luax-social.png

doc: README.md
doc: $(MARKDOWN_OUTPUTS)
doc: $(HTML_OUTPUTS) $(MD_OUTPUTS) $(BUILD_DOC)/index.html
doc: $(IMAGES)

CSS = doc/src/luax.css

PANDOC_GFM = pandoc --to gfm
PANDOC_GFM += --lua-filter doc/src/fix_links.lua
PANDOC_GFM += --fail-if-warnings

PANDOC_HTML = pandoc --to html5
PANDOC_HTML += --lua-filter doc/src/fix_links.lua
PANDOC_HTML += --embed-resources --standalone
PANDOC_HTML += --css=$(CSS)
PANDOC_HTML += --table-of-contents --toc-depth=3
PANDOC_HTML += --highlight-style=tango

export BUILD_BIN

doc/%.md: doc/src/%.md $(IMAGES) $(BUILD_BIN)/luax
	@$(call cyan,"DOC",$@)
	@mkdir -p $(BUILD_TMP)/doc
	@ypp --MD --MT $@ --MF $(BUILD_TMP)/doc/$(notdir $@).d $< | $(PANDOC_GFM) -o $@

$(BUILD_DOC)/%.md: doc/%.md $(IMAGES)
	@$(call cyan,"DOC",$@)
	@mkdir -p $(dir $@)
	@cp -f $< $@

$(BUILD_DOC)/%.html: doc/src/%.md $(CSS) doc/src/fix_links.lua $(IMAGES) $(BUILD_BIN)/luax
	@$(call cyan,"DOC",$@)
	@mkdir -p $(dir $@) $(BUILD_TMP)/doc
	@ypp --MD --MT $@ --MF $(BUILD_TMP)/doc/$(notdir $@).d $< | $(PANDOC_HTML) -o $@

$(BUILD_DOC)/index.html: $(BUILD_DOC)/luax.html
	@$(call cyan,"DOC",$@)
	@mkdir -p $(dir $@)
	@cp -f $< $@

README.md: doc/src/luax.md doc/src/fix_links.lua $(IMAGES) $(BUILD_BIN)/luax
	@$(call cyan,"DOC",$@)
	@mkdir -p $(BUILD_TMP)/doc
	@ypp --MD --MT $@ --MF $(BUILD_TMP)/doc/$(notdir $@).d $< | $(PANDOC_GFM) -o $@

URL = cdelord.fr/luax

doc/luax-banner.svg: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@lsvg $< $@ -- 1024 192 # '$(URL)'

doc/luax-logo.svg: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@lsvg $< $@ -- 256 256 # '$(URL)'

$(BUILD)/luax-social.png: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@mkdir -p $(dir $@)
	@lsvg $< $@ -- 1280 640 '$(URL)'

-include $(BUILD_TMP)/doc/*.d
