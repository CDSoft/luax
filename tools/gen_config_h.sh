#!/bin/bash

LUAX_CONFIG_H="$1"

cat <<EOF > "$LUAX_CONFIG_H"
#pragma once
#define LUAX_VERSION "$(git describe --tags)"
#define LUAX_DATE "$(git show -s --format=%cd --date=format:'%Y-%m-%d')"
#define LUAX_CRYPT_KEY "\x5d\xec\xc3\xbb\xe8\x40\x6e\x68\x7f\x20\xc2\x39\xf4\xa0\x27\x25"
#define LUAX_MAGIC_ID "LuaX"
EOF
