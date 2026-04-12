#!/bin/bash

# comme luax.sh mais utilise les artéfacts dans le répertoire de build (accès aux loaders)

LUA=.cache/lua

export LUA_PATH=".build/lib/luax/?.lua;.build/bin/?.lua"
$LUA .build/bin/luax.lua "$@"
