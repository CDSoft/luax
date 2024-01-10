#!/bin/bash

LUAX_CONFIG_H="$1"

cat <<EOF > "$LUAX_CONFIG_H"
#pragma once
#define LUAX_VERSION "$(git describe --tags)"
#define LUAX_DATE "$(git show -s --format=%cd --date=format:'%Y-%m-%d')"
#define LUAX_COPYRIGHT "LuaX "LUAX_VERSION"  Copyright (C) 2021-$(git show -s --format=%cd --date=format:'%Y') cdelord.fr/luax"
#define LUAX_AUTHORS "Christophe Delord"
EOF
