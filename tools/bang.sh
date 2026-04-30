#!/bin/bash

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
# https://codeberg.org/cdsoft/luax

# This script install LuaX dependencies
# and builds a standard Lua interpreter use to execute bang

set -eu

ZIG=.cache/zig/zig
LUA=.cache/lua

##############################################################################
# Dependencies (contributions are welcome)
##############################################################################

DEPS=(
    ninja
    curl
    minisign
)

found() {
    command -v "$1" > /dev/null
}

DEPS_FOUND=true
for dep in "${DEPS[@]}"; do
    found "$dep" || DEPS_FOUND=false
done

if ! $DEPS_FOUND; then
    echo "Installing dependancies..."
    case $(uname -s) in
        Linux)
            if   found dnf;    then sudo dnf install -y ninja-build curl minisign
            elif found apt;    then sudo apt install -f -y ninja-build curl minisign
            elif found pacman; then sudo pacman -S --noconfirm ninja curl minisign
            fi
            ;;
        Darwin)
            brew install ninja curl minisign
            ;;
    esac
fi

##############################################################################
# Zig
##############################################################################

tools/install_zig.sh $ZIG

##############################################################################
# Lua
##############################################################################

cat <<EOF | $ZIG cc -xc -I"$PWD/lua" - -o $LUA-version
#include "lua.h"
#include <stdio.h>
int main(void) {
    printf("%d.%d.%d\n", LUA_VERSION_MAJOR_N, LUA_VERSION_MINOR_N, LUA_VERSION_RELEASE_N);
}
EOF

if ! [ -x $LUA ] || [ "$($LUA -v | awk '{print $2}')" != "$($LUA-version)" ]; then
    CFLAGS=(
        -Os
        -Ilua
    )
    LDFLAGS=(
        -lm
        -s
    )
    case $(uname -s) in
        Linux)  CFLAGS+=( -DLUA_USE_LINUX ) ;;
        Darwin) CFLAGS+=( -DLUA_USE_MACOSX ) ;;
    esac
    echo "Compiling Lua..."
    mkdir -p "$(dirname $LUA)"
    $ZIG cc "${CFLAGS[@]}" lua/*.c "${LDFLAGS[@]}" -o $LUA
fi

##############################################################################
# Run Bang with the standard Lua interpreter
##############################################################################

export LUA_PATH="bang/?.lua;luax/?.lua;./?.lua"

$LUA bang/bang.lua "$@" -g "LUA_PATH=\"$LUA_PATH\" $LUA bang/bang.lua"
