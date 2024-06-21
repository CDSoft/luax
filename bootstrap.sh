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

info()
{
    echo "# $*"
}

error()
{
    echo "Error: $*"
    exit 1
}

######################################################################
info "Step 0: install dependencies"
######################################################################

ZIG_VERSION=0.13.0
ZIG=~/.local/opt/zig/$ZIG_VERSION/zig

found()
{
    hash "$@" 2>/dev/null
}

if ! found ninja
then
    echo "Install ninja"
    case "$(uname -s)" in
        (Linux)     if found dnf; then sudo dnf install -y ninja-build
                    elif found apt; then sudo apt install -f -y ninja-build
                    elif found pacman; then sudo pacman -S --noconfirm ninja
                    fi
                    ;;
        (Darwin)    sudo brew install ninja ;;
    esac
    found ninja || error "ninja is not installed"
fi

[ -x $ZIG ] || tools/install_zig.sh $ZIG_VERSION $ZIG
[ -x $ZIG ] || error "zig can not be installed"

######################################################################
info "Step 1: bootstrap a Lua interpreter and generate build.ninja"
######################################################################

[ -x $ZIG ] && export CC="$ZIG cc"
ninja -f bootstrap.ninja

######################################################################
info "Step 2: compile LuaX"
######################################################################

ninja compile

######################################################################
info "Step 3: done"
######################################################################

cat <<EOF
LuaX build succeeded.
Just run « ninja install » to actually install LuaX.
EOF
