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

cd "$(git rev-parse --show-toplevel)"

RED=41
BLUE=44

say()
{
    local COLOR=$1
    local MSG=$2
    local EOL=$3
    printf "\\e[${COLOR}m### %-$(($(tput cols) - 4))s\\e[0m${EOL}\n" "$MSG"
}

check()
{
    local ARGS="$*"
    local NAME="${ARGS// /-}"
    test -z "$NAME" && NAME=default_options
    local BUILDDIR=".build/test-all/$NAME"
    say $BLUE "$*"
    ./bootstrap.sh -b "$BUILDDIR" -o "$BUILDDIR/build.ninja" "$@"
    (
        eval "$("$BUILDDIR/bin/luax" env)"
        ninja -f "$BUILDDIR/build.ninja" test || ninja -f "$BUILDDIR/build.ninja" test
    )
}

check fast gcc
check fast gcc ssl lz4 lto strip
check fast clang
check fast clang ssl lz4 lto strip
check fast zig
check fast zig ssl lz4 lto strip cross release

check small gcc
check small clang
check small zig

check debug gcc
check debug clang
check debug zig

check debug san

# The last check shall restore the default build configuration
check
