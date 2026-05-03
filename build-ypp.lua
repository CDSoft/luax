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
section "Ypp"
-------------------------------------------------------------------------------

local F = require "F"
local targets = require "luax-targets"

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

local ypp_sources = ls "ypp/*.lua"

-------------------------------------------------------------------------------
-- Compilation
-------------------------------------------------------------------------------

acc(compile) {
    luax.lua    "$builddir/bin/ypp.lua"        { ypp_sources },
    luax.pandoc "$builddir/bin/ypp-pandoc.lua" { ypp_sources },
    luax.native "$builddir/bin/ypp"            { ypp_sources },

    -- Add prebuilt scripts to the repository
    build.cp "bin/ypp.lua"        "$builddir/bin/ypp.lua",
    build.cp "bin/ypp-pandoc.lua" "$builddir/bin/ypp-pandoc.lua",
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

local function build_release(target)
    local archive = archive(target)
    return {
        cp_to(archive/"bin") {
            "$builddir/bin/ypp.lua",
            "$builddir/bin/ypp-pandoc.lua",
        },
        target.name and luax[target.name](archive/"bin/ypp") { ypp_sources },
    }
end

local function build_standalone(target)
    local dir = standalone_dir()
    if target == "lua" then
        return {
            luax.lua(dir/"ypp.lua") { ypp_sources },
            luax.pandoc(dir/"ypp-pandoc.lua") { ypp_sources },
        }
    else
        return luax[target.name](dir/"ypp-"..target.name) { ypp_sources }
    end
end

acc(release) {
    targets : map(build_release),
    build_release "lua",
}
acc(standalone) {
    targets : map(build_standalone),
    build_standalone "lua",
}

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

acc(test) {
    build "$builddir/tests/ypp/test.md" { "ypp/tests/test.md",
        description = "YPP $in",
        command = {
            "export PATH=$cache:$$PATH;",
            "export BUILD=$builddir;",
            "export YPP_IMG=[$builddir/tests/ypp/]ypp_images;",
            "$builddir/bin/ypp-pandoc.lua",
                "-t svg",
                "--MF $depfile",
                "-p", "ypp/tests",
                "-l", "test.lua",
                "-l", "mod1",
                "-l", "mymod=mod2",
                "-l", "_=mod3",
                "-e", "'VAR1 = 2 * 3 * 7'",
                "-e", "'VAR2 = [[43]]'",
                "-DVAR3=44",
                "-DVAR4=val4",
                "-DVAR5=",
                "-DVAR6",
                "$in",
                "-o $out",
            "&& touch $builddir/tests/ypp/ypp_images/hello.svg.meta",   -- to avoid useless rebuilds
        },
        depfile = "$out.d",
        implicit_in = {
            "$builddir/bin/ypp-pandoc.lua",
        },
        implicit_out = {
            "$builddir/tests/ypp/test.md.d",
            "$builddir/tests/ypp/test-file.txt",
            -- Images meta files are not touched when their contents are not changed
            -- Ninja will consider them as always dirty => "ninja test" may always have something to do
            -- This is for test purpose only. In normal usage, meta files are internal files, not output files.
            "$builddir/tests/ypp/ypp_images/hello.svg.meta",
        },
        validations = F{
            { "$builddir/tests/ypp/test.md", "ypp/tests/test-ref.md" },
            { "$builddir/tests/ypp/test.md.d", "ypp/tests/test-ref.d" },
            { "$builddir/tests/ypp/test-file.txt", "ypp/tests/test-file.txt" },
            { "$builddir/tests/ypp/ypp_images/hello.svg.meta", "ypp/tests/hello.svg.meta" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test123-no-separator.md" { "ypp/tests/test1.md", "ypp/tests/test2.md", "ypp/tests/test3.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "--MF $depfile",
                "$in",
                "-o $out",
        },
        depfile = "$out.d",
        implicit_in = {
            "$builddir/bin/ypp",
        },
        implicit_out = {
            "$builddir/tests/ypp/test123-no-separator.md.d",
        },
        validations = F{
            { "$builddir/tests/ypp/test123-no-separator.md", "ypp/tests/test123-no-separator-ref.md" },
            { "$builddir/tests/ypp/test123-no-separator.md.d", "ypp/tests/test123-no-separator-ref.d" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test123-separator.md" { "ypp/tests/test1.md", "ypp/tests/test2.md", "ypp/tests/test3.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "--MF $depfile",
                "$in",
                "-o $out",
                "-s",
        },
        depfile = "$out.d",
        implicit_in = {
            "$builddir/bin/ypp",
        },
        implicit_out = {
            "$builddir/tests/ypp/test123-separator.md.d",
        },
        validations = F{
            { "$builddir/tests/ypp/test123-separator.md", "ypp/tests/test123-separator-ref.md" },
            { "$builddir/tests/ypp/test123-separator.md.d", "ypp/tests/test123-separator-ref.d" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test-error.err" { "ypp/tests/test-error.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "-p", "ypp/tests",
                "-l", "test.lua",
                "$in",
                "2> $out",
                ";",
            "test $$? -ne 0",
        },
        implicit_in = {
            "$builddir/bin/ypp",
        },
        validations = F{
            { "$builddir/tests/ypp/test-error.err", "ypp/tests/test-error-ref.err" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test-error-color.err" { "ypp/tests/test-error.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "-a",
                "-p", "ypp/tests",
                "-l", "test.lua",
                "$in",
                "2> $out",
                ";",
            "test $$? -ne 0",
        },
        implicit_in = {
            "$builddir/bin/ypp",
        },
        validations = F{
            { "$builddir/tests/ypp/test-error-color.err", "ypp/tests/test-error-color-ref.err" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test-syntax-error.err" { "ypp/tests/test-syntax-error.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "$in",
                "2> $out",
                ";",
            "test $$? -ne 0",
        },
        implicit_in = {
            "$builddir/bin/ypp",
        },
        validations = F{
            { "$builddir/tests/ypp/test-syntax-error.err", "ypp/tests/test-syntax-error-ref.err" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
    build "$builddir/tests/ypp/test-syntax-error-color.err" { "ypp/tests/test-syntax-error.md",
        description = "YPP $in",
        command = {
            "$builddir/bin/ypp",
                "-a",
                "$in",
                "2> $out",
                ";",
            "test $$? -ne 0",
        },
        implicit_in = {
            "$builddir/bin/ypp",
        },
        validations = F{
            { "$builddir/tests/ypp/test-syntax-error-color.err", "ypp/tests/test-syntax-error-color-ref.err" },
        } : map(function(files)
            return build(files[1]..".diff") { "diff", files }
        end),
    },
}

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

acc(doc) {
    build.lsvg.svg "ypp/doc/ypp-banner.svg" {"luax/doc/luax-logo.lua", args={1024, 192, "--name ypp"}},
    ls "ypp/doc/*.md.in" : map(function(src)
        return gfm((src:splitext())) { src }
    end),
}

-------------------------------------------------------------------------------
-- Install Ypp
-------------------------------------------------------------------------------

install "bin" {
    "$builddir/bin/ypp.lua",
    "$builddir/bin/ypp-pandoc.lua",
    "$builddir/bin/ypp",
}
