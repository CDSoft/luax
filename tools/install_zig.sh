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

set -e

ZIG_VERSION="$1"
ZIG="$2"

if ! [ -x "$ZIG" ]
then

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

    ZIG_ARCHIVE="zig-$OS-$ARCH-$ZIG_VERSION.tar.xz"
    case $ZIG_VERSION in
        *-dev*)     ZIG_URL="https://ziglang.org/builds/$ZIG_ARCHIVE" ;;
        *)          ZIG_URL="https://ziglang.org/download/$ZIG_VERSION/$ZIG_ARCHIVE" ;;
    esac

    mkdir -p "$(dirname "$ZIG")"
    wget "$ZIG_URL" -O "$(dirname "$ZIG")/$ZIG_ARCHIVE"

    tar xJf "$(dirname "$ZIG")/$ZIG_ARCHIVE" -C "$(dirname "$ZIG")" --strip-components 1
    mkdir -p C "$(dirname "$ZIG")/cache"

fi

touch "$ZIG"
