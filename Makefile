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
LUAX_URL ?= https://github.com/CDSoft/luax
LUAX_MAGIC_ID ?= LuaX $(LUAX_VERSION) - $(LUAX_URL)

BUILD = .build
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
TARGETS += x86_64-macos-gnu
TARGETS += aarch64-macos-gnu

RUNTIMES = $(patsubst %-windows-gnu,%-windows-gnu.exe,$(TARGETS:%=$(BUILD)/luaxruntime-%))
LUAX_BINARIES := $(RUNTIMES:$(BUILD)/luaxruntime-%=$(BUILD)/luax-%)

LUA = $(BUILD)/lua
LUAX0 = $(BUILD)/lua0-$(ARCH)-$(OS)-$(LIBC)
LUA_SOURCES := $(sort $(wildcard lua/*))

LUAX_SOURCES := $(sort $(shell find src -name "*.[ch]"))

LUAX_RUNTIME := $(sort $(shell find src -name "*.lua"))
LUAX_RUNTIME_BUNDLE := $(BUILD)/lua_runtime_bundle.dat

LUAX_CONFIG_H := $(BUILD)/luax_config.h
LUAX_CONFIG_LUA := $(BUILD)/luax_config.lua

ARCH := $(shell uname -m)
OS   := $(shell uname -s | tr A-Z a-z)
LIBC := gnu
ifeq ($(OS),windows)
EXT := .exe
else
EXT :=
endif

LUAX_CLI = $(BUILD)/luaxcli.lua

.DEFAULT_GOAL := compile

# include makex to install LuaX doc and test dependencies
include makex.mk

###############################################################################
# Help
###############################################################################

red   = printf "${RED}[%s]${NORMAL} %s\n" "$1" "$2"
green = printf "${GREEN}[%s]${NORMAL} %s\n" "$1" "$2"
blue  = printf "${BLUE}[%s]${NORMAL} %s\n" "$1" "$2"
cyan  = printf "${CYAN}[%s]${NORMAL} %s\n" "$1" "$2"

welcome:
	@echo '${CYAN}Lua${NORMAL} e${CYAN}X${NORMAL}tended'
	@echo 'Copyright (C) 2021-2022 Christophe Delord (http://cdelord.fr/luax)'
	@echo ''
	@echo '${CYAN}luax${NORMAL} is a Lua interpreter and REPL based on Lua 5.4.4'
	@echo 'augmented with some useful packages.'
	@echo '${CYAN}luax${NORMAL} can also produces standalone executables from Lua scripts.'
	@echo ''
	@echo '${CYAN}luax${NORMAL} runs on several platforms with no dependency:'
	@echo ''
	@echo '- Linux (x86_64, i386, aarch64)'
	@echo '- MacOS (x86_64, aarch64)'
	@echo '- Windows (x86_64, i386)'
	@echo ''
	@echo '${CYAN}luax${NORMAL} can cross-compile scripts from and to any of these platforms.'

###############################################################################
# All
###############################################################################

.SECONDARY:

.PHONY: all
.PHONY: compile
.PHONY: test

## Compile LuaX for the host
compile: $(BUILD)/luax

## Compile LuaX for Linux, MacOS and Windows
all: $(RUNTIMES)
all: $(LUAX_BINARIES)
all: $(BUILD)/luax.tar.xz
all: doc

## Delete the build directory
clean:
	rm -rf $(BUILD)

## Delete the build directory and the downloaded Zig compiler
mrproper: clean makex-clean
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
.PHONY: update-serpent
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

SERPENT_VERSION = master
SERPENT_ARCHIVE = serpent-$(SERPENT_VERSION).zip
SERPENT_URL = https://github.com/pkulchenko/serpent/archive/refs/heads/$(SERPENT_VERSION).zip

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
update: update-serpent
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
	       -e 's/TCSAFLUSH/TCSADRAIN/'                                      \
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

## Update serpent sources
update-serpent: $(BUILD)/$(SERPENT_ARCHIVE)
	rm -f src/serpent/serpent.lua
	unzip -j $< '*/serpent.lua' -d src/serpent
	sed -i -e 's/(loadstring or load)/load/g'                   \
	       -e '/^ *if setfenv then setfenv(f, env) end *$$/d'   \
	       src/serpent/serpent.lua

$(BUILD)/$(SERPENT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(SERPENT_URL) -O $@

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

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))
INSTALLED_LUAX_BINARIES := $(LUAX_BINARIES:$(BUILD)/%=$(PREFIX)/bin/%)

## Install LuaX (for the host only)
install: $(PREFIX)/bin/luax$(EXT)
install: $(PREFIX)/bin/luaxcli.lua
install: $(PREFIX)/lib/luax.lua

## Install LuaX for Linux, MacOS and Windows
install-all: install
install-all: $(INSTALLED_LUAX_BINARIES)

$(PREFIX)/bin/luax$(EXT): $(PREFIX)/bin/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"SYMLINK",$< -> $@)
	@cd $(dir $@) && ln -sf $(notdir $<) $(notdir $@)

