#!/bin/bash

VERSION=$(git describe --tags)
DATE=$(git show -s --format=%cd --date=format:'%Y-%m-%d')
YEAR=$(git show -s --format=%cd --date=format:'%Y')

cat <<EOF
--@LIB
local version = "$VERSION"
return {
    version = version,
    date = "$DATE",
    copyright = "LuaX "..version.."  Copyright (C) 2021-$YEAR $URL",
    authors = "$AUTHORS",
}
EOF
