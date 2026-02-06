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

TITLE=$(tput setaf 253; tput setab 4)
TEXT=$(tput sgr0)

title()
{
    local MSG=$1
    local W=$(($(tput cols) - 4))
    printf "${TITLE}### %-${W}s${TEXT}\n" "$MSG"
}

check()
{
    local ARGS="$*"
    local NAME="${ARGS// /-}"
    test -z "$NAME" && NAME=default_options
    local BUILDDIR=".build/test-all/$NAME"
    title "$*"
    ./bootstrap.sh -b "$BUILDDIR" -o "$BUILDDIR/build.ninja" "$@"
    (
        eval "$("$BUILDDIR/bin/luax" env)"
        ninja -f "$BUILDDIR/build.ninja" test || ninja -f "$BUILDDIR/build.ninja" test
    )
}

check fast gcc ssl lto strip
check fast clang ssl lto strip
check fast zig ssl lto strip cross release

check small gcc
check small clang
check small zig

check debug gcc
check debug clang
check debug zig

check debug san

# The last check shall restore the default build configuration
check