$(PREFIX)/bin/luax-%: $(BUILD)/luax-%
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@) $(dir $@)/../lib
	@install $< $@
	@find $(BUILD)/lib/ -name "$(patsubst %.exe,%,$(notdir $<)).*" -exec cp {} $(PREFIX)/lib/ \;

$(PREFIX)/bin/luaxcli.lua: $(LUAX_CLI)
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@)
	@install $< $@

$(PREFIX)/lib/luax.lua: lib/luax.lua
	@$(call cyan,"INSTALL",$@)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	@mkdir -p $(dir $@)
	@cp $< $@

###############################################################################
# Search for or install a zig compiler
###############################################################################

ZIG := $(ZIG_INSTALL)/zig

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
# Native Lua interpreter
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

$(LUAX0): $(ZIG) $(LUA_SOURCES) $(LUAX_SOURCES) $(LUAX_CONFIG_H) build.zig
	@$(call cyan,"ZIG",$@)
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

$(BUILD)/blake3: tools/blake3.zig $(ZIG)
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@$(ZIG) build-exe $< -fsingle-threaded --strip --cache-dir $(ZIG_CACHE) -femit-bin=$@

$(LUAX_CONFIG_H): $(wildcard .git/refs/tags) $(wildcard .git/index) $(BUILD)/blake3 Makefile
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                \
	    echo "#pragma once";                                    \
	    echo "#define LUAX_VERSION \"$(LUAX_VERSION)\"";        \
	    echo "#define LUAX_CRYPT_KEY \"`echo -n $(CRYPT_KEY) | $(BUILD)/blake3`\"";     \
	    echo "#define LUAX_MAGIC_ID \"$(LUAX_MAGIC_ID)\"";      \
	) > $@.tmp
	@mv $@.tmp $@

$(LUAX_CONFIG_LUA): $(wildcard .git/refs/tags) $(wildcard .git/index) Makefile
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  set -eu;                                                \
	    echo "return {";                                        \
	    echo "    magic_id = \"$(LUAX_MAGIC_ID)\",";            \
	    echo "    targets = {$(sort $(TARGETS:%='%',))},";      \
	    echo "}";                                               \
	) > $@.tmp
	@mv $@.tmp $@

$(LUAX_RUNTIME_BUNDLE): $(LUAX0) $(LUAX_RUNTIME) tools/bundle.lua tools/build_bundle_args.lua $(LUAX_CONFIG_LUA)
	@$(call cyan,"BUNDLE",$(@))
	@LUA_PATH="$(LUA_PATH);$(dir $(LUAX_CONFIG_LUA))/?.lua" \
	$(LUAX0) tools/bundle.lua -nomain -ascii \
	    $(shell $(LUAX0) tools/build_bundle_args.lua $(LUAX_CONFIG_LUA) $(LUAX_RUNTIME)) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD)/luaxruntime-%: $(ZIG) $(LUA_SOURCES) $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_SOURCES) $(LUAX_CONFIG_H) build.zig
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@RUNTIME_NAME=luaxruntime LIB_NAME=luax RUNTIME=1 $(ZIG) build \
	    --cache-dir $(ZIG_CACHE) \
	    --prefix $(dir $@) --prefix-exe-dir "" \
	    -D$(RELEASE) \
	    -Dtarget=$(patsubst %.exe,%,$(patsubst $(BUILD)/luaxruntime-%,%,$@)) \
	    --build-file build.zig
	@find $(BUILD)/lib -name "libluax*" | while read lib; do mv "$$lib" "`echo $$lib | sed 's/libluax/luax/'`"; done
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES := tools/luax.lua tools/bundle.lua $(LUAX_CONFIG_LUA)

