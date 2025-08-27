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

set -e

ZIG_VERSION="$1"
ZIG="$2"
ZIG_KEY="$3"

ARCH="$(uname -m)"
case "$ARCH" in
    (i386)  ARCH=x86 ;;
    (i486)  ARCH=x86 ;;
    (i586)  ARCH=x86 ;;
    (i686)  ARCH=x86 ;;
    (arm64) ARCH=aarch64 ;;
esac

case "$(uname -s)" in
    (Linux)  OS=linux;   EXT=.tar.xz ;;
    (Darwin) OS=macos;   EXT=.tar.xz ;;
    (MINGW*) OS=windows; EXT=.zip ;;
    (*)      OS=unknown ;;
esac

ZIG_ARCHIVE=zig-$ARCH-$OS-$ZIG_VERSION$EXT

found()
{
    hash "$@" 2>/dev/null
}

download()
{
    local OUTPUT="$1"
    echo "Downloading $ZIG_ARCHIVE"
    if ! found curl
    then
        echo "ERROR: curl not found"
        exit 1
    fi
    if ! found minisign
    then
        echo "ERROR: minisign not found"
        exit 1
    fi
    local MIRRORS
    MIRRORS=$(curl -s https://ziglang.org/download/community-mirrors.txt)
    mapfile -t MIRRORS < <(shuf -e "${MIRRORS[@]}")
    for mirror in "${MIRRORS[@]}"
    do
        echo "Try mirror: $mirror/$ZIG_ARCHIVE"
        if curl -L "$mirror/$ZIG_ARCHIVE?source=luax-zig-setup" -o "$OUTPUT" --progress-bar --fail
        then
            curl -L "$mirror/$ZIG_ARCHIVE.minisig?source=luax-zig-setup" -o "$OUTPUT.minisig" --progress-bar --fail
            minisign -Vm "$OUTPUT" -x "$OUTPUT.minisig" -P "$ZIG_KEY"
            break
        fi
    done
}

if ! [ -x "$ZIG" ]
then
    mkdir -p "$(dirname "$ZIG")"
    download "$(dirname "$ZIG")/$ZIG_ARCHIVE"

    tar xJf "$(dirname "$ZIG")/$ZIG_ARCHIVE" -C "$(dirname "$ZIG")" --strip-components 1
    rm "$(dirname "$ZIG")/$ZIG_ARCHIVE"
    rm "$(dirname "$ZIG")/$ZIG_ARCHIVE.minisig"
fi

touch "$ZIG"
