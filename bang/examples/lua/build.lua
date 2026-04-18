section [[
Dummy project showing bang capabilities
and many other features enabled by LuaX.

The src directory contains the C sources of a Lua interpreter.

This script generates a Ninja file that compiles and optionally install Lua
]]

local sys = require "sys"

-- local copy of Lua sources
local sources = ls "../../../lua/*" : map(function(f) return build.cp("$builddir/src"/f:basename()) { f } end)
local c_sources = sources : filter(function(f) return f:ext() == ".c" end)
local h_sources = sources : filter(function(f) return f:ext() == ".h" end)

build.cc
: add "cflags" {
    "-O2",
    "-I$builddir/src",
    case(sys.os) {
        linux = "-DLUA_USE_LINUX",
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
        linux = "-lm",
        macos = "-lm",
        windows = {},
    },
}

local lib = build.cc:static_lib "$builddir/liblua.a" {
    c_sources : difference { "$builddir/src/lua.c", "$builddir/src/luac.c" },
    implicit_in = h_sources,
}

local binaries = {
    build.cc "$builddir/lua"  { "$builddir/src/lua.c",  lib },
    --build.cc "$builddir/luac" { "$builddir/src/luac.c", lib }, -- not available in LuaX
}

install "bin" { binaries }
default { binaries }
