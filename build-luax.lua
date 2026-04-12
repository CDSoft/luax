-------------------------------------------------------------------------------
section "LuaX"
-------------------------------------------------------------------------------

var "cache"       ".cache"
var "zig_version" "0.15.2"
var "zig_key"     "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"
var "zig_path"    "$cache/zig/$zig_version"
var "zig"         "$zig_path/zig"

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

local libluax_lua_sources = F.flatten { ls "lib/luax/**.lua" }
local libluax_luax_sources = F.flatten { libluax_lua_sources, ls "luax/ext/**.lua" }
local luax_lua_sources = ls "luax/*.lua"

local luax_c_sources = ls "luax/*.c"
local lua_c_sources = ls "lua/*.c" : difference { "lua/lua.c" }
local ext_c_sources = ls "luax/ext/**.c"

-------------------------------------------------------------------------------
-- LuaX compilers
-------------------------------------------------------------------------------

-- Compile using LuaX sources
build.luax.set_global "luax" "tools/luax.sh"
build.luax.add_global "implicit_in" (F.flatten{ libluax_lua_sources, libluax_luax_sources, luax_lua_sources, "tools/luax.sh" }:nub())
build.luax.add_global "flags" { "-q" }

-- Compile using LuaX sources and binaries generated in $builddir
luax_build = F(targets) : map2t(function(target)
    return target.name, build.luax[target.name] : new("luax-build-"..target.name)
        : set "luax" "tools/luax-build.sh"
        : add "implicit_in" "tools/luax-build.sh"
end)
luax_build.native = build.luax.native : new "luax-build"
    : set "luax" "tools/luax-build.sh"
    : add "implicit_in" "tools/luax-build.sh"

-------------------------------------------------------------------------------
-- Zig cross-compiler
-------------------------------------------------------------------------------

build "$zig" {
    command = { "tools/install_zig.sh $zig_version $out $zig_key", version.url:gsub("/", "-") },
    pool = "console",
}

-------------------------------------------------------------------------------
-- Generate the pure-Lua LuaX interpreters and library
-------------------------------------------------------------------------------

acc(compile) {
    build.luax.lua "bin/luax.lua" { luax_lua_sources },
    build.luax.pandoc "bin/luax-pandoc.lua" { luax_lua_sources },
    build.luax.luax "lib/libluax.lua" { libluax_lua_sources },
}

-------------------------------------------------------------------------------
-- Compile the LuaX loaders for all supported targets
-------------------------------------------------------------------------------

local cflags = build.compile_flags {
    "-std=gnu2x",
    "-O3",
    "-pipe",
    "-fPIC",
    "-Ilua",
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
    "-s",
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
    }

    if target.name == sys.name then
        build.compile_flags {
            F{target_flags, lua_flags}
                : flatten()
                : map(function(s) return s:gsub("'", "") end)
        }
    end

    local zigcc = build.zigcc[target.name] : new("cc-"..target.name)
        : add "cflags" { cflags, lua_flags }
        : add "ldflags" { ldflags }
        : add "ldlibs" {
            "-lm",
            case(target.os) {
                windows = "-lshlwapi",
            },
        }
        : add "implicit_in" { "$zig" }

    local zigcc_luax = zigcc : new("cc-luax-"..target.name)
        : add "cflags" { luax_cflags, target_flags }

    local zigcc_lua = zigcc : new("cc-lua-"..target.name)
        : add "cflags" { target_flags }

    local zigcc_ext = zigcc : new("cc-ext-"..target.name)
        : add "cflags" { }

    return zigcc_luax:executable("$builddir/lib/luax/luax-loader-"..target.name..target.exe) {
        zigcc_luax:static_lib("$builddir/tmp"/target.name/"libluax.a") { luax_c_sources },
        zigcc_lua:static_lib("$builddir/tmp"/target.name/"liblua.a") { lua_c_sources },
        zigcc_ext:static_lib("$builddir/tmp"/target.name/"libext.a") {
            ext_c_sources : difference(
                target.os == "windows" and {
                    "luax/ext/linenoise/linenoise.c",
                } or {})
        },
    }

