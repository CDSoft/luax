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
section "lsvg"
-------------------------------------------------------------------------------

local F = require "F"
local targets = require "luax-targets"

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

local lsvg_sources = ls "lsvg/*.lua"

-------------------------------------------------------------------------------
-- Compilation
-------------------------------------------------------------------------------

acc(compile) {
    luax.lua    "$builddir/bin/lsvg.lua" { lsvg_sources },
    luax.native "$builddir/bin/lsvg"     { lsvg_sources },

    -- Add prebuilt scripts to the repository
    build.cp "bin/lsvg.lua" "$builddir/bin/lsvg.lua",
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

local function build_release(target)
    local archive = archive(target)
    return {
        cp_to(archive/"bin") {
            "$builddir/bin/lsvg.lua",
        },
        target ~= "lua" and {
            luax[target.name](archive/"bin/lsvg") {
                lsvg_sources,
            },
        } or {},
    }
end

acc(release) {
    targets : map(build_release),
    build_release "lua",
}

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

rule "lsvg" {
    description = "LSVG $in",
    command = {
        "LUA_PATH=lsvg/tests/?.lua",
        "PATH=$cache:$$PATH $lsvg $in -o $out --MF $depfile -- lsvg demo",
    },
    depfile = "$out.d",
    implicit_in = "$lsvg",
}


local test_envs = F{
    { "$builddir/bin/lsvg",     "$builddir/tests/lsvg/luax" },
    { "$builddir/bin/lsvg.lua", "$builddir/tests/lsvg/lua" },
}

acc(test) {
    ls "lsvg/tests/*.lua" : map(function(input)
        return test_envs : map(function(test_env)
            local lsvg, test_dir = F.unpack(test_env)
            local test_type = test_dir:basename()

            local output_svg = test_dir / input:basename():splitext()..".svg"
            local ref = input:splitext()..".svg"
            local output_ok = output_svg:splitext()..".ok"
            local output_svg_d = output_svg..".d"
            local ref_d = ref.."."..test_type..".d"
            local output_deps_ok = output_svg:splitext()..".d.ok"
            return build(output_svg) { "lsvg", input,
                lsvg = lsvg,
                implicit_in = lsvg,
                implicit_out = output_svg_d,
                validations = {
                    build(output_ok)      { "diff", ref, output_svg },
                    build(output_deps_ok) { "diff", ref_d, output_svg_d },
                },
            }
        end)
    end)
}

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

acc(doc) {
    build.lsvg.svg "doc/lsvg/lsvg-banner.svg" {"luax/doc/luax-logo.lua", args={1024, 192, "--name lsvg"}},
    gfm2gfm "doc/lsvg/README.md" { "lsvg/doc/README.md" },
    build.cp "doc/lsvg/tests/demo.lua" "lsvg/tests/demo.lua",
    build.cp "doc/lsvg/tests/demo.svg" "lsvg/tests/demo.svg",
}

-------------------------------------------------------------------------------
-- Install lsvg
-------------------------------------------------------------------------------

install "bin" {
    "$builddir/bin/lsvg.lua",
    "$builddir/bin/lsvg",
}
