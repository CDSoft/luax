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
    #update_lua          5.4.6
    update_lua-git      v5.4
    update_lcomplex     100
    update_limath       105
    update_lqmath       107
    update_lmathx
    update_luasocket    3.1.0
    update_lpeg         1.1.0
    update_argparse     master
    update_serpent      master
    update_lz4          release
    update_cbor
    update_linenoise    utf8-support # switch to "master" when the UTF-8 support is merged
    #update_json         master
    update_dkjson       2.7
}

found()
{
    hash "$@" 2>/dev/null
}

download()
{
    local URL="$1"
    local OUTPUT="$2"
    echo "Downloading $URL"
    if found curl
    then
        curl -L "$URL" -o "$OUTPUT" --progress-bar --fail
        return
    fi
    if found wget
    then
        wget "$URL" -O "$OUTPUT"
        return
    fi
    echo "ERROR: curl or wget not found"
    exit 1
}

update_lua()
{
    local LUA_VERSION="$1"
    local LUA_ARCHIVE="lua-$LUA_VERSION.tar.gz"
    local LUA_URL="https://www.lua.org/ftp/$LUA_ARCHIVE"

    mkdir -p "$TMP"
    download "$LUA_URL" "$TMP/$LUA_ARCHIVE"

    rm -rf lua
    mkdir -p lua
    tar -xzf "$TMP/$LUA_ARCHIVE" -C lua --exclude=Makefile --exclude=lua.hpp --strip-components=2 "lua-$LUA_VERSION/src"
}

update_lua-git()
{
    local LUA_VERSION="$1"
    local LUA_ARCHIVE="lua-$LUA_VERSION.zip"
    local LUA_URL="https://codeload.github.com/lua/lua/zip/refs/heads/$LUA_VERSION"

    mkdir -p "$TMP"
    download "$LUA_URL" "$TMP/$LUA_ARCHIVE"

    rm -rf lua "$TMP/lua"
    mkdir -p lua
    unzip "$TMP/$LUA_ARCHIVE" -d "$TMP/lua"
    mv "$TMP"/lua/*/l*.[ch] lua/
    rm lua/ltests.[ch]
}

update_lcomplex()
{
    local LCOMPLEX_VERSION="$1"
    local LCOMPLEX_ARCHIVE="lcomplex-$LCOMPLEX_VERSION.tar.gz"
    local LCOMPLEX_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LCOMPLEX_ARCHIVE"

    mkdir -p "$TMP"
    download "$LCOMPLEX_URL" "$TMP/$LCOMPLEX_ARCHIVE"

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
    download "$LIMATH_URL" "$TMP/$LIMATH_ARCHIVE"

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
    download "$LQMATH_URL" "$TMP/$LQMATH_ARCHIVE"

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
    download "$LMATHX_URL" "$TMP/$LMATHX_ARCHIVE"

    rm -rf ext/c/mathx
    tar -xzf "$TMP/$LMATHX_ARCHIVE" -C ext/c --exclude=Makefile --exclude=test.lua
}

update_luasocket()
{
    local LUASOCKET_VERSION="$1"
    local LUASOCKET_ARCHIVE="luasocket-$LUASOCKET_VERSION.zip"
    local LUASOCKET_URL="https://github.com/lunarmodules/luasocket/archive/refs/tags/v$LUASOCKET_VERSION.zip"

    mkdir -p "$TMP"
    download "$LUASOCKET_URL" "$TMP/$LUASOCKET_ARCHIVE"

    rm -rf ext/c/luasocket
    mkdir ext/c/luasocket
    unzip -j "$TMP/$LUASOCKET_ARCHIVE" "luasocket-$LUASOCKET_VERSION/src/*" -x "*/src/makefile" -d ext/c/luasocket
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
    download "$LPEG_URL" "$TMP/$LPEG_ARCHIVE"

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
    download "$ARGPARSE_URL" "$TMP/$ARGPARSE_ARCHIVE"

    rm -f ext/lua/argparse/argparse.lua
    unzip -j -o "$TMP/$ARGPARSE_ARCHIVE" '*/argparse.lua' -d ext/lua/argparse
}

update_serpent()
{
    local SERPENT_VERSION="$1"
    local SERPENT_ARCHIVE="serpent-$SERPENT_VERSION.zip"
    local SERPENT_URL="https://github.com/pkulchenko/serpent/archive/refs/heads/$SERPENT_VERSION.zip"

    mkdir -p "$TMP"
    download "$SERPENT_URL" "$TMP/$SERPENT_ARCHIVE"

    rm -f ext/lua/serpent/serpent.lua
    unzip -j "$TMP/$SERPENT_ARCHIVE" '*/serpent.lua' -d ext/lua/serpent
    sed -i -e 's/(loadstring or load)/load/g'                   \
           -e '/^ *if setfenv then setfenv(f, env) end *$/d'    \
           ext/lua/serpent/serpent.lua
    echo "--@LIB" >> ext/lua/serpent/serpent.lua
}

update_lz4()
{
    local LZ4_VERSION="$1"
    local LZ4_ARCHIVE="lz4-$LZ4_VERSION.zip"
    local LZ4_URL="https://github.com/lz4/lz4/archive/refs/heads/$LZ4_VERSION.zip"

    mkdir -p "$TMP"
    download "$LZ4_URL" "$TMP/$LZ4_ARCHIVE"

    rm -rf ext/c/lz4
    mkdir -p ext/c/lz4/lib ext/c/lz4/programs
    unzip -j "$TMP/$LZ4_ARCHIVE" '*/lib/*.[ch]' '*/lib/LICENSE' -d ext/c/lz4/lib
    unzip -j "$TMP/$LZ4_ARCHIVE" '*/programs/*.[ch]' '*/programs/COPYING' -d ext/c/lz4/programs
}