end)

-------------------------------------------------------------------------------
-- Install the LuaX libraries in $builddir
-------------------------------------------------------------------------------

local installed_libs = {
    libluax_luax_sources : map(function(name) return build.cp("$builddir/lib/luax/"/name:basename()) { name } end),
    luax_lua_sources : map(function(name) return build.cp("$builddir/bin"/name:basename()) { name } end),
}

-------------------------------------------------------------------------------
-- Generate the native LuaX interpreter
-------------------------------------------------------------------------------

local interpreter = luax_build.native "$builddir/bin/luax" {
    luax_lua_sources,
    implicit_in = {
        installed_libs,
        loaders,
    },
}

acc(compile) {
    loaders,
    interpreter,
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

function archive(target)
    return "$builddir/release"/version.version/"luax-"..version.version.."-"..target.name
end

function cp_to(dest) return function(files)
    return F.flatten{files} : map(function(file)
        return build.cp(dest/file:basename()) { file }
    end)
end end

acc(release) {
    targets : map(function(target)
        local archive = archive(target)
        return {
            cp_to(archive/"bin") {
                "bin/luax.lua",
                "bin/luax-pandoc.lua",
            },
            luax_build[target.name](archive/"bin/luax") {
                luax_lua_sources,
                implicit_in = {
                    installed_libs,
                    loaders,
                },
            },
            cp_to(archive/"lib") {
                "lib/libluax.lua",
            },
            cp_to(archive/"lib/luax") {
                libluax_luax_sources,
                loaders,
            },
        }
    end)
}

-------------------------------------------------------------------------------
-- luarc.json
-------------------------------------------------------------------------------

if bang.output:dirname() == bang.input:dirname() then
    local function dirs(path)
        return fs.ls(path/"**.lua")
            : map(F.compose{F.prefix"    \"", F.suffix"\",", fs.dirname})
            : nub() : unlines() : rtrim() : gsub(",$", "")
    end
    file(bang.input:dirname()/".luarc.json")(F.unlines(F.flatten{
        "{",
        [=[  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",]=],
        [=[  "runtime.version": "Lua 5.5",]=],
        [=[  "workspace.library": []=],
        dirs "lib/luax" .. ",",
        dirs "luax/ext",
        [=[  ],]=],
        [=[  "workspace.checkThirdParty": false]=],
        "}",
    }))
end

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

local imported_test_sources = ls "tests/luax/luax-tests/to_be_imported-*.lua"
local test_sources = {
    ls "tests/luax/luax-tests/*.*" : difference(imported_test_sources),
}
local test_main = "tests/luax/luax-tests/main.lua"

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
build.cc "$httpd" { "tests/luax/luax-tests/httpd.c" }

local pandoc_version = (sh"pandoc --version" or "0") : match"[%d%.]+" : split"%." : map(tonumber)
local has_pandoc = F.op.uge(pandoc_version, {3, 1, 12, 3})

acc(test) {

    build "$builddir/tests/luax/test-1-luax_executable.ok" { test_sources,
        description = "test $out",
        command = {
            sanitizer_options,
            "$builddir/bin/luax compile -q -b -k test-1-key -o $builddir/tests/luax/test-luax $in",
            "&&",
            "PATH=$builddir/bin:$$PATH",
            "LUA_PATH='tests/luax/luax-tests/?.lua'",
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


    ({"native"} .. native_targets) : mapi(function(i, target_name)
        local test_libc = ("-musl"):is_suffix_of(target_name) and "musl" or libc
        local test_name = target_name=="native" and sys.name or target_name
        local exe_name = "$builddir/tests/luax/test-compiled".."-"..i
        return build("$builddir/tests/luax/test-1-"..i.."-compiled_executable.ok") { test_sources,
            description = "test $out",
            command = {
                sanitizer_options,
                "$builddir/bin/luax compile -q", "-t", target_name, "-b -k test-1-key",
                    "-o", exe_name,
                    "$in",
                "&&",
                "PATH=$builddir/luax/bin:$$PATH",
                "LUA_PATH='tests/luax/luax-tests/?.lua'",
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
                libraries,
                imported_test_sources,
            },
        }
    end),

    has_pandoc and build "$builddir/tests/luax/test-5-pandoc-luax-lua.ok" { test_main,
        description = "test $out",
        command = {
            sanitizer_options,
            "PATH=bin:$$PATH",
            "LUA_PATH='lib/?.lua;tests/luax/luax-tests/?.lua'",
            "TEST_NUM=5",
            test_options,
            "ARCH="..sys.arch, "OS="..sys.os, "LIBC=lua", "EXE="..sys.exe, "SO="..sys.so, "NAME="..sys.name,
            "pandoc lua -l libluax $in Lua is great",
            "&&",
            "touch $out",
        },
        implicit_in = {
            "lib/libluax.lua",
            libraries,
            test_sources,
            imported_test_sources,
        },
    } or {},

    build "$builddir/tests/luax/test-ext-1-lua.ok" { "tests/luax/external_interpreter_tests/external_interpreters.lua",
        description = "test $out",
        command = {
            sanitizer_options,
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

    build "$builddir/tests/luax/test-ext-2-luax.ok" { "tests/luax/external_interpreter_tests/external_interpreters.lua",
        description = "test $out",
        command = {
            sanitizer_options,
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

    has_pandoc and build "$builddir/tests/luax/test-ext-4-pandoc.ok" { "tests/luax/external_interpreter_tests/external_interpreters.lua",
        description = "test $out",
        command = {
            sanitizer_options,
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

}

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

build.ypp
    : set "cmd" "tools/ypp.sh"
    : add "implicit_in" { "tools/ypp.sh", ls "ypp/*.lua", "$builddir/bin/luax" }
    : set "depfile" "$builddir/tmp/$out.d"
    : add "flags" "-a"

build.lsvg.svg
    : set "cmd" "tools/lsvg.sh"
    : add "implicit_in" { "tools/lsvg.sh", ls "lsvg/*.lua", "$builddir/bin/luax" }
    : set "depfile" "$builddir/tmp/$out.d"

local markdown_sources = ls "luax/doc/*.md"

local ypp_config_params = {
    build.ypp_vars {
        LUAX = "$builddir/bin/luax",
        AUTHORS = version.author,
    },
}

gfm = pipe {
    build.ypp : new "ypp.md"
        : add "implicit_in" "lib/libluax.lua"
        : add "flags" { ypp_config_params },
    build.pandoc_gfm : new "pandoc-gfm-luax"
        : add "flags" {
            "--to=gfm+emoji+definition_lists",
            "--reference-location=section",
            "--lua-filter luax/doc/fix_links.lua",
        }
        : add "implicit_in" { "luax/doc/fix_links.lua" }
}

gfm2gfm = pipe {
    build.ypp : new "ypp-gfm2gfm.md"
        : add "implicit_in" "lib/libluax.lua"
        : add "flags" { ypp_config_params },
    build.pandoc_gfm : new "pandoc-gfm2gfm-luax"
        : add "flags" {
            "--from=gfm",
            "--to=gfm+emoji+definition_lists",
            "--reference-location=section",
            "--lua-filter luax/doc/fix_links.lua",
        }
        : add "implicit_in" { "luax/doc/fix_links.lua" }
}

if has_pandoc then
    acc(doc) {

        build.lsvg.svg "doc/luax/luax-banner.svg" {"luax/doc/luax-logo.lua", args={1024,  192}},
        build.lsvg.svg "doc/luax/luax-logo.svg"   {"luax/doc/luax-logo.lua", args={ 256,  256}},

        markdown_sources : map(function(src)
            return gfm("doc/luax"/src:basename()) { src }
        end),
        build.cp "doc/luax/README.md" "doc/luax/luax.md",

    }
end

-------------------------------------------------------------------------------
-- Install LuaX
-------------------------------------------------------------------------------

install "bin" {
    "bin/luax.lua",
    "bin/luax-pandoc.lua",
    interpreter,
}

install "lib/luax" {
    libluax_luax_sources,
    loaders,
}

install "lib" {
    "lib/libluax.lua",
}
