#!/bin/bash

LUAX_CONFIG_LUA="$1"

cat <<EOF > "$LUAX_CONFIG_LUA"
--@LIB
return {
    version = "$(git describe --tags)",
    date = "$(git show -s --format=%cd --date=format:'%Y-%m-%d')",
    magic_id = "LuaX",
    targets = {"x86_64-linux-musl", "x86_64-linux-gnu", "aarch64-linux-musl", "aarch64-linux-gnu", "x86_64-windows-gnu", "x86_64-macos-none", "aarch64-macos-none"},
}
EOF
