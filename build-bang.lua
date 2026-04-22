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
section "Bang"
-------------------------------------------------------------------------------

local F = require "F"
local targets = require "luax-targets"

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

local bang_sources = ls "bang/*.lua"

-------------------------------------------------------------------------------
-- Compilation
-------------------------------------------------------------------------------

acc(compile) {
    luax.lua    "$builddir/bin/bang.lua" { bang_sources },
    luax.native "$builddir/bin/bang"     { bang_sources },

    -- Add prebuilt scripts to the repository
    build.cp "bin/bang.lua" "$builddir/bin/bang.lua",
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

local function build_release(target)
    local archive = archive(target)
    return {
        cp_to(archive/"bin") {
            "$builddir/bin/bang.lua",
        },
        target.name and luax[target.name](archive/"bin/bang") { bang_sources },
    }
end

acc(release) {
    targets : map(build_release),
    build_release "lua",
}

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

rule "diff" {
    description = "DIFF $in",
    command = "diff $in > $out || (cat $out && false)",
}

rule "run_test" {
    description = "BANG $in",
    command = {
        "rm -f $builddir/bang/tests/new_file.txt;",
        "rm -f $builddir/bang/tests/compile_flags.txt;", -- ensures the timestamp changes
        "PATH=$cache:$$PATH $bang -g $bang -q $in -o $out -- arg1 arg2 -x=y",
    },
    implicit_in = "$bang",
}

rule "run_test-builddir" {
    description = "BANG $in",
    command = "PATH=$cache:$$PATH $bang -g $bang -q $in -o $out $args",
    implicit_in = "$bang",
}

rule "run_test-future-version" {
    description = "BANG $in",
    command = "PATH=$cache:$$PATH $bang -g $bang -q $in -o $out",
    implicit_in = "$bang",
}

rule "run_test-default" {
    description = "BANG $in",
    command = "PATH=$cache:$$PATH $bang -g $bang -q $in -o $out",
    implicit_in = "$bang",
}

rule "run_test-error" {
    description = "BANG $in",
    command = "PATH=$cache:$$PATH $bang -g $bang -q $in -o $ninja_file 2> $out; test $$? -ne 0",
    implicit_in = "$bang",
}

rule "missing" {
    description = "TEST $missing",
    command = "test ! -f $missing_file > $out",
}

rule "run_test-error-unknown_file" {
    description = "BANG $in",
    command = "PATH=$cache:$$PATH $bang -g $bang -q $unknown_input -o $ninja_file 2> $out; test $$? -ne 0",
    implicit_in = "$bang",
}

acc(test) {

    F{
        { "$builddir/bin/bang",     "$builddir/tests/bang/luax" },
        { "$builddir/bin/bang.lua", "$builddir/tests/bang/lua"  },
    }
    : map(function(bang_test_dir)
        local bang, test_dir = F.unpack(bang_test_dir)
        local interpreter = test_dir:basename()
        return {

            -- Nominal tests
            build(test_dir/"test.ninja") { "run_test", "bang/tests/test.lua",
                bang = bang,
                test_dir = test_dir,
                implicit_in = bang,
                implicit_out = {
                    test_dir/"new_file.txt",
                    test_dir/"compile_flags.txt",
                },
                validations = {
                    build(test_dir/"test.diff")     {"diff", {test_dir/"test.ninja",   "bang/tests/test-"..interpreter..".ninja"}},
                    build(test_dir/"new_file.diff") {"diff", {test_dir/"new_file.txt", "bang/tests/new_file.txt"}},
                    build(test_dir/"compile_flags.diff") {"diff", {test_dir/"compile_flags.txt", "bang/tests/compile_flags.txt"}},
                },
            },

            -- builddir
            ls "bang/tests/test-builddir-*.lua"
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
            ls "bang/tests/test-future-version-*.lua"
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
            ls "bang/tests/test-default-*.lua"
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
            ls "bang/tests/test-err-*.lua"
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
            F{ "bang/tests/unknown_file.lua" }
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

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

acc(doc) {
    build.lsvg.svg "bang/doc/bang-banner.svg" {"luax/doc/luax-logo.lua", args={1024, 192, "--name Bang"}},
    ls "bang/doc/*.md.in" : map(function(src)
        return gfm((src:splitext())) { src }
    end),
}

-------------------------------------------------------------------------------
-- Install Bang
-------------------------------------------------------------------------------

install "bin" {
    "$builddir/bin/bang.lua",
    "$builddir/bin/bang",
}
