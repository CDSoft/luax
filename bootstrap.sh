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
info "Step 1: OS detection"
######################################################################

OS="$(uname -s)"

######################################################################
info "Step 2: Ninja"
######################################################################

if ! found ninja
then
    echo "Install ninja"
    case "$OS" in
        (Linux)     if found dnf; then sudo dnf install -y ninja-build
                    elif found apt; then sudo apt install -f -y ninja-build
                    elif found pacman; then sudo pacman -S --noconfirm ninja
                    fi
                    ;;
        (Darwin)    sudo brew install ninja ;;
    esac
    found ninja || error "ninja is not installed"
fi

######################################################################
info "Step 3: Zig"
######################################################################

ZIG_VERSION=0.13.0
ZIG=~/.local/opt/zig/$ZIG_VERSION/zig

[ -x $ZIG ] || tools/install_zig.sh $ZIG_VERSION $ZIG
[ -x $ZIG ] || error "zig can not be installed"

######################################################################
info "Step 4: Lua"
######################################################################

case "$OS" in
    (Linux)     CFLAGS=(-DLUA_USE_LINUX) ;;
    (Darwin)    CFLAGS=(-DLUA_USE_MACOSX) ;;
    (*)         CFLAGS=() ;;
esac

LUA_SOURCES=( lua/*.c )

$ZIG cc -pipe -s -Oz "${CFLAGS[@]}" "${LUA_SOURCES[@]}" -o $LUA

######################################################################
info "Step 5: build.ninja"
######################################################################

$LUA tools/bang.lua -q build.lua -o build.ninja -- "$@"

######################################################################
info "Step 6: LuaX"
######################################################################

ninja compile

cat <<EOF

LuaX build succeeded.
Just run « ninja install » to actually install LuaX.
EOF
