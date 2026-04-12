#!/bin/bash

LUA=.cache/lua

if ! [ -x $LUA ]; then
    CFLAGS=(
        -Ilua
    )
    LDFLAGS=(
        -lm
    )
    case $(uname -s) in
        Linux)  CFLAGS+=( -DLUA_USE_LINUX ) ;;
        Darwin) CFLAGS+=( -DLUA_USE_MACOSX ) ;;
    esac
    echo "Compiling Lua..."
    mkdir -p "$(dirname $LUA)"
    ${CC:-cc} "${CFLAGS[@]}" lua/*.c "${LDFLAGS[@]}" -o $LUA
fi

export LUA_PATH="lib/luax/?.lua;bang/?.lua;./?.lua"
$LUA bang/bang.lua "$@" -g "LUA_PATH=\"$LUA_PATH\" $LUA bang/bang.lua"