$(BUILD)/luax: $(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"CP",$@)
	@cp -f $< $@

$(BUILD)/luax-%: $(BUILD)/luaxruntime-% $(LUAX_PACKAGES) tools/bundle.lua
	@$(call cyan,"BUNDLE",$@)
	@cp $< $@.tmp
	@LUA_PATH="$(LUA_PATH);$(dir $(LUAX_CONFIG_LUA))/?.lua" \
	$(LUAX0) tools/bundle.lua $(LUAX_PACKAGES) >> $@.tmp
	@mv $@.tmp $@

###############################################################################
# luax CLI (e.g. for lua or pandoc)
###############################################################################

$(LUAX_CLI): lib/luax.lua tools/luax.lua Makefile
	@(  set -eu;                                    \
	    echo "#!/usr/bin/env lua";                  \
	    echo "";                                    \
	    echo "_LUAX_VERSION = '$(LUAX_VERSION)'";   \
	    echo "";                                    \
	    echo "--{{{ lib/luax.lua";                  \
	    echo "do";                                  \
	    cat lib/luax.lua;                           \
	    echo "end";                                 \
	    echo "--}}}";                               \
	    echo "";                                    \
	    cat tools/luax.lua;                         \
	) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Tests (native only)
###############################################################################

.PHONY: test

