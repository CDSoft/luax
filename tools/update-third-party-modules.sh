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

TMP="$1"

update_all()
{
    update_lua          5.4.6
    update_lcomplex     100
    update_limath       104
    update_lqmath       105
    update_lmathx
    update_luasocket    3.1.0
    update_lpeg         1.1.0
    update_argparse     master
    update_inspect      master
    update_serpent      master
    update_lz4          release
}

update_lua()
{
    local LUA_VERSION="$1"
    local LUA_ARCHIVE="lua-$LUA_VERSION.tar.gz"
    local LUA_URL="https://www.lua.org/ftp/$LUA_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LUA_URL" -O "$TMP/$LUA_ARCHIVE"

    rm -rf lua
    mkdir -p lua
    tar -xzf "$TMP/$LUA_ARCHIVE" -C lua --exclude=Makefile --strip-components=2 "lua-$LUA_VERSION/src"
}

update_lcomplex()
{
    local LCOMPLEX_VERSION="$1"
    local LCOMPLEX_ARCHIVE="lcomplex-$LCOMPLEX_VERSION.tar.gz"
    local LCOMPLEX_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LCOMPLEX_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LCOMPLEX_URL" -O "$TMP/$LCOMPLEX_ARCHIVE"

    rm -rf ext/c/lcomplex
    tar -xzf "$TMP/$LCOMPLEX_ARCHIVE" -C ext/c --exclude=Makefile --exclude=test.lua
    mv "ext/c/lcomplex-$LCOMPLEX_VERSION" ext/c/lcomplex
}

update_limath()
{
    local LIMATH_VERSION="$1"
    local LIMATH_ARCHIVE="limath-$LIMATH_VERSION.tar.gz"
    local LIMATH_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LIMATH_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LIMATH_URL" -O "$TMP/$LIMATH_ARCHIVE"

    rm -rf ext/c/limath
    tar -xzf "$TMP/$LIMATH_ARCHIVE" -C ext/c --exclude=Makefile --exclude=test.lua
    mv "ext/c/limath-$LIMATH_VERSION" ext/c/limath
    sed -i 's@"imath.h"@"src/imath.h"@' ext/c/limath/limath.c
}

update_lqmath()
{
    local LQMATH_VERSION="$1"
    local LQMATH_ARCHIVE="lqmath-$LQMATH_VERSION.tar.gz"
    local LQMATH_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LQMATH_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LQMATH_URL" -O "$TMP/$LQMATH_ARCHIVE"

    rm -rf ext/c/lqmath
    tar -xzf "$TMP/$LQMATH_ARCHIVE" -C ext/c --exclude=Makefile --exclude=test.lua
    mv "ext/c/lqmath-$LQMATH_VERSION" ext/c/lqmath
    sed -i 's@"imrat.h"@"src/imrat.h"@' ext/c/lqmath/lqmath.c
}

update_lmathx()
{
    local LMATHX_ARCHIVE=lmathx.tar.gz
    local LMATHX_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/5.3/$LMATHX_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LMATHX_URL" -O "$TMP/$LMATHX_ARCHIVE"

    rm -rf ext/c/mathx
    tar -xzf "$TMP/$LMATHX_ARCHIVE" -C ext/c --exclude=Makefile --exclude=test.lua
}

update_luasocket()
{
    local LUASOCKET_VERSION="$1"
    local LUASOCKET_ARCHIVE="luasocket-$LUASOCKET_VERSION.zip"
    local LUASOCKET_URL="https://github.com/lunarmodules/luasocket/archive/refs/tags/v$LUASOCKET_VERSION.zip"

    mkdir -p "$TMP"
    wget "$LUASOCKET_URL" -O "$TMP/$LUASOCKET_ARCHIVE"

    rm -rf ext/c/luasocket
    mkdir ext/c/luasocket
    unzip -j "$TMP/$LUASOCKET_ARCHIVE" "luasocket-$LUASOCKET_VERSION/src/*" -d ext/c/luasocket
    echo "--@LIB=socket.ftp"     >> ext/c/luasocket/ftp.lua
    echo "--@LIB=socket.headers" >> ext/c/luasocket/headers.lua
    echo "--@LIB=socket.http"    >> ext/c/luasocket/http.lua
    echo "--@LIB=socket.smtp"    >> ext/c/luasocket/smtp.lua
    echo "--@LIB=socket.tp"      >> ext/c/luasocket/tp.lua
    echo "--@LIB=socket.url"     >> ext/c/luasocket/url.lua
}

