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

set -ex

ROOT=$(git rev-parse --show-toplevel)
TMP=/tmp/luax-update
mkdir -p $TMP

update_all()
{
    update_lua          5.5.0
    update_lcomplex     100
    update_limath       106
    update_lqmath       108
    update_lmathx
    update_lpeg         1.1.0
    update_argparse     LuaX
    update_serpent      master
    update_cbor
    update_linenoise    master
    update_dkjson       2.8
    update_toml         1.0.0
    update_luasocket    3.1.0
    update_lz4          release
    update_lzlib        1.16
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
    if ! found curl; then
        echo "ERROR: curl not found"
        exit 1
    fi
    curl --insecure -L "$URL" -o "$OUTPUT" --progress-bar --fail
}

update_lua()
{
    local LUA_VERSION="$1"
    local LUA_ARCHIVE="lua-$LUA_VERSION.tar.gz"
    local LUA_URL
    case $LUA_VERSION in
        *-beta) LUA_URL="https://www.lua.org/work/$LUA_ARCHIVE" ;;
        *-rc*)  LUA_URL="https://www.lua.org/work/$LUA_ARCHIVE" ;;
        *)      LUA_URL="https://www.lua.org/ftp/$LUA_ARCHIVE" ;;
    esac

    download "$LUA_URL" "$TMP/$LUA_ARCHIVE"

    rm -rf "$ROOT/lua"
    mkdir -p "$ROOT/lua" "$TMP/lua"
    tar -xaf "$TMP/$LUA_ARCHIVE" -C "$TMP/lua" --exclude=luac.c --strip-components=2 "lua-${LUA_VERSION%-*}/src"
    cp "$TMP"/lua/*.[ch] "$ROOT/lua/"
}

update_lcomplex()
{
    local LCOMPLEX_VERSION="$1"
    local LCOMPLEX_ARCHIVE="lcomplex-$LCOMPLEX_VERSION.tar.gz"
    local LCOMPLEX_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LCOMPLEX_ARCHIVE"

    download "$LCOMPLEX_URL" "$TMP/$LCOMPLEX_ARCHIVE"

    rm -rf "$ROOT/luax/ext/lcomplex"
    mkdir -p "$ROOT/luax/ext/lcomplex" "$TMP/lcomplex"
    tar -xaf "$TMP/$LCOMPLEX_ARCHIVE" -C "$TMP/lcomplex" --exclude=Makefile --exclude=test.lua --strip-components=1
    cp "$TMP"/lcomplex/*.[ch] "$ROOT/luax/ext/lcomplex/"
}

update_limath()
{
    local LIMATH_VERSION="$1"
    local LIMATH_ARCHIVE="limath-$LIMATH_VERSION.tar.gz"
    local LIMATH_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LIMATH_ARCHIVE"

    download "$LIMATH_URL" "$TMP/$LIMATH_ARCHIVE"

    rm -rf "$ROOT/luax/ext/limath"
    mkdir -p "$ROOT/luax/ext/limath" "$TMP/limath"
    tar -xaf "$TMP/$LIMATH_ARCHIVE" -C "$TMP/limath" --exclude=Makefile --exclude=test.lua --strip-components=1
    cp "$TMP"/limath/*.[ch] "$ROOT/luax/ext/limath/"
    cp "$TMP"/limath/src/*.[ch] "$ROOT/luax/ext/limath/"
}

update_lqmath()
{
    local LQMATH_VERSION="$1"
    local LQMATH_ARCHIVE="lqmath-$LQMATH_VERSION.tar.gz"
    local LQMATH_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$LQMATH_ARCHIVE"

    download "$LQMATH_URL" "$TMP/$LQMATH_ARCHIVE"

    rm -rf "$ROOT/luax/ext/lqmath"
    mkdir -p "$ROOT/luax/ext/lqmath" "$TMP/lqmath"
    tar -xaf "$TMP/$LQMATH_ARCHIVE" -C "$TMP/lqmath" --exclude=Makefile --exclude=test.lua --strip-components=1
    cp "$TMP"/lqmath/*.[ch] "$ROOT/luax/ext/lqmath/"
    cp "$TMP"/lqmath/src/*.[ch] "$ROOT/luax/ext/lqmath/"

    # imath and qmath shall share the same imath implementation
    if ! diff "$ROOT/luax/ext/limath/imath.h" "$ROOT/luax/ext/lqmath/imath.h"; then
        echo "limath and lqmath use different versions of imath"
        exit 1
    fi
    if ! diff "$ROOT/luax/ext/limath/imath.c" "$ROOT/luax/ext/lqmath/imath.c"; then
        echo "limath and lqmath use different versions of imath"
        exit 1
    fi
    rm "$ROOT/luax/ext/lqmath/imath.c"
}

update_lmathx()
{
    local LMATHX_ARCHIVE=lmathx.tar.gz
    local LMATHX_URL="https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/5.3/$LMATHX_ARCHIVE"

    download "$LMATHX_URL" "$TMP/$LMATHX_ARCHIVE"

    rm -rf "$ROOT/luax/ext/mathx"
    mkdir -p "$ROOT/luax/ext/mathx" "$TMP/mathx"
    tar -xaf "$TMP/$LMATHX_ARCHIVE" -C "$TMP/mathx" --exclude=Makefile --exclude=test.lua --strip-components=1
    cp "$TMP"/mathx/*.[ch] "$ROOT/luax/ext/mathx/"
}

update_lpeg()
{
    local LPEG_VERSION="$1"
    local LPEG_ARCHIVE="lpeg-$LPEG_VERSION.tar.gz"
    local LPEG_URL="https://www.inf.puc-rio.br/~roberto/lpeg/$LPEG_ARCHIVE"

    download "$LPEG_URL" "$TMP/$LPEG_ARCHIVE"

    rm -rf "$ROOT/luax/ext/lpeg"
    mkdir -p "$ROOT/luax/ext/lpeg" "$TMP/lpeg"
    tar xaf "$TMP/$LPEG_ARCHIVE" -C "$TMP/lpeg" --exclude=HISTORY --exclude=*.gif --exclude=*.html --exclude=makefile --exclude=test.lua --strip-components=1
    cp "$TMP"/lpeg/*.{c,h,lua} "$ROOT/luax/ext/lpeg/"
}

update_argparse()
{
    local ARGPARSE_VERSION="$1"
    local ARGPARSE_ARCHIVE="argparse-$ARGPARSE_VERSION.zip"
    local ARGPARSE_URL="https://codeberg.org/cdsoft/argparse/archive/$ARGPARSE_VERSION.zip"

    download "$ARGPARSE_URL" "$TMP/$ARGPARSE_ARCHIVE"

    unzip -o "$TMP/$ARGPARSE_ARCHIVE" -d "$TMP"
    cp "$TMP/argparse/src/argparse.lua" "$ROOT/luax/"
}

update_serpent()
{
    local SERPENT_VERSION="$1"
    local SERPENT_ARCHIVE="serpent-$SERPENT_VERSION.zip"
    local SERPENT_URL="https://github.com/pkulchenko/serpent/archive/refs/heads/$SERPENT_VERSION.zip"

    download "$SERPENT_URL" "$TMP/$SERPENT_ARCHIVE"

    unzip -o "$TMP/$SERPENT_ARCHIVE" -d "$TMP"
    cp "$TMP/serpent-$SERPENT_VERSION/src/serpent.lua" "$ROOT/luax/"
    sed -i -e 's/(loadstring or load)/load/g'                       \
           -e '/^ *if setfenv then setfenv(f, env) end *$/d'        \
           -e "s/'local'/'local', 'global'/"                        \
           -e "s/\(globals\[v\] = g..'.'..k\)/if v==v then \1 end/" \
           "$ROOT/luax/serpent.lua"
    echo "--@LIB" >> "$ROOT/luax/serpent.lua"
}

update_cbor()
{
    local CBOR_REPO="https://code.zash.se/lua-cbor/"

    rm -rf "$TMP/lua-cbor"
    hg clone $CBOR_REPO "$TMP/lua-cbor"

    cp "$TMP/lua-cbor"/cbor.lua "$ROOT/luax/"
    echo "--@LIB" >> "$ROOT/luax/cbor.lua"

    patch -p1 <<EOF
diff --git a/luax/cbor.lua b/luax/cbor.lua
index 2b6cc0b..322f8ef 100644
--- a/luax/cbor.lua
+++ b/luax/cbor.lua
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
    local LINENOISE_REPO="antirez/linenoise"
    local LINENOISE_VERSION="$1"
    local LINENOISE_ARCHIVE="linenoise-$LINENOISE_VERSION.zip"
    local LINENOISE_URL="https://github.com/$LINENOISE_REPO/archive/refs/heads/$LINENOISE_VERSION.zip"

    download "$LINENOISE_URL" "$TMP/$LINENOISE_ARCHIVE"

    rm -rf "$ROOT/luax/ext/linenoise"
    mkdir -p "$ROOT/luax/ext/linenoise"
    unzip -o "$TMP/$LINENOISE_ARCHIVE" -d "$TMP"
    cp "$TMP/linenoise-$LINENOISE_VERSION"/linenoise.[ch] "$ROOT/luax/ext/linenoise/"
    sed -i                                                              \
        -e 's/case ENTER:/case ENTER: case 10:/'                        \
        -e 's/TCSAFLUSH/TCSADRAIN/'                                     \
        "$ROOT/luax/ext/linenoise/linenoise.c"
}

update_dkjson()
{
    local JSON_VERSION="$1"
    local JSON_SCRIPT="dkjson-$JSON_VERSION.lua"
    local JSON_URL="http://dkolf.de/dkjson-lua/$JSON_SCRIPT"

    download "$JSON_URL" "$TMP/$JSON_SCRIPT"

    cp "$TMP/$JSON_SCRIPT" "$ROOT/luax/json.lua"

    patch -p1 <<EOF
diff --git a/luax/json.lua b/luax/json.lua
index 7a86724..076f679 100644
--- a/luax/json.lua
+++ b/luax/json.lua
@@ -321,6 +321,7 @@ encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, s
       local order = valmeta and valmeta.__jsonorder or globalorder
       if order then
         local used = {}
+        if type(order) == "function" then order = order(value) end
         n = #order
         for i = 1, n do
           local k = order[i]
EOF
    rm -f "$ROOT/luax/json.lua.orig"
}

update_toml()
{
    local TOML_REPO=FourierTransformer/tinytoml
    local TOML_VERSION="$1"
    local TOML_ARCHIVE="toml-$TOML_VERSION.zip"
    local TOML_URL="https://github.com/$TOML_REPO/archive/refs/tags/$TOML_VERSION.zip"

    download "$TOML_URL" "$TMP/$TOML_ARCHIVE"

    unzip -o "$TMP/$TOML_ARCHIVE" -d "$TMP"

    cp "$TMP/tinytoml-$TOML_VERSION/tinytoml.lua" "$ROOT/luax/toml.lua"
    patch -p1 <<EOF
diff --git a/luax/toml.lua b/luax/toml.lua
index ef81455..b26e867 100644
--- a/luax/toml.lua
+++ b/luax/toml.lua
@@ -204,7 +204,7 @@ local function _error(sm, message, anchor)
    error(table.concat(error_message))
 end

-
+local F = require "F"
 local _unpack = unpack or table.unpack
 local _tointeger = math.tointeger or tonumber

@@ -1450,7 +1450,7 @@ local function encode_element(element, allow_multiline_strings)
          table.insert(encoded_string, "{")

          local remove_trailing_comma = false
-         for k, v in pairs(element) do
+         for k, v in F.pairs(element) do
             remove_trailing_comma = true
             table.insert(encoded_string, k)
             table.insert(encoded_string, " = ")
@@ -1487,7 +1487,7 @@ end

 local function encoder(input_table, encoded_string, depth, options)
    local printed_table_info = false
-   for k, v in pairs(input_table) do
+   for k, v in F.pairs(input_table) do
       if type(v) ~= "table" or (type(v) == "table" and is_array(v)) then
          if not printed_table_info and #depth > 0 then
             encode_depth(encoded_string, depth)
@@ -1513,7 +1513,7 @@ local function encoder(input_table, encoded_string, depth, options)
          table.insert(encoded_string, "\n")
       end
    end
-   for k, v in pairs(input_table) do
+   for k, v in F.pairs(input_table) do
       if type(v) == "table" and not is_array(v) then
          if next(v) == nil then
             table.insert(depth, escape_key(k))
EOF
}

update_luasocket()
{
    local LUASOCKET_VERSION="$1"
    local LUASOCKET_ARCHIVE="luasocket-$LUASOCKET_VERSION.zip"
    local LUASOCKET_URL="https://github.com/lunarmodules/luasocket/archive/refs/tags/v$LUASOCKET_VERSION.zip"

    download "$LUASOCKET_URL" "$TMP/$LUASOCKET_ARCHIVE"

    rm -rf "$ROOT/luax/ext/luasocket"
    mkdir -p "$ROOT/luax/ext/luasocket"
    unzip -o "$TMP/$LUASOCKET_ARCHIVE" -d "$TMP"
    cp "$TMP/luasocket-$LUASOCKET_VERSION"/src/*.{c,h,lua} "$ROOT/luax/ext/luasocket"

    echo "--@LIB=socket.ftp"     >> "$ROOT/luax/ext/luasocket/ftp.lua"
    echo "--@LIB=socket.headers" >> "$ROOT/luax/ext/luasocket/headers.lua"
    echo "--@LIB=socket.http"    >> "$ROOT/luax/ext/luasocket/http.lua"
    echo "--@LIB=socket.smtp"    >> "$ROOT/luax/ext/luasocket/smtp.lua"
    echo "--@LIB=socket.tp"      >> "$ROOT/luax/ext/luasocket/tp.lua"
    echo "--@LIB=socket.url"     >> "$ROOT/luax/ext/luasocket/url.lua"
}

update_lz4()
{
    local LZ4_VERSION="$1"
    local LZ4_ARCHIVE="lz4-$LZ4_VERSION.zip"
    local LZ4_URL="https://github.com/lz4/lz4/archive/refs/heads/$LZ4_VERSION.zip"

    download "$LZ4_URL" "$TMP/$LZ4_ARCHIVE"

    rm -rf "$ROOT/luax/ext/lz4"
    mkdir -p "$ROOT/luax/ext/lz4"
    unzip -o "$TMP/$LZ4_ARCHIVE" -d "$TMP"
    cp "$TMP/lz4-release"/lib/*.{c,h} "$ROOT/luax/ext/lz4"
}

update_lzlib()
{
    local LZLIB_VERSION="$1"
    local LZLIB_ARCHIVE="lzlib-$LZLIB_VERSION.tar.gz"
    local LZLIB_URL="http://download.savannah.gnu.org/releases/lzip/lzlib/$LZLIB_ARCHIVE"

    download "$LZLIB_URL" "$TMP/$LZLIB_ARCHIVE"

    rm -rf "$ROOT/luax/ext/lzlib"
    mkdir -p "$ROOT/luax/ext/lzlib" "$ROOT/luax/ext/lzlib/inc"
    tar -xzf "$TMP/$LZLIB_ARCHIVE" -C "$TMP"

    cp "$TMP/lzlib-$LZLIB_VERSION"/lzlib.{c,h} "$ROOT/luax/ext/lzlib/"
    cp "$TMP/lzlib-$LZLIB_VERSION"/lzip.h "$ROOT/luax/ext/lzlib/"

    cp "$TMP/lzlib-$LZLIB_VERSION"/cbuffer.c "$ROOT/luax/ext/lzlib/inc"
    cp "$TMP/lzlib-$LZLIB_VERSION"/decoder.{c,h} "$ROOT/luax/ext/lzlib/inc"
    cp "$TMP/lzlib-$LZLIB_VERSION"/encoder*.{c,h} "$ROOT/luax/ext/lzlib/inc"
    cp "$TMP/lzlib-$LZLIB_VERSION"/fast_encoder.{c,h} "$ROOT/luax/ext/lzlib/inc"
}

update_all
