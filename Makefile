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
# (new keys can be produced by tools/random.lua)
export CRYPT_KEY ?= \x5d\xec\xc3\xbb\xe8\x40\x6e\x68\x7f\x20\xc2\x39\xf4\xa0\x27\x25

# magic id for LuaX chunks
LUAX_VERSION := $(shell git describe --tags || echo undefined)
LUAX_DATE := $(shell git show -s --format=%cd --date=format:'%Y-%m-%d' || echo undefined)
LUAX_MAGIC_ID ?= LuaX

BUILD = .build
BUILD_BIN = $(BUILD)/bin
BUILD_LIB = $(BUILD)/lib
BUILD_TMP = $(BUILD)/tmp
BUILD_TEST = $(BUILD)/test
BUILD_DOC = $(BUILD)/doc
ZIG_INSTALL = .zig
ZIG_CACHE = $(ZIG_INSTALL)/zig-cache

# Linux
TARGETS += x86_64-linux-musl
TARGETS += x86_64-linux-gnu
TARGETS += x86-linux-musl
TARGETS += x86-linux-gnu
TARGETS += aarch64-linux-musl
TARGETS += aarch64-linux-gnu

# Windows
TARGETS += x86_64-windows-gnu
TARGETS += x86-windows-gnu

# MacOS
TARGETS += x86_64-macos-none
TARGETS += aarch64-macos-none

RUNTIMES = $(patsubst %-windows-gnu,%-windows-gnu.exe,$(TARGETS:%=$(BUILD_TMP)/luaxruntime-%))
LUAX_BINARIES := $(RUNTIMES:$(BUILD_TMP)/luaxruntime-%=$(BUILD_BIN)/luax-%)

