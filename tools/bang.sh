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
TEST32=.cache/test32

##############################################################################
# Dependencies (contributions are welcome)
##############################################################################

DEPS=( ninja curl minisign )

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
# Zig [tag:zig_install]
##############################################################################

tools/install_zig.sh $ZIG

##############################################################################
# Lua [tag:lua_bootstrap]
##############################################################################

FLAGS=( -Os -s -Ilua -lm )
case $(uname -s) in
    Linux)  FLAGS+=( -DLUA_USE_LINUX ) ;;
    Darwin) FLAGS+=( -DLUA_USE_MACOSX ) ;;
esac

OLD_MD5=$(cat $LUA.md5 2>/dev/null || true)
NEW_MD5=$(cat lua/*.c | md5sum)
if [ "$NEW_MD5" != "$OLD_MD5" ]; then
    echo "Compiling $LUA"
    mkdir -p "$(dirname $LUA)"
    $ZIG cc "${FLAGS[@]}" lua/*.c -o $LUA
    echo "$NEW_MD5" > $LUA.md5
fi

##############################################################################
# 32-bit support tester
##############################################################################

OLD_MD5=$(cat $TEST32.md5 2>/dev/null || true)
NEW_MD5=$(cat tools/test32.c | md5sum)
if [ "$NEW_MD5" != "$OLD_MD5" ]; then
    echo "Compiling $TEST32"
    mkdir -p "$(dirname $TEST32)"
    $ZIG cc -target x86-linux-musl "${FLAGS[@]}" tools/test32.c -o $TEST32
    echo "$NEW_MD5" > $TEST32.md5
fi

##############################################################################
# Run Bang with the standard Lua interpreter
##############################################################################

export LUA_PATH="bang/?.lua;luax/?.lua;./?.lua"

$LUA \
    -l luax-package \
    bang/bang.lua -g "LUA_PATH=\"$LUA_PATH\" $LUA -l luax-package bang/bang.lua"
