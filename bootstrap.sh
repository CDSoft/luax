#!/bin/bash
######################################################################
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
######################################################################

######################################################################
# This script installs some dependencies and compile LuaX
######################################################################

set -eu

B=.build/boot
LUA=$B/lua

mkdir -p $B

info()
{
    echo "# $*"
}

error()
{
    echo "Error: $*"
    exit 1
}

found()
{
    hash "$@" 2>/dev/null
}

######################################################################
# OS detection
######################################################################

OS="$(uname -s)"

######################################################################
# Ninja
######################################################################

if ! found ninja
then
    echo "Install ninja"
    case "$OS" in
        (Linux)
            if   found dnf;    then sudo dnf install -y ninja-build
            elif found apt;    then sudo apt install -f -y ninja-build
            elif found pacman; then sudo pacman -S --noconfirm ninja
            fi
            ;;
        (Darwin)
            sudo brew install ninja
            ;;
    esac
    found ninja || error "ninja is not installed"
fi

######################################################################
# Zig
######################################################################

ZIG_VERSION=0.13.0
ZIG=~/.local/opt/zig/$ZIG_VERSION/zig

if ! [ -x $ZIG ]
then
    tools/install_zig.sh $ZIG_VERSION $ZIG
    [ -x $ZIG ] || error "zig can not be installed"
fi

######################################################################
# Lua
######################################################################

if ! [ -x $LUA ]
then
    case "$OS" in
        (Linux)     CFLAGS=(-DLUA_USE_LINUX) ;;
        (Darwin)    CFLAGS=(-DLUA_USE_MACOSX) ;;
        (*)         CFLAGS=() ;;
    esac
    LUA_SOURCES=( lua/*.c )
    $ZIG cc -pipe -s -Oz "${CFLAGS[@]}" "${LUA_SOURCES[@]}" -o $LUA
fi

######################################################################
# build.ninja
######################################################################

$LUA tools/luax.lua tools/bang.luax \
    -g "$LUA tools/luax.lua tools/bang.luax" \
    -q \
    build.lua -o build.ninja \
    -- "$@"

######################################################################
# LuaX
######################################################################

ninja compile
