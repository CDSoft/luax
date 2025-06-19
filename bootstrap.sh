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
# https://codeberg.org/cdsoft/luax
######################################################################

######################################################################
# This script installs some dependencies and compile LuaX
######################################################################

set -eu

cd "$(dirname "$0")"

COMPILER="gcc"
BUILDDIR=.build
OUTPUT=build.ninja
ARGS=()

while [ $# -gt 0 ]
do
    case "$1" in
        gcc)    COMPILER=gcc;           ARGS+=("$1") ;;
        clang)  COMPILER=clang;         ARGS+=("$1") ;;
        zig)    COMPILER=zig;           ARGS+=("$1") ;;
        -b)     BUILDDIR="$2"; shift ;;
        -b*)    BUILDDIR="${1:2}" ;;
        -o)     OUTPUT="$2"; shift ;;
        -o*)    OUTPUT="${1:2}" ;;
        *)                              ARGS+=("$1") ;;
    esac
    shift
done

BOOT=$BUILDDIR/boot
LUA=$BOOT/minilua

mkdir -p "$BOOT"

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
            brew install ninja
            ;;
    esac
    found ninja || error "ninja is not installed"
fi

######################################################################
# C compiler
######################################################################

ZIG_URL=$(grep "ZIG_URL *=" build.lua | cut -d= -f2 | tr -d " \",")
ZIG_VERSION=$(grep "ZIG_VERSION *=" build.lua | cut -d= -f2 | tr -d " \",")
ZIG_PATH=$(grep "ZIG_PATH *=" build.lua | cut -d= -f2 | tr -d " \",")
eval "ZIG=$ZIG_PATH/$ZIG_VERSION/zig" # use eval to expand "~"

case "$COMPILER" in
    zig)
        COMPILER="$ZIG cc"
        if ! [ -x "$ZIG" ]
        then
            tools/install_zig.sh "$ZIG_URL" "$ZIG_VERSION" "$ZIG"
            [ -x "$ZIG" ] || error "zig can not be installed"
        fi
        ;;
    *)
        hash "$COMPILER" 2>/dev/null || error "$COMPILER is not installed"
        ;;
esac

######################################################################
# Lua
######################################################################

if ! [ -x "$LUA" ]
then
    echo "Compile $LUA"
    CFLAGS=(
        -pipe
    )
    LDFLAGS=(
        -s
        -lm
    )
    case "$OS" in
        (Linux)     CFLAGS+=(-DLUA_USE_LINUX) ;;
        (Darwin)    CFLAGS+=(-DLUA_USE_MACOSX) ;;
    esac
    LUA_SOURCES=( lua/*.c )
    $COMPILER "${CFLAGS[@]}" "${LUA_SOURCES[@]}" "${LDFLAGS[@]}" -o "$LUA"
fi

######################################################################
# build.ninja
######################################################################

$LUA tools/luax.lua tools/bang.luax \
    -g "$LUA tools/luax.lua tools/bang.luax" \
    -q \
    -b "$BUILDDIR" \
    build.lua -o "$OUTPUT" \
    -- "${ARGS[@]}"

######################################################################
# LuaX
######################################################################

ninja -f "$OUTPUT" compile
