#!/bin/bash

LUAX_CONFIG_H="$1"

cat <<EOF > "$LUAX_CONFIG_H"
#pragma once
#define LUAX_VERSION "$(git describe --tags)"
#define LUAX_DATE "$(git show -s --format=%cd --date=format:'%Y-%m-%d')"
#define LUAX_CRYPT_KEY "$CRYPT_KEY"
#define LUAX_MAGIC_ID "LuaX"
EOF
