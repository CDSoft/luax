#!/bin/bash

LUAX_CONFIG_LUA="$1"

cat <<EOF > "$LUAX_CONFIG_LUA"
--@LIB
local version = "$(git describe --tags)"
return {
    version = version,
    date = "$(git show -s --format=%cd --date=format:'%Y-%m-%d')",
    copyright = "LuaX "..version.."  Copyright (C) 2021-$(git show -s --format=%cd --date=format:'%Y') cdelord.fr/luax",
    authors = "Christophe Delord",
    magic_id = "LuaX",
    targets = {"x86_64-linux-musl", "x86_64-linux-gnu", "aarch64-linux-musl", "aarch64-linux-gnu", "x86_64-windows-gnu", "x86_64-macos-none", "aarch64-macos-none"},
}
EOF
