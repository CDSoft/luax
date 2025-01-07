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

cd "$(git rev-parse --show-toplevel)"

check()
{
    echo "# $*"
    ninja clean || true
    ./bootstrap.sh "$@" && ninja all
}

check fast gcc
check fast gcc lto
check fast gcc strip
check fast gcc ssl
check fast clang
check fast clang lto
check fast clang strip
check fast clang ssl
check fast zig
check fast zig lto
check fast zig strip
check fast zig cross
check fast zig ssl
check fast zig ssl cross

check small gcc
check small gcc strip
check small clang
check small clang strip
check small zig
check small zig strip

check debug gcc
check debug gcc strip
check debug clang
check debug clang strip
check debug zig
check debug zig strip

check debug san

# The last check shall restore the default build configuration
check