update_cbor()
{
    local CBOR_ARCHIVE=lua-cbor.tar.gz
    local CBOR_URL="https://code.zash.se/lua-cbor/archive/tip.tar.gz"

    mkdir -p "$TMP"
    download "$CBOR_URL" "$TMP/$CBOR_ARCHIVE"

    rm -rf ext/lua/cbor
    mkdir -p ext/lua/cbor
    tar -xzf "$TMP/$CBOR_ARCHIVE" -C ext/lua/cbor
    mv ext/lua/cbor/lua-cbor-*/cbor.lua ext/lua/cbor/
    mv ext/lua/cbor/lua-cbor-*/README.* ext/lua/cbor/
    mv ext/lua/cbor/lua-cbor-*/COPYING ext/lua/cbor/
    rm -rf ext/lua/cbor/lua-cbor-*
    echo "--@LIB" >> ext/lua/cbor/cbor.lua

    patch -p1 <<EOF
diff --git a/ext/lua/cbor/cbor.lua b/ext/lua/cbor/cbor.lua
index 2b6cc0b..322f8ef 100644
--- a/ext/lua/cbor/cbor.lua
+++ b/ext/lua/cbor/cbor.lua
@@ -230,6 +230,7 @@ function encoder.table(t, opts)
 			return encode_t(t, opts);
 		end
 	end
+    local custom_pairs = opts and opts.pairs or pairs
 	-- the table is encoded as an array iff when we iterate over it,
 	-- we see successive integer keys starting from 1.  The lua
 	-- language doesn't actually guarantee that this will be the case
@@ -240,7 +241,7 @@ function encoder.table(t, opts)
 	-- back to a map with integer keys, which becomes a bit larger.
 	local array, map, i, p = { integer(#t, 128) }, { "\191" }, 1, 2;
 	local is_array = true;
-	for k, v in pairs(t) do
+	for k, v in custom_pairs(t) do
 		is_array = is_array and i == k;
 		i = i + 1;

@@ -265,8 +266,9 @@ function encoder.array(t, opts)
 end

 function encoder.map(t, opts)
+    local custom_pairs = opts and opts.pairs or pairs
 	local map, p, len = { "\191" }, 2, 0;
-	for k, v in pairs(t) do
+	for k, v in custom_pairs(t) do
 		map[p], p = encode(k, opts), p + 1;
 		map[p], p = encode(v, opts), p + 1;
 		len = len + 1;
@@ -280,8 +282,9 @@ encoder.dict = encoder.map; -- COMPAT
 function encoder.ordered_map(t, opts)
 	local map = {};
 	if not t[1] then -- no predefined order
+        local custom_pairs = opts and opts.pairs or pairs
 		local i = 0;
-		for k in pairs(t) do
+		for k in custom_pairs(t) do
 			i = i + 1;
 			map[i] = k;
 		end
EOF
}

update_linenoise()
{
    local LINENOISE_REPO="yhirose/linenoise" # switch to "antirez/linenoise" when the UTF-8 support is merged
    local LINENOISE_VERSION="$1"
    local LINENOISE_ARCHIVE="linenoise-$LINENOISE_VERSION.zip"
    local LINENOISE_URL="https://github.com/$LINENOISE_REPO/archive/refs/heads/$LINENOISE_VERSION.zip"

    mkdir -p "$TMP"
    download "$LINENOISE_URL" "$TMP/$LINENOISE_ARCHIVE"

    rm -rf ext/c/linenoise
    mkdir -p ext/c/linenoise
    unzip -j "$TMP/$LINENOISE_ARCHIVE" '*/linenoise.[ch]' '*/encodings/*.[ch]' '*/LICENSE' -d ext/c/linenoise
    sed -i                                                              \
        -e 's/case ENTER:/case ENTER: case 10:/'                        \
        -e 's/TCSAFLUSH/TCSADRAIN/'                                     \
        ext/c/linenoise/linenoise.c
}

update_json()
{
    local JSON_REPO=rxi/json.lua
    local JSON_VERSION="$1"
    local JSON_ARCHIVE="json-$JSON_VERSION.zip"
    local JSON_URL="https://github.com/$JSON_REPO/archive/refs/heads/$JSON_VERSION.zip"

    mkdir -p "$TMP"
    download "$JSON_URL" "$TMP/$JSON_ARCHIVE"

    rm -rf ext/lua/json
    mkdir -p ext/lua/json
    unzip -j "$TMP/$JSON_ARCHIVE" '*/json.lua' '*/LICENSE' -d ext/lua/json
}

update_dkjson()
{
    local JSON_VERSION="$1"
    local JSON_SCRIPT="dkjson-$JSON_VERSION.lua"
    local JSON_URL="http://dkolf.de/dkjson-lua/$JSON_SCRIPT"

    mkdir -p "$TMP"
    download "$JSON_URL" "$TMP/$JSON_SCRIPT"

    rm -rf ext/lua/json
    mkdir -p ext/lua/json
    cp "$TMP/$JSON_SCRIPT" ext/lua/json/json.lua

    patch -p1 <<EOF
diff --git a/ext/lua/json/json.lua b/ext/lua/json/json.lua
index 7a86724..076f679 100644
--- a/ext/lua/json/json.lua
+++ b/ext/lua/json/json.lua
@@ -321,6 +321,7 @@ encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, s
       local order = valmeta and valmeta.__jsonorder or globalorder
       if order then
         local used = {}
+        if type(order) == "function" then order = order(value) end
         n = #order
         for i = 1, n do
           local k = order[i]
EOF
}

update_all
