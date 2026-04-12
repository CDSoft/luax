section [[
This file is part of bang.

bang is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bang is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bang.  If not, see <https://www.gnu.org/licenses/>.

For further information about bang you can visit
https://codeberg.org/cdsoft/bang
]]

local F = require "F"

version "3.6"

help.name "Bang"
help.description [[Ninja file for building $name]]
help.epilog [[Without any arguments, Ninja will compile and test $name.]]

---------------------------------------------------------------------
-- Build directories
---------------------------------------------------------------------

section "Build directories"

var "bin"     "$builddir"
var "test"    "$builddir/test"

clean "$builddir"

---------------------------------------------------------------------
-- Compilation
---------------------------------------------------------------------

section "Compilation"

local sources = {
    ls "src/*.lua",
    file "$builddir/bang-version" { vars.version },
}

build.luax.add_global "flags" "-q"

local binaries = {
    build.luax.native "$bin/bang" { sources },
    build.luax.lua "$bin/bang.lua" { sources },
}

-- used by LuaX only
local bang_luax = build.luax.luax "$bin/bang.luax" { sources }

local prebuilt = {
    build.cp "bin/bang.lua"  "$bin/bang.lua",
    build.cp "bin/bang.luax" "$bin/bang.luax",
}

phony "compile" { binaries, bang_luax, prebuilt }
default "compile"
help "compile" "compile $name"

install "bin" { binaries }

phony "all" { "compile", "test" }

phony "release" {
    build.tar "$builddir/release/${version}/bang-${version}-lua.tar.gz" {
        base = "$builddir/release/.build",
        name = "bang-${version}-lua",
        build.luax.lua("$builddir/release/.build/bang-${version}-lua/bin/bang.lua") { sources },
    },
    require "targets" : map(function(target)
        return build.tar("$builddir/release/${version}/bang-${version}-"..target.name..".tar.gz") {
            base = "$builddir/release/.build",
            name = "bang-${version}-"..target.name,
            build.luax[target.name]("$builddir/release/.build/bang-${version}-"..target.name/"bin/bang") { sources },
        }
    end),
}

---------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------

section "Tests"

rule "diff" {
    description = "DIFF $in",
    command = "diff $in > $out || (cat $out && false)",
}

rule "run_test" {
    description = "BANG $in",
    command = {
        "rm -f $test_dir/new_file.txt;",
        "rm -f $test_dir/compile_flags.txt;", -- ensures the timestamp changes
        "$bang -g $bang -q $in -o $out -- arg1 arg2 -x=y",
    },
}

rule "run_test-builddir" {
    description = "BANG $in",
    command = "$bang -g $bang -q $in -o $out $args",
}

rule "run_test-future-version" {
    description = "BANG $in",
    command = "$bang -g $bang -q $in -o $out",
}

rule "run_test-default" {
    description = "BANG $in",
    command = "$bang -g $bang -q $in -o $out",
}

rule "run_test-error" {
    description = "BANG $in",
    command = "$bang -g $bang -q $in -o $ninja_file 2> $out; test $$? -ne 0",
}

rule "missing" {
    description = "TEST $missing",
    command = "test ! -f $missing_file > $out",
}

rule "run_test-error-unknown_file" {
    description = "BANG $in",
    command = "$bang -g $bang -q $unknown_input -o $ninja_file 2> $out; test $$? -ne 0",
}

section "Functional tests"

