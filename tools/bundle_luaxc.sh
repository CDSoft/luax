#!/bin/bash

# This file is part of luax.
#
# luax is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# luax is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with luax.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about luax you can visit
# http://cdelord.fr/luax

set -e

#####################################################################
# Compile luax
#####################################################################

ZIG_VERSION=0.11.0
KEY=LuaX
OUTPUT=
while [ -n "$1" ]
do
    case "$1" in
        -o)     OUTPUT="$2"; shift 2;;
        -zig)   ZIG_VERSION="$2"; shift 2;;
        -k)     KEY="$2"; shift 2;;
        *)      echo "$1: unknown argument"; exit 1;;
    esac
done

if [ -z "$OUTPUT" ]
then
    echo "Output argument missing"
    exit 1
fi

figlet Bootstrap
ninja -f bootstrap.ninja

figlet Compile
.build/boot/lua tools/bang.lua -- key="$KEY"
ninja compile

eval "$(.build/bin/luax env)"

#####################################################################
# Get target list
#####################################################################

eval "TARGETS=( $( luax -l F -l sys -e 'print(F.map(F.partial(F.nth, "name"), sys.targets):unwords())' ) )"

#####################################################################
# Compile LuaX libraries for all targets
#####################################################################

ARCHIVE=.build/luaxc/archive
mkdir -p $ARCHIVE

