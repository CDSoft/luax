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

# Minimal script to cross-compile Ninja with zig

#set -x

ZIG_VERSION=0.13.0
ZIG=~/.local/opt/zig/$ZIG_VERSION/zig

NINJA_URL=https://github.com/ninja-build/ninja
NINJA_VERSION=v1.12.1
#NINJA_VERSION=master

BUILD=.build
NINJA_REPO=$BUILD/$(basename $NINJA_URL)

FORCE=false
INSTALL=false
for arg in "$@"
do
    case "$arg" in
        (clean)     rm -rf $BUILD
                    exit
                    ;;
        (install)   INSTALL=true
                    ;;
        (-f)        FORCE=true
                    ;;
        (*)         echo "$arg: invalid argument"
                    exit
                    ;;
    esac
done

case "$NINJA_VERSION" in
    v1.12.1)
        SOURCES=(
            "$NINJA_REPO"/src/build_log.cc
            "$NINJA_REPO"/src/build.cc
            "$NINJA_REPO"/src/clean.cc
            "$NINJA_REPO"/src/clparser.cc
            "$NINJA_REPO"/src/dyndep.cc
            "$NINJA_REPO"/src/dyndep_parser.cc
            "$NINJA_REPO"/src/debug_flags.cc
            "$NINJA_REPO"/src/deps_log.cc
            "$NINJA_REPO"/src/disk_interface.cc
            "$NINJA_REPO"/src/edit_distance.cc
            "$NINJA_REPO"/src/eval_env.cc
            "$NINJA_REPO"/src/graph.cc
            "$NINJA_REPO"/src/graphviz.cc
            "$NINJA_REPO"/src/json.cc
            "$NINJA_REPO"/src/line_printer.cc
            "$NINJA_REPO"/src/manifest_parser.cc
            "$NINJA_REPO"/src/metrics.cc
            "$NINJA_REPO"/src/missing_deps.cc
            "$NINJA_REPO"/src/parser.cc
            "$NINJA_REPO"/src/state.cc
            "$NINJA_REPO"/src/status.cc
            "$NINJA_REPO"/src/string_piece_util.cc
            "$NINJA_REPO"/src/util.cc
            "$NINJA_REPO"/src/version.cc
            "$NINJA_REPO"/src/depfile_parser.cc
            "$NINJA_REPO"/src/lexer.cc
            "$NINJA_REPO"/src/ninja.cc
        )
        WIN32_SOURCES=(
            "$NINJA_REPO"/src/subprocess-win32.cc
            "$NINJA_REPO"/src/includes_normalize-win32.cc
            "$NINJA_REPO"/src/msvc_helper-win32.cc
            "$NINJA_REPO"/src/msvc_helper_main-win32.cc
            "$NINJA_REPO"/src/minidump-win32.cc
        )
        POSIX_SOURCES=(
            "$NINJA_REPO"/src/subprocess-posix.cc
        )
        ;;
    master)
        SOURCES=(
            "$NINJA_REPO"/src/build_log.cc
            "$NINJA_REPO"/src/build.cc
            "$NINJA_REPO"/src/clean.cc
            "$NINJA_REPO"/src/clparser.cc
            "$NINJA_REPO"/src/dyndep.cc
            "$NINJA_REPO"/src/dyndep_parser.cc
            "$NINJA_REPO"/src/debug_flags.cc
            "$NINJA_REPO"/src/deps_log.cc
            "$NINJA_REPO"/src/disk_interface.cc
            "$NINJA_REPO"/src/edit_distance.cc
            "$NINJA_REPO"/src/eval_env.cc
            "$NINJA_REPO"/src/graph.cc
            "$NINJA_REPO"/src/graphviz.cc
            "$NINJA_REPO"/src/json.cc
            "$NINJA_REPO"/src/line_printer.cc
            "$NINJA_REPO"/src/manifest_parser.cc
            "$NINJA_REPO"/src/metrics.cc
            "$NINJA_REPO"/src/missing_deps.cc
            "$NINJA_REPO"/src/parser.cc
            "$NINJA_REPO"/src/state.cc
            "$NINJA_REPO"/src/status_printer.cc
            "$NINJA_REPO"/src/string_piece_util.cc
            "$NINJA_REPO"/src/util.cc
            "$NINJA_REPO"/src/version.cc
            "$NINJA_REPO"/src/depfile_parser.cc
            "$NINJA_REPO"/src/lexer.cc
            "$NINJA_REPO"/src/ninja.cc
        )
        WIN32_SOURCES=(
            "$NINJA_REPO"/src/subprocess-win32.cc
            "$NINJA_REPO"/src/includes_normalize-win32.cc
            "$NINJA_REPO"/src/msvc_helper-win32.cc
            "$NINJA_REPO"/src/msvc_helper_main-win32.cc
            "$NINJA_REPO"/src/minidump-win32.cc
        )
        POSIX_SOURCES=(
            "$NINJA_REPO"/src/subprocess-posix.cc
        )
        ;;
    *)
        echo "Ninja $NINJA_VERSION not supported"
        exit 1
        ;;
