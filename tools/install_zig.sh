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
# https://github.com/cdsoft/luax

set -e

ZIG_VERSION="$1"
ZIG="$2"

found()
{
    hash "$@" 2>/dev/null
}

download()
{
    local URL="$1"
    local OUTPUT="$2"
    echo "Downloading $URL"
    if ! found curl
    then
        echo "ERROR: curl not found"
        exit 1
    fi
    curl -L "$URL" -o "$OUTPUT" --progress-bar --fail
}

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

if ! [ -x "$ZIG" ]
then
    mkdir -p "$(dirname "$ZIG")"
    download "$ZIG_URL" "$(dirname "$ZIG")/$ZIG_ARCHIVE"

    tar xJf "$(dirname "$ZIG")/$ZIG_ARCHIVE" -C "$(dirname "$ZIG")" --strip-components 1
    rm "$(dirname "$ZIG")/$ZIG_ARCHIVE"
fi

touch "$ZIG"