TEST_SOURCES := tests/main.lua $(sort $(filter-out test/main.lua,$(wildcard tests/*.lua)))

## Run LuaX tests
test: $(BUILD)/test-luax.ok
ifeq ($(LIBC),gnu)
test: $(BUILD)/test-lib.ok
endif
test: $(BUILD)/test-lua.ok
test: $(BUILD)/test-lua-luaxcli.ok
ifeq ($(OS)-$(ARCH),linux-x86_64)
test: $(BUILD)/test-pandoc.ok
test: $(BUILD)/test-pandoc-luaxcli.ok
endif

$(BUILD)/test-luax.ok: $(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",Luax executable: $^)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) TYPE=static $< Lua is great
	@touch $@

$(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT): $(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(TEST_SOURCES)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) -o $@ $(TEST_SOURCES)

$(BUILD)/test-lib.ok: $(BUILD)/luax-$(ARCH)-$(OS)-$(LIBC) $(TEST_SOURCES) $(LUA)
	@$(call cyan,"TEST",Shared library: $(BUILD)/lib/luax-$(ARCH)-$(OS)-$(LIBC))
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) TYPE=dynamic LUA_CPATH="$(BUILD)/lib/?.so" LUA_PATH="tests/?.lua" $(LUA) -l luax-$(ARCH)-$(OS)-$(LIBC) $(firstword $(TEST_SOURCES)) Lua is great
	@touch $@

$(BUILD)/test-lua.ok: $(LUA) lib/luax.lua $(TEST_SOURCES)
	@$(call cyan,"TEST",Vanilla Lua interpreter: $(firstword $(TEST_SOURCES)))
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="lib/?.lua;tests/?.lua" $(LUA) -l luax $(firstword $(TEST_SOURCES)) Lua is great
	@touch $@

$(BUILD)/test-lua-luaxcli.ok: $(LUA) $(LUAX_CLI) $(TEST_SOURCES)
	@$(call cyan,"TEST",Vanilla Lua interpreter + $(notdir $(LUAX_CLI)): $(firstword $(TEST_SOURCES)))
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="tests/?.lua" $(LUA) $(LUAX_CLI) $(firstword $(TEST_SOURCES)) Lua is great
	@touch $@

$(BUILD)/test-pandoc.ok: lib/luax.lua $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter: $(firstword $(TEST_SOURCES)))
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="lib/?.lua;tests/?.lua" $(PANDOC) -f $(firstword $(TEST_SOURCES)) </dev/null
	@touch $@

$(BUILD)/test-pandoc-luaxcli.ok: $(LUAX_CLI) $(TEST_SOURCES) | $(PANDOC)
	@$(call cyan,"TEST",Pandoc Lua interpreter + $(notdir $(LUAX_CLI)): $(firstword $(TEST_SOURCES)))
	@ARCH=$(ARCH) OS=$(OS) LIBC=lua TYPE=lua LUA_PATH="tests/?.lua" $(PANDOC) lua $(LUAX_CLI) $(firstword $(TEST_SOURCES)) </dev/null
	@touch $@

###############################################################################
# Documentation
###############################################################################

.PHONY: doc

MARKDOWN_SOURCES = $(wildcard doc/src/*.md)
MARKDOWN_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=doc/%.md)
HTML_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=$(BUILD)/doc/%.html)
MD_OUTPUTS = $(MARKDOWN_SOURCES:doc/src/%.md=$(BUILD)/doc/%.md)

doc: README.md
doc: $(MARKDOWN_OUTPUTS)
doc: $(HTML_OUTPUTS) $(MD_OUTPUTS) $(BUILD)/doc/index.html

CSS = doc/src/luax.css

PANDA_OPT += --lua-filter doc/src/fix_links.lua
PANDA_OPT += --fail-if-warnings

PANDA_HTML_OPT += --embed-resources --standalone
PANDA_HTML_OPT += --css=$(CSS)
PANDA_HTML_OPT += --table-of-contents --toc-depth=3
PANDA_HTML_OPT += --highlight-style=tango

PANDA_GFM_OPT = $(PANDA_OPT)

doc/%.md: doc/src/%.md | $(PANDA)
	@$(call cyan,"DOC",$@)
	@mkdir -p $(BUILD)/doc/src/
	@PANDA_TARGET=$@ PANDA_DEP_FILE=$(BUILD)/doc/src/$(notdir $@).d $(PANDA_GFM) $(PANDA_GFM_OPT) $< -o $@

$(BUILD)/doc/%.md: doc/%.md
	@$(call cyan,"DOC",$@)
	@cp -f $< $@

$(BUILD)/doc/%.html: doc/src/%.md $(CSS) | $(PANDA)
	@$(call cyan,"DOC",$@)
	@mkdir -p $(dir $@)
	@PANDA_TARGET=$@ $(PANDA_HTML) $(PANDA_HTML_OPT) $< -o $@

$(BUILD)/doc/index.html: $(BUILD)/doc/luax.html
	@$(call cyan,"DOC",$@)
	@cp -f $< $@

README.md: doc/src/luax.md doc/src/fix_links.lua | $(PANDA)
	@$(call cyan,"DOC",$@)
	@PANDA_TARGET=$@ PANDA_DEP_FILE=$(BUILD)/doc/src/$(notdir $@).d $(PANDA_GFM) $(PANDA_GFM_OPT) $< -o $@

-include $(BUILD)/doc/*.d
-include $(BUILD)/doc/src/*.d

###############################################################################
# Archive
###############################################################################

$(BUILD)/luax.tar.xz: README.md $(LUAX_BINARIES) lib/luax.lua $(LUAX_CLI) $(HTML_OUTPUTS) $(MD_OUTPUTS) $(BUILD)/doc/index.html
	@$(call cyan,"ARCHIVE",$@)
	@rm -rf $(BUILD)/tar && mkdir -p $(BUILD)/tar
	@cp README.md $(BUILD)/tar
	@cp $(LUAX_BINARIES) $(BUILD)/tar
	@cp -r $(BUILD)/lib $(BUILD)/tar
	@mkdir -p $(BUILD)/tar/doc
	@cp $(BUILD)/doc/*.{md,html} $(BUILD)/tar/doc
	@cp lib/luax.lua $(BUILD)/tar
	@cp $(LUAX_CLI) $(BUILD)/tar
	@tar cJf $@ -C $(abspath $(BUILD)/tar) .