phony "test" {

    F{
        { "$bin/bang",     "$test/luax" },
        { "$bin/bang.lua", "$test/lua"  },
    }
    : map(function(bang_test_dir)
        local bang, test_dir = F.unpack(bang_test_dir)
        local interpreter = test_dir:basename()
        section("Test of the "..interpreter.." interpreter")
        return {

            -- Nominal tests
            build(test_dir/"test.ninja") { "run_test", "test/test.lua",
                bang = bang,
                test_dir = test_dir,
                implicit_in = bang,
                implicit_out = {
                    test_dir/"new_file.txt",
                    test_dir/"compile_flags.txt",
                },
                validations = {
                    build(test_dir/"test.diff")     {"diff", {test_dir/"test.ninja",   "test/test-"..interpreter..".ninja"}},
                    build(test_dir/"new_file.diff") {"diff", {test_dir/"new_file.txt", "test/new_file.txt"}},
                    build(test_dir/"compile_flags.diff") {"diff", {test_dir/"compile_flags.txt", "test/compile_flags.txt"}},
                },
            },

            -- builddir
            ls "test/test-builddir-*.lua"
            : mapi(function(i, src)
                local ninja     = test_dir/src:basename():chext".ninja"
                local diff_res  = test_dir/src:basename():chext".diff"
                local ninja_ref = src:chext".ninja"
                return build(ninja) { "run_test-builddir", src,
                    args = case(i) {
                        [1] = {},
                        [2] = {},
                        [Nil] = "-b custom_build",
                    },
                    bang = bang,
                    implicit_in = bang,
                    validations = build(diff_res) { "diff", ninja, ninja_ref },
                }
            end),

            -- ninja_required_version
            ls "test/test-future-version-*.lua"
            : map(function(src)
                local ninja     = test_dir/src:basename():chext".ninja"
                local diff_res  = test_dir/src:basename():chext".diff"
                local ninja_ref = src:chext".ninja"
                return build(ninja) { "run_test-future-version", src,
                    bang = bang,
                    implicit_in = bang,
                    validations = build(diff_res) { "diff", ninja, ninja_ref },
                }
            end),

            -- default targets
            ls "test/test-default-*.lua"
            : map(function(src)
                local ninja     = test_dir/src:basename():chext".ninja"
                local diff_res  = test_dir/src:basename():chext".diff"
                local ninja_ref = src:splitext().."-"..interpreter..".ninja"
                return build(ninja) { "run_test-default", src,
                    bang = bang,
                    implicit_in = bang,
                    validations = build(diff_res) { "diff", ninja, ninja_ref },
                }
            end),

            -- errors
            ls "test/test-err-*.lua"
            : map(function(src)
                local ninja         = test_dir/src:basename():chext".ninja"
                local ninja_missing = test_dir/src:basename():chext".ninja-missing"
                local diff_res      = test_dir/src:basename():chext".diff"
                local stderr        = test_dir/src:basename():chext".stderr"
                local stderr_ref    = src:chext".stderr"
                return build(stderr) { "run_test-error", src,
                    bang = bang,
                    implicit_in = bang,
                    ninja_file = ninja,
                    validations = {
                        build(diff_res)      { "diff", stderr, stderr_ref },
                        build(ninja_missing) { "missing", stderr, missing_file=ninja },
                    },
                }
            end),

            -- unknown file
            F{ "test/unknown_file.lua" }
            : map(function(src)
                local ninja         = test_dir/src:basename():chext".ninja"
                local ninja_missing = test_dir/src:basename():chext".ninja-missing"
                local diff_res      = test_dir/src:basename():chext".diff"
                local stderr        = test_dir/src:basename():chext".stderr"
                local stderr_ref    = src:chext".stderr"
                return build(stderr) { "run_test-error-unknown_file",
                    bang = bang,
                    implicit_in = bang,
                    ninja_file = ninja,
                    unknown_input = src,
                    validations = {
                        build(diff_res)      { "diff", stderr, stderr_ref },
                        build(ninja_missing) { "missing", stderr, missing_file=ninja },
                    },
                }
            end),

        }
    end),

}

section "Stress tests"

phony "stress" {
    build "$test/stress/main.c" { "test/stress-gen.lua",
        description = "[stress test] Generate a HUGE C project",
        command = "$in $out",
        pool = "console",
    },
    build "$test/stress.ninja" { "test/stress.lua",
        description = "[stress test] BANG $in",
        command = "time $bin/bang $in -o $out -- $test/stress",
        pool = "console",
        implicit_in = {
            "$bin/bang",
            "$test/stress/main.c",
        },
    },
    build "$test/stress.done" { "$test/stress.ninja",
        description = "[stress test] NINJA $in",
        command = "time ninja -f $in && touch $out",
        pool = "console",
        implicit_in = "$test/stress.ninja",
    },
}

default "test"
help "test" "test $name"
