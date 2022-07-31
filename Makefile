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

BUILD = .build
ZIG_CACHE = $(BUILD)/zig-cache

RUNTIMES += $(BUILD)/lrun-x86_64-linux-musl
RUNTIMES += $(BUILD)/lrun-x86_64-windows-gnu.exe
RUNTIMES += $(BUILD)/lrun-x86_64-macos-gnu
RUNTIMES += $(BUILD)/lrun-aarch64-macos-gnu
RUNTIMES += $(BUILD)/lrun-aarch64-linux-musl

LUAX_BINARIES = $(patsubst $(BUILD)/lrun-%,$(BUILD)/luax-%,$(RUNTIMES))
LPACK_BINARIES = $(patsubst $(BUILD)/lrun-%,$(BUILD)/lpack-%,$(RUNTIMES))

LUA = $(BUILD)/lua
LUA_SOURCES = $(sort $(wildcard lua/*))

LUAX_SOURCES = $(sort $(shell find src -name "*.[ch]"))

LUAX_RUNTIME = $(sort $(shell find src -name "*.lua"))
LUAX_RUNTIME_ARGS = $(patsubst %x.lua,-l %x.lua,$(LUAX_RUNTIME)) # autoload *x.lua only
LUAX_RUNTIME_BUNDLE = $(BUILD)/lua_runtime_bundle.inc
LUAX_RUNTIME_MAGIC = $(BUILD)/magic.inc
LUAX_VERSION = $(BUILD)/luax_version.h
SYS_PARAMS = $(BUILD)/sys_params.h

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

all: $(RUNTIMES)
all: $(LUAX_BINARIES)
all: $(LPACK_BINARIES)
all: $(BUILD)/luax.tar.xz
all: test

clean:
	rm -rf $(BUILD)

INSTALL_PATH = $(firstword $(wildcard $(PREFIX) $(HOME)/.local/bin $(HOME)/bin))

install: $(LUAX_BINARIES) $(LPACK_BINARIES)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	install $^ $(INSTALL_PATH)
	ln -sf $(INSTALL_PATH)/luax-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(INSTALL_PATH)/luax$(EXT)
	ln -sf $(INSTALL_PATH)/lpack-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(INSTALL_PATH)/lpack$(EXT)

.SECONDARY:

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

###############################################################################
# Native Lua interpretor
###############################################################################

$(LUA): $(LUA_SOURCES)
	@$(call cyan,"ZIG",$@)
	@zig build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -Drelease-small --build-file build-lua.zig
	@touch $@

###############################################################################
# Code generation
###############################################################################


# all lua scripts from src are bundled and added to the runtime
$(LUAX_VERSION): $(wildcard .git/refs/tags) $(wildcard .git/index)
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  echo "#pragma once";                                                        \
	    echo "#define LUAX_VERSION \"`git describe --tags || echo undefined`\"";    \
	) > $@

$(SYS_PARAMS):
	@$(call cyan,"SYS",$@)
	@mkdir -p $(dir $@)
	@(  echo "#pragma once";                \
	    echo "#define ARCH \"$(ARCH)\"";    \
	    echo "#define OS \"$(OS)\"";        \
	    echo "#define LIBC \"$(LIBC)\"";    \
	) > $@

$(LUAX_RUNTIME_BUNDLE): $(LUA) $(LUAX_RUNTIME) tools/bundle.lua
	@$(call cyan,"BUNDLE",$(LUAX_RUNTIME))
	@$(LUA) tools/bundle.lua -c $(LUAX_RUNTIME_ARGS) > $@.tmp
	@mv $@.tmp $@
	@touch $@

$(LUAX_RUNTIME_MAGIC): $(LUA) tools/bundle.lua
	@$(call cyan,"MAGIC",$(word 2,$^))
	@$(LUA) -e "print(('0x%016XULL'):format(require 'tools/bundle'.magic))" > $@.tmp
	@mv $@.tmp $@
	@touch $@

###############################################################################
# Runtimes
###############################################################################

$(BUILD)/lrun-%.exe: $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_RUNTIME_MAGIC) $(LUAX_SOURCES) $(LUAX_VERSION) $(SYS_PARAMS)
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@zig build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -Drelease-small --build-file build-run.zig -Dtarget=$(patsubst $(BUILD)/lrun-%.exe,%,$@)
	@mv $(BUILD)/lrun.exe $@
	@touch $@

$(BUILD)/lrun-%: $(SOURCES) $(LUAX_RUNTIME_BUNDLE) $(LUAX_RUNTIME_MAGIC) $(LUAX_SOURCES) $(LUAX_VERSION) $(SYS_PARAMS)
	@$(call cyan,"ZIG",$@)
	@mkdir -p $(dir $@)
	@zig build --cache-dir $(ZIG_CACHE) --prefix $(dir $@) --prefix-exe-dir "" -Drelease-small --build-file build-run.zig -Dtarget=$(patsubst $(BUILD)/lrun-%,%,$@)
	@mv $(BUILD)/lrun $@
	@touch $@

###############################################################################
# luax
###############################################################################

LUAX_PACKAGES = tools/luax.lua

$(BUILD)/luax-%: $(BUILD)/lrun-% $(LUAX_PACKAGES) tools/bundle.lua
	@$(call cyan,"BUNDLE",$@)
	@( cat $(word 1,$^); $(LUA) tools/bundle.lua $(LUAX_PACKAGES) ) > $@.tmp
	@mv $@.tmp $@
	@chmod +x $@

###############################################################################
# lpack
###############################################################################

LPACK_PACKAGES = tools/lpack.lua tools/bundle.lua

$(BUILD)/lpack-%: $(BUILD)/lrun-% $(LPACK_PACKAGES) tools/bundle.lua
	@$(call cyan,"BUNDLE",$@)
	@( cat $(word 1,$^); $(LUA) tools/bundle.lua $(LPACK_PACKAGES) ) > $@.tmp
	@mv $@.tmp $@
	@chmod +x $@

###############################################################################
# Archive
###############################################################################

$(BUILD)/luax.tar.xz: README.md $(LPACK_BINARIES) $(LUAX_BINARIES)
	@$(call cyan,"ARCHIVE",$@)
	@tar cJf $@ \
		README.md \
		-C $(abspath $(BUILD)) $(notdir $(LPACK_BINARIES) $(LUAX_BINARIES))

###############################################################################
# Tests (native only)
###############################################################################

TEST_SOURCES = tests/main.lua $(sort $(filter-out test/main.lua,$(wildcard tests/*.lua)))

test: $(BUILD)/test.ok

$(BUILD)/test.ok: $(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT)
	@$(call cyan,"TEST",$^)
	@ARCH=$(ARCH) OS=$(OS) LIBC=$(LIBC) $< Lua is great
	@touch $@

$(BUILD)/test-$(ARCH)-$(OS)-$(LIBC)$(EXT): $(BUILD)/lpack-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(TEST_SOURCES)
	@$(call cyan,"BUNDLE",$@)
	@$(BUILD)/lpack-$(ARCH)-$(OS)-$(LIBC)$(EXT) $(TEST_SOURCES) -o $@
