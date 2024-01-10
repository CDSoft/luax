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
}
EOF
