local F = require "F"
local fs = require "fs"

local URL = "cdelord.fr/luax"
local YEARS = os.date "2021-%Y"
local AUTHORS = "Christophe Delord"
local appname = "luax"
local crypt_key = "LuaX"

section(F.I{URL=URL}[[
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
http://$(URL)
]])

help.name "LuaX"
help.description(F.I{YEARS=YEARS, AUTHORS=AUTHORS, URL=URL}[[
Lua eXtended
Copyright (C) $(YEARS) $(AUTHORS) (https://$(URL))

luax is a Lua interpreter and REPL based on Lua 5.4
augmented with some useful packages.
luax can also produce standalone scripts from Lua scripts.

luax runs on several platforms with no dependency:

- Linux (x86_64, aarch64)
- MacOS (x86_64, aarch64)
- Windows (x86_64)

luax can « compile » scripts executable on all supported platforms
(LuaX must be installed on the target environment).
]])

section [[
WARNING: This file has been generated by bang. DO NOT MODIFY IT.
If you need to update the build system, please modify build.lua
and run bang to regenerate build.ninja.
]]

-- list of targets used for cross compilation (with Zig only)
local luax_sys = dofile"libluax/sys/sys.lua"
local targets = F(luax_sys.targets)
local host = targets
    : filter(function(t) return t.zig_os==luax_sys.os and t.zig_arch==luax_sys.arch end)
    : head()
if not host then
    F.error_without_stack_trace(luax_sys.os.." "..luax_sys.arch..": unknown host")
end

local usage = F.I{
    title = function(s) return F.unlines {s, (s:gsub(".", "="))}:rtrim() end,
    list = function(t) return t:map(F.prefix"    - "):unlines():rtrim() end,
    targets = targets:map(F.partial(F.nth, "name")),
}[[
$(title "LuaX bang file usage")

The LuaX bang file can be given options to customize the LuaX compilation.

Without any options, LuaX is:
    - compiled with Zig for the current platform
    - optimized for speed

$(title "Compilation mode")

bang -- fast        Code optimized for speed (default)
bang -- small       Code optimized for size
bang -- quick       Reduce compilation time (slow execution)
bang -- debug       Compiled with debug informations
                    Tests run with Valgrind (very slow)

$(title "Compiler")

bang -- zig         Compile LuaX with Zig (default)
bang -- gcc         Compile LuaX with gcc
bang -- clang       Compile LuaX with clang

Zig is downloaded by the ninja file.
gcc and clang must be already installed.

$(title "Compilation targets")

bang -- <target>    Compile LuaX for <target> (with zig only)

By default LuaX is compiled for the current platform.
Supported targets:
$(list(targets))

$(title "Compression")

bang -- upx         Compress LuaX with UPX

By default LuaX is not compressed.

$(title "Application bundle options")

bang -- appname=... Name of the applicative bundle
bang -- app=...     Sources of the applicative bundle
bang -- key=...     Encryption key
]]

if F.elem("help", arg) then
    print(usage)
    os.exit(0)
end

local target = nil
local mode = nil -- fast, small, quick, debug
local compiler = nil -- zig, gcc, clang
local upx = false
local myapp = nil -- scripts that may overload the default bundle
local myappname = nil

F.foreach(arg, function(a)
    local function set_mode()
        if mode~=nil then F.error_without_stack_trace(a..": duplicate compilation mode", 2) end
        mode = a
    end
    local function set_compiler()
        if compiler~=nil then F.error_without_stack_trace(a..": duplicate compiler specification", 2) end
        compiler = a
    end
    local function set_target()
        if target~=nil then F.error_without_stack_trace(a..": duplicate target specification", 2) end
        target = targets : filter(function(t) return t.name == a end) : head()
        if not target then F.error_without_stack_trace(a..": unknown target", 2) end
    end
    local function set_key(k, v)
        if not k or not v or #v==0 then F.error_without_stack_trace(a..": the key must be defined and not null", 2) end
        crypt_key = v
    end
    local function set_appname(k, v)
        if not k or not v or #v==0 then F.error_without_stack_trace(a..": the key must be defined and not null", 2) end
        myappname = v
    end
    local function add_app(k, v)
        if not k or not v or #v==0 then F.error_without_stack_trace(a..": the app must be defined and not null", 2) end
        myapp = myapp or F{}
        if fs.is_file(v) then myapp[#myapp+1] = v; return end
        if fs.is_dir(v) then myapp[#myapp+1] = fs.ls(v/"**"); return end
        myapp[#myapp+1] = fs.ls(v)
    end

    local k, v = a:match "^(%w+)=(.*)$"
    case(k or a) {
        fast    = set_mode,
        small   = set_mode,
        quick   = set_mode,
        debug   = set_mode,
        zig     = set_compiler,
        gcc     = set_compiler,
        clang   = set_compiler,
        upx     = function() upx = true end,
        key     = F.partial(set_key, k, v),
        app     = F.partial(add_app, k, v),
        appname = F.partial(set_appname, k, v),
        [F.Nil] = set_target,
    } ()
end)

mode = F.default("fast", mode)
if mode=="debug" and upx then F.error_without_stack_trace("UPX compression not available in debug mode") end

compiler = F.default("zig", compiler)
if compiler~="zig" and target then
    F.error_without_stack_trace("The compilation target can not be specified with "..compiler)
end

if myapp and not myappname then
    F.error_without_stack_trace("The application name shall be defined with the appname option")
end

if myappname and not myapp then
    F.error_without_stack_trace("The application content shall be defined with the app option")
end

appname = myappname or appname

section("Compilation options")
comment(("Compilation mode: %s"):format(mode))
comment(("Compiler        : %s"):format(compiler))
comment(("Target          : %s"):format(target or "native"))
comment(("Compression     : %s"):format(upx and "UPX" or "none"))
comment(("App bundle      : %s"):format(appname))

--===================================================================
section "Build environment"
---------------------------------------------------------------------

if target then
    var "builddir" (".build" / target.name)
else
    var "builddir" ".build"
end

var "bin" "$builddir/bin"
var "lib" "$builddir/lib"
var "doc" "$builddir/doc"
var "tmp" "$builddir/tmp"
var "test" "$builddir/test"

local compile = {}
local test = {}
local doc = {}

--===================================================================
section "Compiler"
---------------------------------------------------------------------

rule "mkdir" {
    description = "MKDIR $out",
    command = "mkdir -p $out",
}

local compiler_deps = {}

case(compiler) {

    zig = function()
        local zig_version = "0.11.0"
        --local zig_version = "0.12.0-dev.2139+e025ad7b4"
        var "zig" (".zig" / zig_version / "zig")

        build "$zig" { "tools/install_zig.sh",
            description = {"GET zig", zig_version},
            command = {"$in", zig_version, "$out"},
            pool = "console",
        }

        compiler_deps = { "$zig" }
        local zig_cache = {
            "ZIG_GLOBAL_CACHE_DIR=$$PWD/${zig}-global-cache",
            "ZIG_LOCAL_CACHE_DIR=$$PWD/${zig}-local-cache",
        }

        var "cc" { zig_cache, "$zig cc" }
        var "ar" { zig_cache, "$zig ar" }
        var "ld" { zig_cache, "$zig cc" }
    end,

    gcc = function()
        var "cc" "gcc"
        var "ar" "ar"
        var "ld" "gcc"
    end,

    clang = function()
        var "cc" "clang"
        var "ar" "ar"
        var "ld" "clang"
    end,

}()

local include_path = {
    ".",
    "$tmp",
    "lua",
    "ext/c/lz4/lib",
    "libluax",
}

local lto_opt = case(compiler) {
    zig   = "-flto=thin",
    gcc   = "-flto",
    clang = "-flto=thin",
}

local native_cflags = {
    "-std=gnu2x",
    "-O3",
    "-fPIC",
    F.map(F.prefix"-I", include_path),
    case(host.zig_os) {
        linux = "-DLUA_USE_LINUX",
        macos = "-DLUA_USE_MACOSX",
        windows = {},
    },
    "-Werror",
    "-Wall",
    "-Wextra",
    case(compiler) {
        zig = {
            "-Wno-constant-logical-operand",
        },
        gcc = {},
        clang = {
            "-Wno-constant-logical-operand",
        },
    },
}

local native_ldflags = {
    "-rdynamic",
    "-s",
    "-lm",
    case(compiler) {
        zig = {},
        gcc = {
            "-Wstringop-overflow=0",
        },
        clang = {},
    },
}

local cflags = {
    "-std=gnu2x",
    case(mode) {
        fast  = "-O3",
        small = "-Os",
        quick = {},
        debug = "-g",
    },
    "-fPIC",
    F.map(F.prefix"-I", include_path),
}

local luax_cflags = {
    cflags,
    "-Werror",
    "-Wall",
    "-Wextra",
    case(compiler) {
        zig = {
            "-Weverything",
            "-Wno-padded",
            "-Wno-reserved-identifier",
            "-Wno-disabled-macro-expansion",
            "-Wno-used-but-marked-unused",
            "-Wno-documentation-unknown-command",
            "-Wno-declaration-after-statement",
            "-Wno-unsafe-buffer-usage",
            "-Wno-pre-c2x-compat",
        },
        gcc = {},
        clang = {
            "-Weverything",
            "-Wno-padded",
            "-Wno-reserved-identifier",
            "-Wno-disabled-macro-expansion",
            "-Wno-used-but-marked-unused",
            "-Wno-documentation-unknown-command",
            "-Wno-declaration-after-statement",
            "-Wno-unsafe-buffer-usage",
            "-Wno-pre-c2x-compat",
        },
    },
}

local ext_cflags = {
    cflags,
    case(compiler) {
        zig = {
            "-Wno-constant-logical-operand",
        },
        gcc = {},
        clang = {
            "-Wno-constant-logical-operand",
        },
    },
}

local ldflags = {
    case(mode) {
        fast  = "-s",
        small = "-s",
        quick = {},
        debug = {},
    },
    "-lm",
    case(compiler) {
        zig = {
            "-Wno-single-bit-bitfield-constant-conversion",
        },
        gcc = {
            "-Wstringop-overflow=0",
        },
        clang = {},
    },
}

local function zig_target(t)
    return t and {"-target", F{t.zig_arch, t.zig_os, t.zig_libc}:str"-"} or {}
end

rule "cc-host" {
    description = "CC $in",
    command = {
        "$cc", "-c", native_cflags, "-MD -MF $depfile $in -o $out",
    },
    implicit_in = {
        compiler_deps,
    },
    depfile = "$out.d",
}

rule "ld-host" {
    description = "LD $out",
    command = {
        "$ld", native_ldflags, "$in -o $out",
    },
    implicit_in = {
        compiler_deps,
    },
}

local target_arch = target and target.zig_arch or host.zig_arch
local target_os   = target and target.zig_os   or host.zig_os
local target_libc = target and target.zig_libc or host.zig_libc

local lto = case(mode) {
    fast = case(target_os) {
        linux   = lto_opt,
        macos   = {},
        windows = lto_opt,
    },
    small = {},
    quick = {},
    debug = {},
}
local target_flags = {
    "-DLUAX_ARCH='\""..target_arch.."\"'",
    "-DLUAX_OS='\""..target_os.."\"'",
    "-DLUAX_LIBC='\""..target_libc.."\"'",
}
local lua_flags = {
    case(target_os) {
        linux   = "-DLUA_USE_LINUX",
        macos   = "-DLUA_USE_MACOSX",
        windows = {},
    },
}
local target_ld_flags = {
    case(target_libc) {
        gnu  = "-rdynamic",
        musl = {},
        none = "-rdynamic",
    },
    case(target_os) {
        linux   = {},
        macos   = {},
        windows = "-lws2_32 -ladvapi32",
    },
}
local target_so_flags = {
    "-shared",
}
local target_opt = case(compiler) {
    zig   = zig_target(target),
    gcc   = {},
    clang = {},
}
local cc = rule("cc-target") {
    description = "CC $in",
    command = {
        "$cc", target_opt, "-c", lto, luax_cflags, lua_flags, target_flags, "-MD -MF $depfile $in -o $out",
        case(target_os) {
            linux   = {},
            macos   = {},
            windows = "$build_as_dll",
        }
    },
    implicit_in = {
        compiler_deps,
    },
    depfile = "$out.d",
}
local cc_ext = rule("cc_ext-target") {
    description = "CC $in",
    command = {
        "$cc", target_opt, "-c", lto, ext_cflags, lua_flags, "$additional_flags", "-MD -MF $depfile $in -o $out",
    },
    implicit_in = {
        compiler_deps,
    },
    depfile = "$out.d",
}
local ld = rule("ld-target") {
    description = "LD $out",
    command = {
        "$ld", target_opt, lto, ldflags, target_ld_flags, "$in -o $out",
    },
    implicit_in = {
        compiler_deps,
    },
}
local so = rule("so-target") {
    description = "SO $out",
    command = {
        "$cc", target_opt, lto, ldflags, target_ld_flags, target_so_flags, "$in -o $out",
    },
    implicit_in = {
        compiler_deps,
    },
}

local ar = rule "ar-target" {
    description = "AR $out",
    command = "$ar -crs $out $in",
    implicit_in = {
        compiler_deps,
    },
}

--===================================================================
section "Third-party modules update"
---------------------------------------------------------------------

build "update_modules" {
    description = "UPDATE",
    command = "tools/update-third-party-modules.sh $builddir/update",
    pool = "console",
}

--===================================================================
section "lz4 cli"
---------------------------------------------------------------------

var "lz4" "$tmp/lz4"

build "$lz4" { "ld-host",
    ls "ext/c/lz4/**.c"
    : map(function(src)
        return build("$tmp/obj/lz4"/src:splitext()..".o") { "cc-host", src }
    end),
}

--===================================================================
section "LuaX sources"
---------------------------------------------------------------------

local linux_only = F{
    "ext/c/luasocket/serial.c",
    "ext/c/luasocket/unixdgram.c",
    "ext/c/luasocket/unixstream.c",
    "ext/c/luasocket/usocket.c",
    "ext/c/luasocket/unix.c",
    "ext/c/linenoise/linenoise.c",
    "ext/c/linenoise/utf8.c",
}
local windows_only = F{
    "ext/c/luasocket/wsocket.c",
}
local ignored_sources = F{
    "ext/c/lqmath/src/imath.c",
}

local sources = {
    lua_c_files = ls "lua/*.c"
        : filter(function(name) return F.not_elem(name:basename(), {"lua.c", "luac.c"}) end),
    lua_main_c_files = F{ "lua/lua.c" },
    luax_main_c_files = F{ "luax/luax.c" },
    libluax_main_c_files = F{ "luax/libluax.c" },
    luax_c_files = ls "libluax/**.c",
    third_party_c_files = ls "ext/c/**.c"
        : filter(function(name) return not name:match "lz4/programs" end)
        : difference(linux_only)
        : difference(windows_only)
        : difference(ignored_sources),
    linux_third_party_c_files = linux_only,
    windows_third_party_c_files = windows_only,
}

--===================================================================
section "Native Lua interpreter"
---------------------------------------------------------------------

var "lua" "$tmp/lua"

var "lua_path" (
    F{
        ".",
        "$tmp",
        "libluax",
        ls "libluax/*" : filter(fs.is_dir),
        "luax",
    }
    : flatten()
    : map(function(path) return path / "?.lua" end)
    : str ";"
)

build "$lua" { "ld-host",
    (sources.lua_c_files .. sources.lua_main_c_files) : map(function(src)
        return build("$tmp/obj/lua"/src:splitext()..".o") { "cc-host", src }
    end),
}

--===================================================================
section "LuaX configuration"
---------------------------------------------------------------------

comment [[
The configuration file (luax_config.h and luax_config.lua)
are created in `libluax`
]]

var "luax_config_h"   "$tmp/luax_config.h"
var "luax_config_lua" "$tmp/luax_config.lua"
var "luax_crypt_key"  "$tmp/luax_crypt_key.h"

local luax_config_table = (F.I % "%%()") {
    AUTHORS = AUTHORS,
    URL = URL,
}

F.compose { file "tools/gen_config_h.sh", luax_config_table } [[
#!/bin/bash

LUAX_CONFIG_H="$1"

cat <<EOF > "$LUAX_CONFIG_H"
#pragma once
#define LUAX_VERSION "$(git describe --tags)"
#define LUAX_DATE "$(git show -s --format=%cd --date=format:'%Y-%m-%d')"
#define LUAX_COPYRIGHT "LuaX "LUAX_VERSION"  Copyright (C) 2021-$(git show -s --format=%cd --date=format:'%Y') %(URL)"
#define LUAX_AUTHORS "%(AUTHORS)"
EOF
]]

F.compose { file "tools/gen_config_lua.sh", luax_config_table } [[
#!/bin/bash

LUAX_CONFIG_LUA="$1"

cat <<EOF > "$LUAX_CONFIG_LUA"
--@LIB
local version = "$(git describe --tags)"
return {
    version = version,
    date = "$(git show -s --format=%cd --date=format:'%Y-%m-%d')",
    copyright = "LuaX "..version.."  Copyright (C) 2021-$(git show -s --format=%cd --date=format:'%Y') %(URL)",
    authors = "%(AUTHORS)",
}
EOF
]]

rule "gen_config" {
    description = "GEN $out",
    command = {
        "bash", "$in", "$out",
    },
    implicit_in = {
        ".git/refs/tags",
        "$lua"
    },
}

build "$luax_config_h"   { "gen_config", "tools/gen_config_h.sh" }
build "$luax_config_lua" { "gen_config", "tools/gen_config_lua.sh" }

var "crypt_key" (crypt_key)

build "$luax_crypt_key"  {
    description = "GEN $out",
    command = {
        "$lua tools/crypt_key.lua LUAX_CRYPT_KEY \"$crypt_key\" > $out",
    },
    implicit_in = {
        "$lua",
        "tools/crypt_key.lua",
    }
}

--===================================================================
section "Lua runtime"
---------------------------------------------------------------------

local luax_runtime = {
    ls "libluax/**.lua",
    ls "ext/**.lua",
}

var "luax_runtime_bundle" "$tmp/lua_runtime_bundle.c"

build "$luax_runtime_bundle" { "$luax_config_lua", luax_runtime,
    description = "BUNDLE $out",
    command = {
        "PATH=$tmp:$$PATH",
        "LUA_PATH=\"$lua_path\"",
        "CRYPT_KEY=\"$crypt_key\"",
        "$lua -l tools/rc4_runtime luax/luax_bundle.lua -lib -c $in > $out",
    },
    implicit_in = {
        "$lz4",
        "$lua",
        "luax/luax_bundle.lua",
        "tools/rc4_runtime.lua",
    },
}

local luax_app = myapp or {
    ls "luax/**.lua",
    "$luax_config_lua",
}

var "luax_app_bundle" "$tmp/lua_app_bundle.c"

build "$luax_app_bundle" { luax_app,
    description = "BUNDLE $out",
    command = {
        "PATH=$tmp:$$PATH",
        "LUA_PATH=\"$lua_path\"",
        "CRYPT_KEY=\"$crypt_key\"",
        "$lua -l tools/rc4_runtime luax/luax_bundle.lua", "-name="..appname, "-app -c $in > $out",
    },
    implicit_in = {
        "$lz4",
        "$lua",
        "luax/luax_bundle.lua",
        "tools/rc4_runtime.lua",
    },
}

--===================================================================
section "Binaries and shared libraries"
---------------------------------------------------------------------

local binaries = {}
local libraries = {}

local ext = case(target_os) {
    linux   = "",
    macos   = "",
    windows = ".exe",
}

local libext = case(target_os) {
    linux   = ".so",
    macos   = ".dylib",
    windows = ".dll",
}

-- imath is also provided by qmath, both versions shall be compatible
rule "diff" {
    description = "DIFF $in",
    command = "diff $in > $out",
}
phony "check_limath_version" {
    build "$tmp/check_limath_header_version" { "diff", "ext/c/lqmath/src/imath.h", "ext/c/limath/src/imath.h" },
    build "$tmp/check_limath_source_version" { "diff", "ext/c/lqmath/src/imath.c", "ext/c/limath/src/imath.c" },
}

local liblua = build("$tmp/lib/liblua.a") { ar,
    F.flatten {
        sources.lua_c_files,
    } : map(function(src)
        return build("$tmp/obj"/src:splitext()..".o") { cc_ext, src }
    end),
}

local libluax = build("$tmp/lib/libluax.a") { ar,
    F.flatten {
        sources.luax_c_files,
    } : map(function(src)
        return build("$tmp/obj"/src:splitext()..".o") { cc, src,
            implicit_in = {
                case(src:basename():splitext()) {
                    version = "$luax_config_h",
                    crypt = "$luax_crypt_key",
                } or {},
            },
        }
    end),
    F.flatten {
        sources.third_party_c_files,
        case(target_os) {
            linux   = sources.linux_third_party_c_files,
            macos   = sources.linux_third_party_c_files,
            windows = sources.windows_third_party_c_files,
        },
    } : map(function(src)
        return build("$tmp/obj"/src:splitext()..".o") { cc_ext, src,
            additional_flags = case(src:basename():splitext()) {
                usocket = "-Wno-#warnings",
            },
            implicit_in = case(src:basename():splitext()) {
                limath = "check_limath_version",
                imath  = "check_limath_version",
            },
        }
    end),
}

local main_luax = F.flatten { sources.luax_main_c_files }
    : map(function(src)
        return build("$tmp/obj"/src:splitext()..".o") { cc, src,
            implicit_in = {
                "$luax_config_h",
                "$luax_app_bundle",
            },
        }
    end)

local main_libluax = F.flatten { sources.libluax_main_c_files }
    : map(function(src)
            return build("$tmp/obj"/src:splitext()..".o") { cc, src,
                build_as_dll = case(target_os) {
                    windows = "-DLUA_BUILD_AS_DLL -DLUA_LIB",
                },
                implicit_in = {
                    "$luax_runtime_bundle",
                },
            }
        end)

local binary = build("$tmp/bin"/appname..ext) { ld,
    main_luax,
    main_libluax,
    liblua,
    libluax,
    "$tmp/lua_runtime_bundle.c",
    "$tmp/lua_app_bundle.c",
}

local shared_library = target_libc~="musl" and not myapp and
    build("$tmp/lib/libluax"..libext) { so,
        main_libluax,
        case(target_os) {
            linux   = {},
            macos   = liblua,
            windows = liblua,
        },
        libluax,
        "$tmp/lua_runtime_bundle.c",
}

if upx and mode~="debug" then
    rule "upx" {
        description = "UPX $in",
        command = "rm -f $out; upx -qqq -o $out $in && touch $out",
    }
    binary = case(target_os) {
        macos   = binary,
        [F.Nil] = build("$tmp/bin-upx"/binary:basename()) { "upx", binary },
    }
    shared_library = shared_library and case(target_os) {
        macos   = shared_library,
        [F.Nil] = build("$tmp/lib-upx"/shared_library:basename()) { "upx", shared_library },
    }
end

rule "cp" {
    description = "CP $out",
    command = "cp -f $in $out",
}

var "luax" ("$bin"/binary:basename())

acc(binaries) {
    build "$luax" { "cp", binary }
}

if shared_library then
    acc(libraries) {
        build("$lib"/shared_library:basename()) { "cp", shared_library }
    }
end

if not myapp then
--===================================================================
section "LuaX Lua implementation"
---------------------------------------------------------------------

--===================================================================
section "$lib/luax.lua"
---------------------------------------------------------------------

local lib_luax_sources = {
    ls "libluax/**.lua",
    ls "ext/lua/**.lua",
}

acc(libraries) {
    build "$lib/luax.lua" { "$luax_config_lua", lib_luax_sources,
        description = "LUAX $out",
        command = {
            "PATH=$tmp:$$PATH",
            "LUA_PATH=\"$lua_path\"",
            "CRYPT_KEY=\"$crypt_key\"",
            "$lua -l tools/rc4_runtime luax/luax_bundle.lua -lib -lua $in > $out",
        },
        implicit_in = {
            "$lz4",
            "$lua",
            "luax/luax_bundle.lua",
            "tools/rc4_runtime.lua",
        },
    }
}

--===================================================================
section "$bin/luax-lua"
---------------------------------------------------------------------

acc(binaries) {
    build "$bin/luax-lua" { ls "luax/**.lua",
        description = "LUAX $out",
        command = {
            "PATH=$tmp:$$PATH",
            "LUA_PATH=\"$lua_path\"",
            "CRYPT_KEY=\"$crypt_key\"",
            "LUAX_LIB=$lib",
            "$lua -l tools/rc4_runtime luax/luax.lua -q -t lua -o $out $in",
        },
        implicit_in = {
            "$lz4",
            "$lua",
            "luax/luax_bundle.lua",
            "tools/rc4_runtime.lua",
            "$lib/luax.lua",
        },
    }
}

--===================================================================
section "$bin/luax-pandoc"
---------------------------------------------------------------------

acc(binaries) {
    build "$bin/luax-pandoc" { ls "luax/**.lua",
        description = "LUAX $out",
        command = {
            "PATH=$tmp:$$PATH",
            "LUA_PATH=\"$lua_path\"",
            "CRYPT_KEY=\"$crypt_key\"",
            "LUAX_LIB=$lib",
            "$lua -l tools/rc4_runtime luax/luax.lua -q -t pandoc -o $out $in",
        },
        implicit_in = {
            "$lz4",
            "$lua",
            "luax/luax_bundle.lua",
            "tools/rc4_runtime.lua",
            "$lib/luax.lua",
        },
    }
}

end

if not target and not myapp then
--===================================================================
section "Tests"
---------------------------------------------------------------------

local test_sources = ls "tests/luax-tests/*.*"
local test_main = "tests/luax-tests/main.lua"

local valgrind = {
    case(mode) {
        fast  = {},
        small = {},
        quick = {},
        debug = "VALGRIND=true valgrind --quiet",
    },
}

acc(test) {

---------------------------------------------------------------------

    build "$test/test-1-luax_executable.ok" {
        description = "TEST $out",
        command = {
            valgrind, "$luax -q -o $test/test-luax",
                test_sources : difference(ls "tests/luax-tests/to_be_imported-*.lua"),
            "&&",
            "PATH=$bin:$tmp:$$PATH",
            "LUA_PATH='tests/luax-tests/?.lua;luax/?.lua'",
            "LUA_CPATH='foo/?.so'",
            "TEST_NUM=1",
            "LUAX=$luax",
            "ARCH="..host.zig_arch, "OS="..host.zig_os, "LIBC="..host.zig_libc,
            valgrind, "$test/test-luax Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$luax",
            test_sources,
        },
    },

---------------------------------------------------------------------

    build "$test/test-2-lib.ok" {
        description = "TEST $out",
        command = {
            "export LUA_CPATH=;",
            "eval \"$$($luax env)\";",
            "PATH=$bin:$tmp:$$PATH",
            "LUA_PATH='tests/luax-tests/?.lua'",
            "TEST_NUM=2",
            "ARCH="..host.zig_arch, "OS="..host.zig_os, "LIBC="..host.zig_libc,
            valgrind, "$lua -l libluax", test_main, "Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lua",
            "$luax",
            libraries,
            test_sources,
        },
    },

---------------------------------------------------------------------

    build "$test/test-3-lua.ok" {
        description = "TEST $out",
        command = {
            "PATH=$bin:$tmp:$$PATH",
            "LIBC=lua LUA_PATH='$lib/?.lua;tests/luax-tests/?.lua'",
            "TEST_NUM=3",
            "ARCH="..host.zig_arch, "OS="..host.zig_os, "LIBC=lua",
            "$lua -l luax", test_main, "Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lua",
            "$lib/luax.lua",
            libraries,
            test_sources,
        },
    },

---------------------------------------------------------------------

    build "$test/test-4-lua-luax-lua.ok" {
        description = "TEST $out",
        command = {
            "PATH=$bin:$tmp:$$PATH",
            "LIBC=lua LUA_PATH='$lib/?.lua;tests/luax-tests/?.lua'",
            "TEST_NUM=4",
            "ARCH="..host.zig_arch, "OS="..host.zig_os, "LIBC=lua",
            "$bin/luax-lua", test_main, "Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lua",
            "$bin/luax-lua",
            test_sources,
        },
    },

---------------------------------------------------------------------

    build "$test/test-5-pandoc-luax-lua.ok" {
        description = "TEST $out",
        command = {
            "PATH=$bin:$tmp:$$PATH",
            "LIBC=lua LUA_PATH='$lib/?.lua;tests/luax-tests/?.lua'",
            "TEST_NUM=5",
            "ARCH="..host.zig_arch, "OS="..host.zig_os, "LIBC=lua",
            "pandoc lua -l luax", test_main, "Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lua",
            "$lib/luax.lua",
            libraries,
            test_sources,
        },
    },

---------------------------------------------------------------------

    build "$test/test-ext-1-lua.ok" { "tests/external_interpreter_tests/external_interpreters.lua",
        description = "TEST $out",
        command = {
            "eval \"$$($luax env)\";",
            "$luax -q -t lua -o $test/ext-lua $in",
            "&&",
            "PATH=$bin:$tmp:$$PATH",
            "TARGET=lua",
            "$test/ext-lua Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lib/luax.lua",
            "$luax",
            binaries,
        },
    },

---------------------------------------------------------------------

    build "$test/test-ext-3-luax.ok" { "tests/external_interpreter_tests/external_interpreters.lua",
        description = "TEST $out",
        command = {
            "eval \"$$($luax env)\";",
            "$luax -q -t luax -o $test/ext-luax $in",
            "&&",
            "PATH=$bin:$tmp:$$PATH",
            "TARGET=luax",
            "$test/ext-luax Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lib/luax.lua",
            "$luax",
        },
    },

---------------------------------------------------------------------

    build "$test/test-ext-4-pandoc.ok" { "tests/external_interpreter_tests/external_interpreters.lua",
        description = "TEST $out",
        command = {
            "eval \"$$($luax env)\";",
            "$luax -q -t pandoc -o $test/ext-pandoc $in",
            "&&",
            "PATH=$bin:$tmp:$$PATH",
            "TARGET=pandoc",
            "$test/ext-pandoc Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "$lib/luax.lua",
            "$luax",
            binaries,
        },
    },

---------------------------------------------------------------------

}
end

if not target and not myapp then
--===================================================================
section "Documentation"
---------------------------------------------------------------------

local markdown_sources = ls "doc/src/*.md"

rule "lsvg" {
    command = "lsvg $in -o $out --MF $depfile -- $args",
    depfile = "$builddir/tmp/lsvg/$out.d",
}

local images = {
    build "doc/luax-banner.svg"         {"lsvg", "doc/src/luax-logo.lua", args={1024,  192}},
    build "doc/luax-logo.svg"           {"lsvg", "doc/src/luax-logo.lua", args={ 256,  256}},
    build "$builddir/luax-banner.png"   {"lsvg", "doc/src/luax-logo.lua", args={1024,  192, "sky"}},
    build "$builddir/luax-banner.jpg"   {"lsvg", "doc/src/luax-logo.lua", args={1024,  192, "sky"}},
    build "$builddir/luax-social.png"   {"lsvg", "doc/src/luax-logo.lua", args={1280,  640, F.show(URL)}},
    build "$builddir/luax-logo.png"     {"lsvg", "doc/src/luax-logo.lua", args={1024, 1024}},
    build "$builddir/luax-logo.jpg"     {"lsvg", "doc/src/luax-logo.lua", args={1024, 1024}},
}

acc(doc)(images)

local pandoc_gfm = {
    "pandoc",
    "--to gfm",
    "--lua-filter doc/src/fix_links.lua",
    "--fail-if-warnings",
}

rule "ypp" {
    description = "YPP $in",
    command = {
        "LUAX=$luax",
        "ypp --MD --MT $out --MF $depfile $in -o $out",
    },
    depfile = "$out.d",
    implicit_in = {
        "$luax",
    },
}

rule "md_to_gfm" {
    description = "PANDOC $out",
    command = {
        pandoc_gfm, "$in -o $out",
    },
    implicit_in = {
        "doc/src/fix_links.lua",
        images,
    },
}

acc(doc) {

    build "README.md" { "md_to_gfm",
        build "$tmp/doc/README.md" { "ypp", "doc/src/luax.md" },
    },

    markdown_sources : map(function(src)
        return build("doc"/src:basename()) { "md_to_gfm",
            build("$tmp"/src) { "ypp", src },
        }
    end)

}

end

--===================================================================
section "Shorcuts"
---------------------------------------------------------------------

acc(compile) {binaries, libraries}

install "bin" {binaries}
if not myapp then
    install "bin" "tools/luaxc"
    install "lib" {libraries}
end

clean "$builddir"

phony "compile" (compile)
default "compile"
help "compile" "compile LuaX"

if not target and #test > 0 and not myapp then

    phony "test-fast" (test[1])
    help "test-fast" "run LuaX tests (fast, native tests only)"

    phony "test" (test)
    help "test" "run all LuaX tests"

end

if not target and not myapp then
    phony "doc" (doc)
    help "doc" "update LuaX documentation"
end

phony "all" {"compile", not target and not myapp and {"test", "doc"} or {}}
help "all" "alias for compile, test and doc"

phony "update" "update_modules"
help "update" "update third-party modules"