update_lpeg()
{
    local LPEG_VERSION="$1"
    local LPEG_ARCHIVE="lpeg-$LPEG_VERSION.tar.gz"
    local LPEG_URL="http://www.inf.puc-rio.br/~roberto/lpeg/$LPEG_ARCHIVE"

    mkdir -p "$TMP"
    wget "$LPEG_URL" -O "$TMP/$LPEG_ARCHIVE"

    rm -rf ext/c/lpeg
    tar xzf "$TMP/$LPEG_ARCHIVE" -C ext/c --exclude=HISTORY --exclude=*.gif --exclude=*.html --exclude=makefile --exclude=test.lua
    mv "ext/c/lpeg-$LPEG_VERSION" ext/c/lpeg
    echo "--@LIB" >> ext/c/lpeg/re.lua
}

update_argparse()
{
    local ARGPARSE_VERSION="$1"
    local ARGPARSE_ARCHIVE="argparse-$ARGPARSE_VERSION.zip"
    local ARGPARSE_URL="https://github.com/luarocks/argparse/archive/refs/heads/$ARGPARSE_VERSION.zip"

    mkdir -p "$TMP"
    wget "$ARGPARSE_URL" -O "$TMP/$ARGPARSE_ARCHIVE"

    rm -f ext/lua//argparse/argparse.lua
    unzip -j -o "$TMP/$ARGPARSE_ARCHIVE" '*/argparse.lua' -d ext/lua//argparse
}

update_inspect()
{
    local INSPECT_VERSION="$1"
    local INSPECT_ARCHIVE="inspect-$INSPECT_VERSION.zip"
    local INSPECT_URL="https://github.com/kikito/inspect.lua/archive/refs/heads/$INSPECT_VERSION.zip"

    mkdir -p "$TMP"
    wget "$INSPECT_URL" -O "$TMP/$INSPECT_ARCHIVE"

    rm -f ext/lua//inspect/inspect.lua
    unzip -j "$TMP/$INSPECT_ARCHIVE" '*/inspect.lua' -d ext/lua//inspect
    echo "--@LIB" >> ext/lua//inspect/inspect.lua
}

update_serpent()
{
    local SERPENT_VERSION="$1"
    local SERPENT_ARCHIVE="serpent-$SERPENT_VERSION.zip"
    local SERPENT_URL="https://github.com/pkulchenko/serpent/archive/refs/heads/$SERPENT_VERSION.zip"

    mkdir -p "$TMP"
    wget "$SERPENT_URL" -O "$TMP/$SERPENT_ARCHIVE"

    rm -f ext/lua//serpent/serpent.lua
    unzip -j "$TMP/$SERPENT_ARCHIVE" '*/serpent.lua' -d ext/lua//serpent
    sed -i -e 's/(loadstring or load)/load/g'                   \
           -e '/^ *if setfenv then setfenv(f, env) end *$/d'    \
           ext/lua//serpent/serpent.lua
    echo "--@LIB" >> ext/lua//serpent/serpent.lua
}

update_lz4()
{
    local LZ4_VERSION="$1"
    local LZ4_ARCHIVE="lz4-$LZ4_VERSION.zip"
    local LZ4_URL="https://github.com/lz4/lz4/archive/refs/heads/$LZ4_VERSION.zip"

    mkdir -p "$TMP"
    wget "$LZ4_URL" -O "$TMP/$LZ4_ARCHIVE"

    rm -rf ext/c/lz4
    mkdir -p ext/c/lz4/lib ext/c/lz4/programs
    unzip -j "$TMP/$LZ4_ARCHIVE" '*/lib/*.[ch]' '*/lib/LICENSE' -d ext/c/lz4/lib
    unzip -j "$TMP/$LZ4_ARCHIVE" '*/programs/*.[ch]' '*/programs/COPYING' -d ext/c/lz4/programs
}

update_all
