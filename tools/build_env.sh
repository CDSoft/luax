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
# http://cdelord.fr/luax

ARCH="$(uname -m)"
case "$ARCH" in
    (i386)  ARCH=x86 ;;
    (i486)  ARCH=x86 ;;
    (i586)  ARCH=x86 ;;
    (i686)  ARCH=x86 ;;
    (arm64) ARCH=aarch64 ;;
esac

case "$(uname -s)" in
    (Linux)  OS=linux ;;
    (Darwin) OS=macos ;;
    (MINGW*) OS=windows ;;
    (*)      OS=unknown ;;
esac

case "$OS" in
    (macos) LIBC=none ;;
    (*)     LIBC=gnu ;;
esac

case "$OS" in
    (windows) EXT=".exe" ;;
    (*)       EXT="" ;;
esac

export ARCH
export OS
export LIBC
export EXT

case "$OS" in
    (linux) LUA_CFLAGS="-DLUA_USE_LINUX" ;;
    (macos) LUA_CFLAGS="-DLUA_USE_MACOSX" ;;
    (*)     LUA_CFLAGS="" ;;
esac

export LUA_CFLAGS

export CRYPT_KEY=${CRYPT_KEY:-"LuaX"}
