section [[
Dummy project showing bang capabilities
and many other features enabled by LuaX.

The src directory contains the C sources of a Lua interpreter.

This script generates a Ninja file that compiles and optionally install Lua
]]

local sys = require "sys"

build.cc
: add "cflags" {
    "-O2",
    case(sys.os) {
        linux = "-DLUA_USE_LINUX -DLUA_USE_READLINE",
        macos = "-DLUA_USE_MACOSX",
        windows = {},
    },
}
: add "ldflags" {
    "-s",
}
: add "ldlibs" {
    "-lm",
    case(sys.os) {
        linux = "-lreadline",
        macos = {},
        windows = {},
    },
}

local lib = build.cc:static_lib "$builddir/liblua.a" {
    ls "src/*.c" : difference { "src/lua.c", "src/luac.c" }
}

local binaries = {
    build.cc "$builddir/lua"  { "src/lua.c",  lib },
    build.cc "$builddir/luac" { "src/luac.c", lib },
}

install "bin" { binaries }
default { binaries }
