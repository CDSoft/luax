#!/bin/bash

VERSION=$(git describe --tags)
DATE=$(git show -s --format=%cd --date=format:'%Y-%m-%d')
YEAR=$(git show -s --format=%cd --date=format:'%Y')

cat <<EOF
#pragma once
#define LUAX_VERSION "$VERSION"
#define LUAX_DATE "$DATE"
#define LUAX_COPYRIGHT "LuaX "LUAX_VERSION"  Copyright (C) 2021-$YEAR $URL"
#define LUAX_AUTHORS "$AUTHORS"
EOF
