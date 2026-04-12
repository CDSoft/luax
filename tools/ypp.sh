#!/bin/bash

LUA=.cache/lua

export LUA_PATH="lib/luax/?.lua;ypp/?.lua;./?.lua"
$LUA ypp/ypp.lua "$@"
