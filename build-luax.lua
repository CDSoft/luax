--[[
This file is part of luax.

luax is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

luax is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with luax.  If not, see <https://www.gnu.org/licenses/>.

For further information about luax you can visit
https://codeberg.org/cdsoft/luax
--]]

-------------------------------------------------------------------------------
section "LuaX"
-------------------------------------------------------------------------------

var "cache"       ".cache"
var "zig"         "$cache/zig/zig"  -- installed by bang.sh
var "lua"         "$cache/lua"      -- installed by bang.sh

clean.mrproper "$cache"

local F = require "F"
local fs = require "fs"
local sh = require "sh"
local sys = require "sys"
local targets = require "luax-targets"
local version = require "luax-version"

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

local luax_lua_sources = F{ "luax/luax.lua" }
local libluax_lua_sources = ls "luax/*.lua" : difference(luax_lua_sources)
local libluax_ext_sources = ls "luax/ext/**.lua"

local luax_c_sources = ls "luax/*.c"
local lua_c_sources = ls "lua/*.c" : difference { "lua/lua.c" }
local ext_c_sources = ls "luax/ext/**.c" : difference(ls "luax/ext/lzlib/inc/*.c")

-------------------------------------------------------------------------------
-- LuaX compilers
-------------------------------------------------------------------------------

local _luax_idx = -1
local function new_luax(prog, deps)
    _luax_idx = _luax_idx + 1
    local luax = {}
    deps = F.flatten{prog:words():last(), deps}:nub()
    local target_names = F.flatten {
        "native", "lua", "luax", "pandoc",
        targets : map(function(target) return target.name end),
    }
    target_names : foreach(function(target_name)
        luax[target_name] = build.luax[target_name] : new("luax-".._luax_idx.."-"..target_name)
            : set "luax" (prog)
            : add "implicit_in" (deps)
            : add "flags" "-q"
    end)
    return luax
end

rule "packlib" {
    command = {
        "export LUA_PATH=luax/?.lua;",
        "$cache/lua tools/packlib.lua -o $out $in",
    },
    implicit_in = "tools/packlib.lua",
}

-------------------------------------------------------------------------------
-- Compile the LuaX loaders for all supported targets
-------------------------------------------------------------------------------

local function when(flag)
    return flag and F.id or F.const{}
end

local function lto(target)
    if args.d then return {} end
    if target.os == "macos" then return {} end
    return "-flto"
end

local cflags = build.compile_flags {
    "-std=gnu2x",
    "-O3",
    "-pipe",
    "-fPIC",
    "-Ilua",
    "-Iluax/ext/lzlib/inc",

    when(args.d) {
        "-g",
        "-Og",
    },
}

local luax_cflags = build.compile_flags {
    "-Werror",
    "-Wall",
    "-Wextra",
    "-pedantic",
    "-DFNV1A_BIT128",

    "-Wstrict-prototypes",
    "-Wmissing-field-initializers",
    "-Wmissing-prototypes",
    "-Wmissing-declarations",
    "-Werror=switch-enum",
    "-Werror=implicit-fallthrough",
    "-Werror=missing-prototypes",

    "-Wno-unused-macros",

    "-Weverything",
    "-Wno-padded",
    "-Wno-reserved-identifier",
    "-Wno-disabled-macro-expansion",
    "-Wno-used-but-marked-unused",
    "-Wno-documentation-unknown-command",
    "-Wno-declaration-after-statement",
    "-Wno-unsafe-buffer-usage",
    "-Wno-pre-c2x-compat",
}

local ldflags = {
    "-pipe",
    when(not args.d) "-s",
}