LUA = $(BUILD_TMP)/lua
LUA_SOURCES := $(sort $(wildcard lua/*))

LUAX_SOURCES := $(sort $(shell find luax-libs -name "*.[ch]" && find ext -name "*.[ch]"))

LUAX_RUNTIME := $(sort $(shell find luax-libs -name "*.lua" && find ext -name "*.lua"))
LUAX_RUNTIME_BUNDLE := $(BUILD_TMP)/lua_runtime_bundle.dat

LIB_LUAX_SOURCES := $(sort $(shell find luax-libs -name "*.lua" && find ext/lua -name "*.lua"))

LUAX_CONFIG_H := $(BUILD_TMP)/luax_config.h
LUAX_CONFIG_LUA := $(BUILD_TMP)/luax_config.lua

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
	@echo '- Linux (x86_64, x86, aarch64)'
	@echo '- MacOS (x86_64, aarch64)'
	@echo '- Windows (x86_64, x86)'
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
	rm -rf $(ZIG_INSTALL) zig-cache

###############################################################################
# Package updates
###############################################################################

.PHONY: update

### Update the source code of third party packages
update:
	@tools/update-third-party-modules.sh $(BUILD_TMP)

###############################################################################
# Installation
###############################################################################

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))
INSTALLED_LUAX_BINARIES := $(LUAX_BINARIES:$(BUILD_BIN)/%=$(PREFIX)/bin/%)

## Install LuaX (for the host only)
install: $(PREFIX)/bin/luax
install: $(PREFIX)/bin/luax-pandoc
install: $(PREFIX)/bin/luax-lua
install: $(PREFIX)/lib/luax.lua

## Install LuaX for Linux, MacOS and Windows
install-all: install
install-all: $(INSTALLED_LUAX_BINARIES)

$(PREFIX)/bin/luax: $(LUAX_BINARIES)
	@$(call cyan,"SYMLINK",$<)
	@. tools/detect.sh; cd $(dir $@) && ln -sf $(notdir $@)-$$ARCH-$$OS-$$LIBC $(notdir $@)

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
# Install a zig compiler
###############################################################################

ZIG := $(ZIG_INSTALL)/zig

$(ZIG): tools/install_zig.sh
	@$(call cyan,"ZIG",install Zig)
	@$< $@

###############################################################################
# Native Lua interpreter
###############################################################################

# avoid being polluted by user definitions
export LUA_PATH := ./?.lua;$(dir $(LUAX_CONFIG_LUA))/?.lua;luax-libs/F/?.lua;luax-libs/fs/?.lua;luax-libs/mathx/?.lua;luax-libs/lz4/?.lua;luax-libs/sh/?.lua;luax-libs/crypt/?.lua

$(LUA): $(ZIG) $(LUA_SOURCES) build-lua.zig luax-c-sources.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@. tools/detect.sh; \
	$(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -Dtarget=$$ARCH-$$OS-$$LIBC \
	    --build-file build-lua.zig
	@touch $@

###############################################################################
# Code generation
###############################################################################

$(LUAX_CONFIG_H): $(wildcard .git/refs/tags) $(wildcard .git/index)
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                \
	    echo "#pragma once";                                    \
	    echo "#define LUAX_VERSION \"$(LUAX_VERSION)\"";        \
	    echo "#define LUAX_DATE \"$(LUAX_DATE)\"";              \
	    echo "#define LUAX_CRYPT_KEY \"$(CRYPT_KEY)\"";         \
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

$(LUAX_RUNTIME_BUNDLE): $(LUA) $(LUAX_RUNTIME) luax/bundle.lua $(LUAX_CONFIG_LUA) tools/rc4_runtime.lua
	@$(call cyan,"BUNDLE",$(@))
	@mkdir -p $(dir $@)
	@$(LUA) -l tools/rc4_runtime luax/bundle.lua -lib -ascii $(LUAX_CONFIG_LUA) $(LUAX_RUNTIME) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD_TMP)/luaxruntime-%: $(ZIG) $(LUA_SOURCES) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG_H) build.zig luax-c-sources.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@) $(BUILD_LIB) $(BUILD_TMP)/lib
	@RUNTIME_NAME=luaxruntime LIB_NAME=luax $(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -Dtarget=$(patsubst %.exe,%,$(patsubst $(BUILD_TMP)/luaxruntime-%,%,$@)) \
	    --build-file build.zig
	@find $(BUILD_TMP)/lib -name "*luax-$(patsubst %.exe,%,$(patsubst $(BUILD_TMP)/luaxruntime-%,%,$@))*" \
	    | while read lib; do mv "$$lib" "$(BUILD_LIB)/`basename $$lib | sed s/^luax-/libluax-/`"; done
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES := luax/luax.lua luax/bundle.lua luax/shell_env.lua $(LUAX_CONFIG_LUA)

$(BUILD_BIN)/luax: $(LUAX_BINARIES)
	@$(call cyan,"CP",$@)
	@. tools/detect.sh; cp -f $(BUILD_BIN)/luax-$$ARCH-$$OS-$$LIBC $@

$(BUILD_BIN)/luax-%: $(BUILD_TMP)/luaxruntime-% $(LUAX_PACKAGES) luax/bundle.lua $(LUA) tools/rc4_runtime.lua
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@cp $< $@.tmp
	@$(LUA) -l tools/rc4_runtime luax/bundle.lua -binary $(LUAX_PACKAGES) >> $@.tmp
	@mv $@.tmp $@

$(LIB_LUAX): $(LUA) $(LIB_LUAX_SOURCES) luax/bundle.lua $(LUA) tools/rc4_runtime.lua
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                                        \
	    echo "--@LOAD=_: load luax to expose LuaX modules";                             \
	    echo "_LUAX_VERSION = '$(LUAX_VERSION)'";                                       \
	    echo "_LUAX_DATE = '$(LUAX_DATE)'";                                             \
	    $(LUA) -l tools/rc4_runtime luax/bundle.lua -lib -lua $(LIB_LUAX_SOURCES);      \
	) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# luax CLI (e.g. for lua or pandoc)
###############################################################################

$(LUAX_LUA): $(BUILD_BIN)/luax luax/luax.lua $(LIB_LUAX)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD_BIN)/luax -q -t lua -o $@ luax/luax.lua

###############################################################################
# luax-pandoc
###############################################################################

$(LUAX_PANDOC): $(BUILD_BIN)/luax luax/luax.lua $(LIB_LUAX)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD_BIN)/luax -q -t pandoc -o $@ luax/luax.lua

###############################################################################
# Tests (native only)
###############################################################################

.PHONY: test test-fast

TEST_SOURCES := $(sort $(wildcard tests/luax-tests/*.*))
TEST_MAIN := tests/luax-tests/main.lua

test-fast: $(BUILD_TEST)/test-luax.ok

## Run LuaX tests
test: $(BUILD_TEST)/test-luax.ok
test: $(BUILD_TEST)/test-lib.ok
test: $(BUILD_TEST)/test-lua.ok
test: $(BUILD_TEST)/test-lua-luax-lua.ok
test: $(BUILD_TEST)/test-pandoc-luax-lua.ok
ifeq ($(PANDOC_DYNAMIC_LINK),yes)
test: $(BUILD_TEST)/test-pandoc-luax-so.ok
endif

export PATH := $(BUILD_TMP):$(PATH)

$(BUILD_TEST)/test-luax.ok: $(BUILD_TEST)/test-luax
	@$(call cyan,"TEST",Luax executable: $^)
	@. tools/detect.sh; TYPE=static LUA_PATH="tests/luax-tests/?.lua" \
	TEST_NUM=1 \
	$< Lua is great
	@touch $@

$(BUILD_TEST)/test-luax: $(BUILD_BIN)/luax $(TEST_SOURCES)
	@$(call cyan,"BUNDLE",$@)
	@mkdir -p $(dir $@)
	@$(BUILD_BIN)/luax -q -o $@ $(TEST_SOURCES)

$(BUILD_TEST)/test-lib.ok: $(BUILD_BIN)/luax $(TEST_SOURCES) $(LUA)
	@$(call cyan,"TEST",Shared library: $(BUILD_LIB)/libluax-XXX)
	@mkdir -p $(dir $@)
	@. tools/detect.sh; TYPE=dynamic LUA_CPATH="$(BUILD_LIB)/?.so" LUA_PATH="tests/luax-tests/?.lua" \
	TEST_NUM=2 \
	$(LUA) -l libluax-$$ARCH-$$OS-$$LIBC $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-lua.ok: $(LUA) $(LIB_LUAX) $(TEST_SOURCES)
	@$(call cyan,"TEST",Plain Lua interpreter: $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@. tools/detect.sh; LIBC=lua TYPE=lua LUA_PATH="$(BUILD_LIB)/?.lua;tests/luax-tests/?.lua" \
	TEST_NUM=3 \
	$(LUA) -l luax $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-lua-luax-lua.ok: $(LUA) $(LUAX_LUA) $(TEST_SOURCES)
	@$(call cyan,"TEST",Plain Lua interpreter + $(notdir $(LUAX_LUA)): $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@. tools/detect.sh; LIBC=lua TYPE=lua LUA_PATH="$(BUILD_LIB)/?.lua;tests/luax-tests/?.lua" \
	TEST_NUM=4 \
	$(LUAX_LUA) $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-pandoc-luax-lua.ok: $(BUILD)/lib/luax.lua $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter + $(notdir $(BUILD)/lib/luax.lua): $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@. tools/detect.sh; LIBC=lua TYPE=pandoc LUA_PATH="$(BUILD_LIB)/?.lua;tests/luax-tests/?.lua" \
	TEST_NUM=5 \
	pandoc lua -l luax $(TEST_MAIN) Lua is great
	@touch $@

$(BUILD_TEST)/test-pandoc-luax-so.ok: $(BUILD_BIN)/luax $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter + libluax-XXX.so: $(TEST_MAIN))
	@mkdir -p $(dir $@)
	@. tools/detect.sh; TYPE=dynamic LUA_CPATH="$(BUILD_LIB)/?.so" LUA_PATH="tests/luax-tests/?.lua" \
	TEST_NUM=6 \
	pandoc lua -l libluax-$$ARCH-$$OS-$$LIBC $(TEST_MAIN) Lua is great
	@touch $@

# Tests of external interpreters

test: test-ext
test-ext: $(BUILD_TEST)/ext-lua.ok
test-ext: $(BUILD_TEST)/ext-lua-luax.ok
test-ext: $(BUILD_TEST)/ext-luax.ok
test-ext: $(BUILD_TEST)/ext-pandoc.ok
ifeq ($(PANDOC_DYNAMIC_LINK),yes)
test-ext: $(BUILD_TEST)/ext-pandoc-luax.ok
endif

$(BUILD_TEST)/ext-lua.ok: tests/external_interpreter_tests/external_interpreters.lua $(BUILD_BIN)/luax
	@$(call cyan,"TEST",luax -t lua: $<)
	@$(BUILD_BIN)/luax -q -t lua -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax env`; \
	TARGET=lua $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-lua-luax.ok: tests/external_interpreter_tests/external_interpreters.lua $(BUILD_BIN)/luax
	@$(call cyan,"TEST",luax -t lua-luax: $<)
	@$(BUILD_BIN)/luax -q -t lua-luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax env`; \
	TARGET=lua-luax $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-luax.ok: tests/external_interpreter_tests/external_interpreters.lua $(BUILD_BIN)/luax
	@$(call cyan,"TEST",luax -t luax: $<)
	@$(BUILD_BIN)/luax -q -t luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax env`; \
	TARGET=luax $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-pandoc.ok: tests/external_interpreter_tests/external_interpreters.lua $(BUILD_BIN)/luax | $(PANDOC)
	@$(call cyan,"TEST",luax -t pandoc: $<)
	@$(BUILD_BIN)/luax -q -t pandoc -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax env`; \
	TARGET=pandoc $(patsubst %.ok,%,$@) Lua is great
	@touch $@

$(BUILD_TEST)/ext-pandoc-luax.ok: tests/external_interpreter_tests/external_interpreters.lua $(BUILD_BIN)/luax | $(PANDOC)
	@$(call cyan,"TEST",luax -t pandoc-luax: $<)
	@$(BUILD_BIN)/luax -q -t pandoc-luax -o $(patsubst %.ok,%,$@) $<
	@eval `$(BUILD_BIN)/luax env`; \
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
IMAGES += $(BUILD)/luax-banner.png
IMAGES += $(BUILD)/luax-social.png
IMAGES += $(BUILD)/luax-logo.png

doc: README.md
doc: $(MARKDOWN_OUTPUTS)
#doc: $(HTML_OUTPUTS) $(MD_OUTPUTS) $(BUILD_DOC)/index.html
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

$(BUILD)/luax-banner.png: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@mkdir -p $(dir $@)
	@lsvg $< $@ -- 1024 192 # '$(URL)'

doc/luax-logo.svg: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@lsvg $< $@ -- 256 256 # '$(URL)'

$(BUILD)/luax-logo.png: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@mkdir -p $(dir $@)
	@lsvg $< $@ -- 1024 1024 # '$(URL)'

$(BUILD)/luax-social.png: doc/src/luax-logo.lua
	@$(call cyan,"IMAGE",$@)
	@mkdir -p $(dir $@)
	@lsvg $< $@ -- 1280 640 '$(URL)'

-include $(BUILD_TMP)/doc/*.d