for target in "${TARGETS[@]}"
do
    figlet -t "$target"

    luax tools/bang.lua -o ".build/build-$target.ninja" -- "$target" key="$KEY"

    (   PREFIX="$ARCHIVE/$target" ninja -f ".build/build-$target.ninja" install
        rm -f ".build/build-$target.ninja"

        OBJ=$ARCHIVE/$target/obj

        mkdir -p "$OBJ"
        cp ".build/$target/tmp/lib"/*.a "$OBJ"
        cp ".build/$target/tmp/obj/luax"/*.o "$OBJ"
        cp ".build/$target/tmp"/luax_config.{h,lua} "$OBJ"
    ) &

done

wait

mkdir -p "$ARCHIVE/luax"
cp luax/*.lua "$ARCHIVE/luax"

#####################################################################
# LuaXC script + precompiled library archive
#####################################################################

figlet "Archive"
tar cJf .build/luaxc/luaxc.tar.xz .build/luaxc/archive --transform "s#$ARCHIVE##"

cat <<EOF > .build/bin/luaxc
$(sed '20,$d' "$0")

set -e

VERSION="$(git describe --tags)"
ZIG_VERSION="$ZIG_VERSION"

CACHE=\$HOME/.local/var/cache/luax

usage()
{
    cat <<END_OF_HELP
LuaX Compiler \$VERSION

\$(basename "\$0") [-t target] -o output inputs
    Compile and link "inputs" with the LuaX runtime
    of the target "target".
    The default target is the host.

\$(basename "\$0") help
    Show this help text.

\$(basename "\$0") clean
    Clean the LuaXC cache.

\$(basename "\$0") install [-t target] [-p prefix]
    Install LuaX for the target "target"
    in "prefix"/bin and "prefix"/lib.
    The default prefix is "~/.local".

END_OF_HELP
    exit 0
}

clean()
{
    echo "Clean \$CACHE"
    rm -rf "\$CACHE"
    exit 0
}

case "\$1" in
    help)       usage ;;
    clean)      clean ;;
    install)    COMMAND=install ;;
    *)          COMMAND=compile ;;
esac

TARGET=
OUTPUT=
SOURCES=()
PREFIX=\$HOME/.local

while [ -n "\$1" ]
do
    case "\$1" in
        (-o)    OUTPUT=\$(realpath "\$2"); shift 2 ;;
        (-t)    TARGET="\$2"; shift 2 ;;
        (-p)    PREFIX="\$2"; shift 2 ;;
        (-h)    usage ;;
        (*)     SOURCES+=("\$(realpath "\$1")"); shift ;;
    esac
done

ZIG_DIR=\$CACHE/zig/\$ZIG_VERSION
ZIG=\$ZIG_DIR/zig
ZIG_CACHE=\$ZIG_DIR/cache

LUAXC_DIR=\$CACHE/luaxc/\$VERSION/$(echo "$KEY" | md5sum | tr -d " -")

LUAXC_ARCHIVE=\$LUAXC_DIR/luaxc.tar.xz

case "\$(uname -s)" in
    Linux)      HOST_OS=linux ;;
    Darwin)     HOST_OS=macos ;;
    MINGW*)     HOST_OS=windows ;;
    *)          echo "Unsupported OS"; exit 1;;
esac

case "\$(uname -m)" in
    x86_64)     HOST_ARCH=x86_64 ;;
    arm64)      HOST_ARCH=aarch64 ;;
    *)          echo "Unsupported architecture"; exit 1;
esac

case "\$HOST_OS" in
    windows)    ext=".exe" ;;
    *)          ext="" ;;
esac

HOST_TARGET=\$HOST_OS-\$HOST_ARCH
LUAX=\$LUAXC_DIR/\$HOST_TARGET/bin/luax\$ext

if ! [ -x "\$ZIG" ]
then
    ZIG_ARCHIVE="zig-\$HOST_OS-\$HOST_ARCH-\$ZIG_VERSION.tar.xz"
    ZIG_URL="https://ziglang.org/download/\$ZIG_VERSION/\$ZIG_ARCHIVE"

    mkdir -p "\$ZIG_DIR"
    wget "\$ZIG_URL" -O "\$ZIG_DIR/\$ZIG_ARCHIVE"

    tar xJf "\$ZIG_DIR/\$ZIG_ARCHIVE" -C "\$ZIG_DIR" --strip-components 1
    mkdir -p "\$ZIG_CACHE"
fi

export ZIG_GLOBAL_CACHE_DIR=\$ZIG_CACHE/luaxc-global
export ZIG_LOCAL_CACHE_DIR=\$ZIG_CACHE/luaxc-local
export PATH="\$ZIG_DIR:\$PATH"

if ! [ -f "\$LUAX" ]
then
    mkdir -p "\$LUAXC_DIR"
    sed '1,/---*8<---*/d' "\$0" > "\$LUAXC_ARCHIVE"
    tar xJf "\$LUAXC_ARCHIVE" -C "\$LUAXC_DIR"
fi

if ! [ -f "\$LUAX" ]
then
    echo "\$LUAX can not be installed"
    exit 1
fi

eval "\$(\$LUAX env)"

if [ -z "\$TARGET" ]
then
    TARGET=\$HOST_TARGET
fi

if ! [ -d "\$LUAXC_DIR/\$TARGET" ]
then
    echo "\$TARGET: unknown target"
    exit 1
fi

case "\$COMMAND" in
    install)    install -v -D -t "\$PREFIX/bin" "\$LUAXC_DIR/\$TARGET/bin"/*
                install -v -D -t "\$PREFIX/lib" "\$LUAXC_DIR/\$TARGET/lib"/*
                exit
                ;;
esac

TMP=\$(mktemp --tmpdir -d "\$(basename "\$0")-XXXXXX")
trap "rm -rf \$TMP" EXIT

ZIG_TARGET=\$(luax -l F -l sys -e "target = F.filter(function(t) return t.name=='\$TARGET' end, sys.targets):head(); print(target.zig_arch..'-'..target.zig_os..'-'..target.zig_libc)")
ZIG_OPT=(-target "\$ZIG_TARGET")
ZIG_OPT+=(-std=gnu2x)
ZIG_OPT+=(-O3)
ZIG_OPT+=(-fPIC)
ZIG_OPT+=(-s)
ZIG_OPT+=(-lm)
case "\$ZIG_TARGET" in
    *macos*)    ;;
    *)          ZIG_OPT+=(-flto=thin) ;;
esac
case "\$TARGET" in
    *-gnu)  ZIG_OPT+=(-rdynamic) ;;
    *-musl) ;;
    *-none) ZIG_OPT+=(-rdynamic) ;;
esac
case "\$TARGET" in
    windows*)   ZIG_OPT+=(-lws2_32 -ladvapi32) ;;
esac

luax "\$LUAXC_DIR/luax/luax_bundle.lua" -app -c -name="\$OUTPUT" "\${SOURCES[@]}" > "\$TMP/app_bundle.c"
zig cc "\${ZIG_OPT[@]}" "\$LUAXC_DIR/\$TARGET/obj"/*.{o,a} "\$TMP/app_bundle.c" -o "\$OUTPUT"

exit # ------------------------------8<------------------------------
EOF

cat .build/luaxc/luaxc.tar.xz >> .build/bin/luaxc

chmod +x .build/bin/luaxc