local loaders = F(targets) : map(function(target)

    local target_flags = {
        "-DLUAX_ARCH='\""..target.arch.."\"'",
        "-DLUAX_OS='\""..target.os.."\"'",
        "-DLUAX_LIBC='\""..target.libc.."\"'",
        "-DLUAX_EXE='\""..target.exe.."\"'",
        "-DLUAX_SO='\""..target.so.."\"'",
        "-DLUAX_NAME='\""..target.name.."\"'",
    }

    local lua_flags = {
        case(target.os) {
            linux   = "-DLUA_USE_LINUX",
            macos   = "-DLUA_USE_MACOSX",
            windows = {},
        },
        when(args.d) {
            "-DLUAI_ASSERT",
            "-DLUA_USE_APICHECK",
        },
    }

    if target.name == sys.name then
        build.compile_flags {
            F{target_flags, lua_flags}
                : flatten()
                : map(function(s) return s:gsub("'", "") end)
        }
    end

    local zig_target = {"-target", F{target.arch, target.os, target.libc}:str"-"}
    local zigcc = build.zigcc[target.name] : new("cc-"..target.name)
        : set "cc" { "$zig cc", zig_target }
        : set "ar" { "$zig ar" }
        : set "so" { "$zig cc", zig_target }
        : set "ld" { "$zig cc", zig_target }
        : add "cflags" { cflags, lua_flags, lto(target) }
        : add "ldflags" { ldflags, lto(target) }
        : add "ldlibs" {
            "-lm",
            when(target.os == "windows") {
                "-lshlwapi",
                "-lws2_32",
            },
        }
        : add "implicit_in" { "$zig" }

    local zigcc_luax = zigcc : new("cc-luax-"..target.name)
        : add "cflags" { luax_cflags, target_flags }

    local zigcc_lua = zigcc : new("cc-lua-"..target.name)
        : add "cflags" { target_flags }

    local zigcc_ext = zigcc : new("cc-ext-"..target.name)
        : add "cflags" { }

    return zigcc_luax:executable("$builddir/tmp/luax-loader-"..target.name..target.exe) {
        zigcc_luax:static_lib("$builddir/tmp"/target.name/"libluax.a") { luax_c_sources },
        zigcc_lua:static_lib("$builddir/tmp"/target.name/"liblua.a") { lua_c_sources },
        zigcc_ext:static_lib("$builddir/tmp"/target.name/"libext.a") {
            ext_c_sources : difference(
                target.os == "windows" and {
                    -- Linux/MacOS only
                    "luax/ext/linenoise/linenoise.c",
                    "luax/ext/luasocket/unixdgram.c",
                    "luax/ext/luasocket/serial.c",
                    "luax/ext/luasocket/unixstream.c",
                    "luax/ext/luasocket/usocket.c",
                } or {
                    -- Windows only
                    "luax/ext/luasocket/wsocket.c",
                })
        },
    }

end)

-------------------------------------------------------------------------------
-- Generate the pure-Lua LuaX interpreters and library
-------------------------------------------------------------------------------

local luax0 = new_luax("export LUA_PATH='luax/?.lua'; $cache/lua $builddir/stage0/bin/luax.lua", {
    build.cp "$builddir/stage0/bin/luax.lua" "luax/luax.lua",
    build "$builddir/stage0/lib/libluax.xyz" { "packlib",
        libluax_lua_sources,
        libluax_ext_sources,
        loaders,
    },
})

acc(compile) {
    luax0.lua    "$builddir/bin/luax.lua"        { luax_lua_sources },
    luax0.pandoc "$builddir/bin/luax-pandoc.lua" { luax_lua_sources },
    luax0.luax   "$builddir/lib/libluax.lua"     { libluax_lua_sources },
    build.cp     "$builddir/lib/libluax.xyz"     { "$builddir/stage0/lib/libluax.xyz" },

    -- Add prebuilt scripts to the repository
    build.cp "bin/luax.lua"        "$builddir/bin/luax.lua",
    build.cp "bin/luax-pandoc.lua" "$builddir/bin/luax-pandoc.lua",
    build.cp "lib/libluax.lua"     "$builddir/lib/libluax.lua",
}

-- Compile using LuaX binaries
luax = new_luax("$builddir/bin/luax")

-------------------------------------------------------------------------------
-- Generate the native LuaX interpreter
-------------------------------------------------------------------------------