esac

CFLAGS=(
    -Wno-deprecated
    -Wno-missing-field-initializers
    -Wno-unused-parameter
    -Wno-inconsistent-missing-override
    -fno-rtti
    -fno-exceptions
    -std=c++11
    -pipe
    -O2
    -fdiagnostics-color
    -s
    -DNDEBUG
)

WIN32_CFLAGS=(
    #-D_WIN32_WINNT=0x0601
    -D__USE_MINGW_ANSI_STDIO=1
    -DUSE_PPOLL
)

POSIX_CFLAGS=(
    -fvisibility=hidden
    -pipe
    -Wno-dll-attribute-on-redeclaration
)

LINUX_CFLAGS=(
    -DUSE_PPOLL
)

MACOS_CFLAGS=(
)

found()
{
    hash "$@" 2>/dev/null
}

download()
{
    local URL="$1"
    local OUTPUT="$2"
    echo "Downloading $URL"
    if found curl
    then
        curl -L "$URL" -o "$OUTPUT" --progress-bar --fail
        return
    fi
    if found wget
    then
        wget "$URL" -O "$OUTPUT"
        return
    fi
    echo "ERROR: curl or wget not found"
    exit 1
}

detect_os()
{
    ARCH="$(uname -m)"
    case "$ARCH" in
        (arm64) ARCH=aarch64 ;;
    esac

    case "$(uname -s)" in
        (Linux)  OS=linux ;;
        (Darwin) OS=macos ;;
        (MINGW*) OS=windows; EXT=.exe ;;
        (*)      OS=unknown ;;
    esac
}

install_zig()
{
    [ -x "$ZIG" ] && return

    local ZIG_ARCHIVE="zig-$OS-$ARCH-$ZIG_VERSION.tar.xz"
    local ZIG_URL="https://ziglang.org/download/$ZIG_VERSION/$ZIG_ARCHIVE"

    mkdir -p "$(dirname "$ZIG")"
    download "$ZIG_URL" "$(dirname "$ZIG")/$ZIG_ARCHIVE"

    tar xJf "$(dirname "$ZIG")/$ZIG_ARCHIVE" -C "$(dirname "$ZIG")" --strip-components 1
    rm "$(dirname "$ZIG")/$ZIG_ARCHIVE"
}

clone_ninja()
{
    $FORCE && rm -rf $BUILD
    [ -d "$NINJA_REPO" ] && return
    git clone "$NINJA_URL" "$NINJA_REPO" -b "$NINJA_VERSION"
}

compile()
{
    local TARGET="$1"
    local OUTPUT
    OUTPUT="ninja-$(echo "$TARGET" | awk -F- '{print $2"-"$1}')"
    local TARGET_CFLAGS=( "${CFLAGS[@]}" )
    local TARGET_SOURCES=( "${SOURCES[@]}" )
    case "$TARGET" in
        (*windows*) TARGET_CFLAGS+=( "${WIN32_CFLAGS[@]}" )
                    TARGET_SOURCES+=( "${WIN32_SOURCES[@]}" )
                    OUTPUT="$OUTPUT.exe"
                    ;;
        (*linux*)   TARGET_CFLAGS+=( "${POSIX_CFLAGS[@]}" "${LINUX_CFLAGS[@]}" )
                    TARGET_SOURCES+=( "${POSIX_SOURCES[@]}" )
                    ;;
        (*macos*)   TARGET_CFLAGS+=( "${POSIX_CFLAGS[@]}" "${MACOS_CFLAGS[@]}" )
                    TARGET_SOURCES+=( "${POSIX_SOURCES[@]}" )
                    ;;
    esac
    echo "Compile Ninja for $TARGET"
    $ZIG c++ -target "$TARGET" "${TARGET_CFLAGS[@]}" "${TARGET_SOURCES[@]}" -o "$BUILD/$OUTPUT"
}

detect_os
install_zig
clone_ninja

compile x86_64-linux-gnu
compile aarch64-linux-gnu
compile x86_64-macos-none
compile aarch64-macos-none
compile x86_64-windows-gnu

if $INSTALL
then
    install -v "$BUILD/ninja-$OS-$ARCH$EXT" ~/.local/bin/ninja"$EXT"
fi
