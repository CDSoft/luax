section [[
Dummy project showing bang capabilities
and many other features enabled by LuaX.

The src directory contains one C source per executable (and per architecture).

The lib directory is a library of sources common to all architectures.

The arch directory contains one sub directory par architecture
and header files defining a common API to all architectures.
]]

local F = require "F"
local fs = require "fs"

var "ex0" "$builddir/ex0"
var "ex1" "$builddir/ex1"

local validation = true

section "Common compilation options"

var "cflags" {
    build.compile_flags {
        "-O3",
        "-Wall",
        "-Werror",
        "-Ilib", "-Iarch",
    },
}
var "ldflags" {
}

rule "clang-tidy" {
    command = {
        "clang-tidy",
        "--quiet",
        "--use-color",
        "--warnings-as-errors=*",
        "-header-filter=.*",
        F{
            "--checks=*",
            "-llvmlibc-restrict-system-libc-headers",
            "-llvm-header-guard",
            "-modernize-macro-to-enum",
            "-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling",
            "-altera-id-dependent-backward-branch",
            "-altera-unroll-loops",
            "-readability-identifier-length",
            "-cppcoreguidelines-macro-to-enum",
            "-portability-avoid-pragma-once",
        }:str",",
        "$in",
        "&> $out",
        "|| (cat $out && false)",
    }
}

section "Example 0: compilation with low level ninja primitives"

-- cc/ar/ld rules for each architecture
local cc = {}
local ar = {}
local ld = {}

local architectures = ls "arch"
    : filter(fs.is_dir)
    : map(function(path)
        local arch_name = path:basename()
        section(arch_name)

        local arch = require(path / "config")
        arch.name = arch_name

        cc[arch_name] = rule("cc_"..arch_name) {
            description = "["..arch_name.."] CC $out",
            command = {
                arch.cc, "-c",
                "$cflags", var("cflags_"..arch_name)(arch.cflags),
                "-MD -MF $depfile",
                "$in -o $out",
            },
            depfile = "$out.d",
        }

        ar[arch_name] = rule("ar_"..arch_name) {
            description = "["..arch_name.."] AR $out",
            command = {arch.ar, "-crs", "$out $in"},
        }

        ld[arch_name] = rule("ld_"..arch_name) {
            description = "["..arch_name.."] LD $out",
            command = {
                arch.ld,
                "$ldflags", var("ldflags_"..arch_name)(arch.ldflags),
                "-o $out $in",
            },
        }

        arch.archive_file = "$ex0" / "arch" / arch_name / "arch.a"
        build(arch.archive_file) { ar[arch_name],
            ls(path/"**.c")
            : map(function(source)
                return build("$ex0" / source:chext".o") {
                    cc[arch_name], source,
                    validations = validation and {
                        build("$ex0/clang-tidy"/source..".check") { "clang-tidy", source },
                    },
                }
            end)
        }

        return arch
    end)

architectures : foreach(function(arch)
    arch.libraries = ls "lib"
        : filter(fs.is_dir)
        : map(function(path)
            local lib_name = path:basename()
            section(lib_name.." for "..arch.name)
            return build("$ex0" / arch.name / "lib" / lib_name / lib_name..".a") {
                ar[arch.name],
                ls(path/"**.c")
                : map(function(source)
                    return build("$ex0" / arch.name / source:chext".o") {
                        cc[arch.name], source,
                        validations = validation and {
                            build("$ex0/clang-tidy"/arch.name/source..".check") { "clang-tidy", source },
                        },
                    }
                end)
            }
        end)
end)

architectures : foreach(function(arch)
    ls "bin/*.c"
    : foreach(function(path)
        local bin_name = path:basename()
        section(bin_name:splitext().." for "..arch.name)
        build("$ex0" / arch.name / "bin" / bin_name:chext(arch.ext)) {
            ld[arch.name], arch.libraries, arch.archive_file,
            build("$ex0" / arch.name / "bin" / bin_name:chext".o") {
                cc[arch.name], path,
                validations = validation and {
                    build("$ex0/clang-tidy"/arch.name/path..".check") { "clang-tidy", path },
                },
            }
        }
    end)
end)

section "Example 1: compilation with the C compilation feature"

ls "arch"
: filter(fs.is_dir)
: map(function(arch_path)
    local arch_name = arch_path:basename()
    section(arch_name)

    local arch = require(arch_path / "config")

    local compiler = arch.compiler
        : set "builddir" ("$ex1" / arch_name)
        : add "cflags" { "$cflags", "$cflags_"..arch_name }
        : add "ldflags" { "$ldflags", "$ldflags_"..arch_name }
        : set "cvalid" "clang-tidy"

    local arch_lib = compiler:static_lib("$ex1" / "arch" / arch_name / "arch.a") {
        ls(arch_path/"**.c")
    }

    ls "bin/*.c"
    : foreach(function(bin_path)
        local bin_name = bin_path:basename():chext(compiler.exe_ext)

        compiler:executable("$ex1" / arch_name / "bin" / bin_name) {
            bin_path,
            arch_lib,
            ls "lib/**.c"
        }
    end)
end)

section "Release"

build.cp "$builddir/dist/linux/bin/hi"            "$builddir/ex1/linux/bin/hi"
build.cp "$builddir/dist/linux/bin/hi-repl"       "$builddir/ex1/linux/bin/hi-repl"
build.cp "$builddir/dist/macos/bin/hi"            "$builddir/ex1/macos/bin/hi"
build.cp "$builddir/dist/macos/bin/hi-repl"       "$builddir/ex1/macos/bin/hi-repl"
build.cp "$builddir/dist/windows/bin/hi.exe"      "$builddir/ex1/windows/bin/hi.exe"
build.cp "$builddir/dist/windows/bin/hi-repl.exe" "$builddir/ex1/windows/bin/hi-repl.exe"

build.tar "$builddir/release/linux.tar.gz"   { base="$builddir/dist", name="linux" }
build.tar "$builddir/release/macos.tar.gz"   { base="$builddir/dist", name="macos" }
build.tar "$builddir/release/windows.tar.gz" { base="$builddir/dist", name="windows" }

build.tar "$builddir/release/all.tar.gz"     { base="$builddir/dist" }

section "Project structure"

local make_graph = pipe {
    build.new "graph.dot"   : set "cmd"   "ninja"
                            : set "args"  "-f $in -t graph > $out",
    build.graphviz.dot.svg,
    build.new "svgtidy.svg" : set "cmd" "doc/svgtidy.lua"
                            : set "args" "< $in > $out",
}

make_graph "doc/graph.svg" "build.ninja"

-- this is equivalent to the following statement, without pipe issues:
--[[
build "doc/graph.svg" { "build.ninja",
    description = "GRAPH $out",
    command = "ninja -f $in -t graph | dot -Tsvg | doc/svgtidy.lua > $out",
}
--]]