acc(compile) {
    "$builddir/lib/libluax.xyz",
    luax0.native "$builddir/bin/luax" {
        luax_lua_sources,
        implicit_in = "$builddir/lib/libluax.xyz",
    },
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

function archive(target)
    local target_name = target.name or target
    return "$builddir/release"/version.version/"luax-"..version.version.."-"..target_name
end

function cp_to(dest) return function(files)
    return F.flatten{files} : map(function(file)
        return build.cp(dest/file:basename()) { file }
    end)
end end

build "$builddir/tmp/libluax-lua.xyz" { "packlib",
    libluax_lua_sources,
}

local function build_release(target)
    local archive = archive(target)
    return {
        cp_to(archive/"bin") {
            "$builddir/bin/luax.lua",
            "$builddir/bin/luax-pandoc.lua",
        },
        target.name and luax[target.name](archive/"bin/luax") {
            luax_lua_sources,
            implicit_in = "$builddir/lib/libluax.xyz",
        },
        cp_to(archive/"lib") {
            "$builddir/lib/libluax.lua",
            target.name
                and "$builddir/lib/libluax.xyz"
                or "$builddir/tmp/libluax-lua.xyz",
        },
    }
end

acc(release) {
    targets : map(build_release),
    build_release "lua",
}

-------------------------------------------------------------------------------
-- luarc.json
-------------------------------------------------------------------------------

if bang.output:dirname() == bang.input:dirname() then
    local function dirs(path)
        return ls(path/"**.lua")
            : map(F.compose{F.prefix"    \"", F.suffix"\",", fs.dirname})
            : nub() : unlines() : rtrim() : gsub(",$", "")
    end
    file(bang.input:dirname()/".luarc.json")(F.unlines(F.flatten{
        "{",
        [=[  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",]=],
        [=[  "runtime.version": "Lua 5.5",]=],
        [=[  "workspace.library": []=],
        [=[    "luax",]=],
        dirs "luax/ext",
        [=[  ],]=],
        [=[  "workspace.checkThirdParty": false]=],
        "}",
    }))
end

-------------------------------------------------------------------------------
-- Native C compiler
-------------------------------------------------------------------------------

local zigcc = build.zigcc : new("cc-native")
    : set "cc" { "$zig cc" } : add "cflags" { cflags, luax_cflags }
    : set "ar" { "$zig ar" }
    : set "so" { "$zig cc" }
    : set "ld" { "$zig cc" } : add "ldflags" { ldflags }
    : add "implicit_in" { "$zig" }

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

local imported_test_sources = ls "luax/tests/luax-tests/to_be_imported-*.lua"
local test_sources = {
    ls "luax/tests/luax-tests/*.*" : difference(imported_test_sources),
}
local test_main = "luax/tests/luax-tests/main.lua"

local libc = case(sys.os) {
    linux   = "gnu",
    macos   = "none",
    windows = "gnu",
}

local test_options = {
    "BUILD=$builddir",
    "TESTDIR=$builddir/tests/luax",
}

local native_targets = targets
    : filter(function(t) return t.os==sys.os and t.arch==sys.arch end)
    : map(function(t) return t.name end)

local _port = 8000
local function new_httpd_port_range()
    _port = _port + 10
    return _port
end

var "httpd" "$builddir/tests/luax/httpd"
zigcc "$httpd" { "luax/tests/luax-tests/httpd.c" }

local pandoc_version = (sh"pandoc --version" or "0") : match"[%d%.]+" : split"%." : map(tonumber)
local has_pandoc = F.op.uge(pandoc_version, {3, 1, 12, 3})

acc(test) {

    build "$builddir/tests/luax/test-1-luax_executable.ok" { test_sources,
        description = "test $out",
        command = {
            "$builddir/bin/luax compile -q -b -k test-1-key -o $builddir/tests/luax/test-luax $in",
            "&&",
            "PATH=$builddir/bin:$$PATH",
            "LUA_PATH='luax/tests/luax-tests/?.lua'",
            "TEST_NUM=1",
            test_options,
            sys.os=="linux" and {
                "HTTP_SERVER=$httpd",
                "HTTP_PORT_RANGE="..new_httpd_port_range(),
            } or {},
            "LUAX=$builddir/bin/luax",
            "ARCH="..sys.arch, "OS="..sys.os, "LIBC="..libc, "EXE="..sys.exe, "SO="..sys.so, "NAME="..sys.name,
            "$builddir/tests/luax/test-luax Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$builddir/bin/luax",
            loaders,
            "lib/libluax.lua",
            imported_test_sources,
            "$httpd",
        },
    },

    not args.d and {

        ({"native"} .. native_targets) : mapi(function(i, target_name)
            local test_libc = ("-musl"):is_suffix_of(target_name) and "musl" or libc
            local test_name = target_name=="native" and sys.name or target_name
            local exe_name = "$builddir/tests/luax/test-compiled".."-"..i
            return build("$builddir/tests/luax/test-1-"..i.."-compiled_executable.ok") { test_sources,
                description = "test $out",
                command = {
                    "$builddir/bin/luax compile -q", "-t", target_name, "-b -k test-1-key",
                        "-o", exe_name,
                        "$in",
                    "&&",
                    "PATH=$builddir/luax/bin:$$PATH",
                    "LUA_PATH='luax/tests/luax-tests/?.lua'",
                    "TEST_NUM=1", "TEST_CASE="..i,
                    test_options,
                    "LUAX=$builddir/bin/luax",
                    "IS_COMPILED=true", "EXE_NAME="..exe_name,
                    "ARCH="..sys.arch, "OS="..sys.os, "LIBC="..test_libc, "EXE="..sys.exe, "SO="..sys.so, "NAME="..test_name,
                    exe_name, "Lua is great",
                    "&&",
                    "touch $out",
                },
                implicit_in = {
                    "$builddir/bin/luax",
                    loaders,
                    "lib/libluax.lua",
                    imported_test_sources,
                },
            }
        end),

        has_pandoc and build "$builddir/tests/luax/test-5-pandoc-luax-lua.ok" { test_main,
            description = "test $out",
            command = {
                "PATH=bin:$$PATH",
                "LUA_PATH='lib/?.lua;luax/tests/luax-tests/?.lua'",
                "TEST_NUM=5",
                test_options,
                "ARCH="..sys.arch, "OS="..sys.os, "LIBC=lua", "EXE="..sys.exe, "SO="..sys.so, "NAME="..sys.name,
                "pandoc lua -l libluax $in Lua is great",
                "&&",
                "touch $out",
            },
            implicit_in = {
                "lib/libluax.lua",
                test_sources,
                imported_test_sources,
            },
        } or {},

        build "$builddir/tests/luax/test-ext-1-lua.ok" { "luax/tests/external_interpreter_tests/external_interpreters.lua",
            description = "test $out",
            command = {
                "eval \"$$($builddir/bin/luax env)\";",
                "$builddir/bin/luax compile -q -b -k test-ext-1-key -t lua -o $builddir/tests/luax/ext-lua $in",
                "&&",
                "PATH=$builddir/bin:.cache:$$PATH",
                "TARGET=lua",
                test_options,
                "$builddir/tests/luax/ext-lua Lua is great",
                "&&",
                "touch $out",
            },
            implicit_in = {
                "lib/libluax.lua",
                "$builddir/bin/luax",
                loaders,
            },
        },

        build "$builddir/tests/luax/test-ext-2-luax.ok" { "luax/tests/external_interpreter_tests/external_interpreters.lua",
            description = "test $out",
            command = {
                "eval \"$$($builddir/bin/luax env)\";",
                "$builddir/bin/luax compile -q -b -k test-ext-2-key -t luax -o $builddir/tests/luax/ext-luax-key $in",
                "&&",
                "PATH=$builddir/bin:$$PATH",
                "TARGET=luax-key",
                test_options,
                "$builddir/tests/luax/ext-luax-key Lua is great",
                "&&",
                "touch $out",
            },
            implicit_in = {
                "lib/libluax.lua",
                "$builddir/bin/luax",
                loaders,
            },
        },

        build "$builddir/tests/luax/test-ext-3-luax.ok" { "luax/tests/external_interpreter_tests/external_interpreters.lua",
            description = "test $out",
            command = {
                "eval \"$$($builddir/bin/luax env)\";",
                "$builddir/bin/luax compile -q -b -z -t luax -o $builddir/tests/luax/ext-luax-z $in",
                "&&",
                "PATH=$builddir/bin:$$PATH",
                "TARGET=luax-z",
                test_options,
                "$builddir/tests/luax/ext-luax-z Lua is great",
                "&&",
                "touch $out",
            },
            implicit_in = {
                "lib/libluax.lua",
                "$builddir/bin/luax",
                loaders,
            },
        },

        has_pandoc and build "$builddir/tests/luax/test-ext-4-pandoc.ok" { "luax/tests/external_interpreter_tests/external_interpreters.lua",
            description = "test $out",
            command = {
                "eval \"$$($builddir/bin/luax env)\";",
                "$builddir/bin/luax compile -q -t pandoc -o $builddir/tests/luax/ext-pandoc $in", -- no bytecode to remain compatible with pandoc
                "&&",
                "PATH=$builddir/bin:$$PATH",
                "TARGET=pandoc",
                test_options,
                "$builddir/tests/luax/ext-pandoc Lua is great",
                "&&",
                "touch $out",
            },
            implicit_in = {
                "lib/libluax.lua",
                "$builddir/bin/luax",
                loaders,
            },
        } or {},

    } or {},

}

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

build.ypp
    : set "cmd" "$builddir/bin/ypp"
    : add "implicit_in" { "$builddir/bin/ypp" }
    : set "depfile" "$builddir/tmp/$out.d"
    : add "flags" {
        "-a",
        "-t svg",
        build.ypp_vars {
            BUILD = "$builddir",
        },
    }

build.lsvg.svg
    : set "cmd" "$builddir/bin/lsvg"
    : add "implicit_in" { "$builddir/bin/lsvg" }
    : set "depfile" "$builddir/tmp/$out.d"

local ypp_config_params = {
    build.ypp_vars {
        LUAX = "$builddir/bin/luax",
        AUTHORS = version.author,
    },
}

gfm = build.ypp : new "ypp.md"
    : add "implicit_in" "lib/libluax.lua"
    : add "flags" { ypp_config_params }

acc(doc) {

    build.lsvg.svg "luax/doc/luax-banner.svg" {"luax/doc/luax-logo.lua", args={1024,  192}},
    build.lsvg.svg "luax/doc/luax-logo.svg"   {"luax/doc/luax-logo.lua", args={ 256,  256}},

    ls "luax/doc/*.md.in" : map(function(src)
        return gfm((src:splitext())) { src }
    end),
    build.cp "luax/doc/README.md" "luax/doc/luax.md",

}

-------------------------------------------------------------------------------
-- Install LuaX
-------------------------------------------------------------------------------

install "bin" {
    "$builddir/bin/luax",
    "$builddir/bin/luax.lua",
    "$builddir/bin/luax-pandoc.lua",
}

install "lib" {
    "$builddir/lib/libluax.lua",
    "$builddir/lib/libluax.xyz",
}
