#!/bin/bash

LUA=.cache/lua

LUA_PATH="lib/luax/?.lua;luax/?.lua;$(dirname "$1")/?.lua;./?.lua" \
$LUA luax/luax.lua "$@"
