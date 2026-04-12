#!/bin/bash

LUA=.cache/lua

export LUA_PATH="lib/luax/?.lua;lsvg/?.lua;./?.lua"
$LUA lsvg/lsvg.lua "$@"
