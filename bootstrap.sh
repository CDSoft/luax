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
    echo -e "\n\e[44m$*\e[0m\n"
}

warn()
{
    echo -e "\n\e[41m$*\e[0m\n"
}

######################################################################
info "Step 0: install dependencies"
######################################################################

found()
{
    hash "$@" 2>/dev/null
}

if (! found ninja || ! found cc) 2>/dev/null
then
    found dnf    && sudo dnf install -y ninja-build gcc
    found apt    && sudo apt install -f -y ninja-build gcc
    found brew   && sudo brew install ninja gcc
    found pacman && sudo pacman -S --noconfirm ninja gcc
fi

found ninja || warn "ERROR: ninja is not installed"
found cc    || warn "ERROR: gcc or clang is not installed"

######################################################################
info "Step 1: bootstrap a Lua interpreter and generate build.ninja"
######################################################################

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
