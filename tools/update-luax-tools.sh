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

# This script updates bang, lsvg and luax scripts in the tools directory.

set -e

ROOT=$(git rev-parse --show-toplevel)
BANG_DIR=$(dirname "$ROOT")/bang
LSVG_DIR=$(dirname "$ROOT")/lsvg
YPP_DIR=$(dirname "$ROOT")/ypp

if ! [ -d "$BANG_DIR" ]; then echo "bang not found in $BANG_DIR"; exit 1; fi
if ! [ -d "$LSVG_DIR" ]; then echo "lsvg not found in $LSVG_DIR"; exit 1; fi
if ! [ -d "$YPP_DIR" ];  then echo "ypp not found in $YPP_DIR";   exit 1; fi

cd "$ROOT" && ./bootstrap.sh

eval "$("$ROOT"/.build/bin/luax env)"

cd "$BANG_DIR" && luax ./boot.lua              && ninja && cp .build/bang.luax "$ROOT/tools/"
cd "$LSVG_DIR" && luax "$ROOT/tools/bang.luax" && ninja && cp .build/lsvg.luax "$ROOT/tools/"
cd "$YPP_DIR"  && luax "$ROOT/tools/bang.luax" && ninja && cp .build/ypp.luax  "$ROOT/tools/"
