-------------------------------------------------------------------------------
section "Bang"
-------------------------------------------------------------------------------

local F = require "F"
local fs = require "fs"
local sh = require "sh"
local sys = require "sys"
local targets = require "luax-targets"
local version = require "luax-version"

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

local bang_sources = ls "bang/*.lua"

-------------------------------------------------------------------------------
-- Generate the pure-Lua Bang implementation
-------------------------------------------------------------------------------

acc(compile) {
    build.luax.lua "bin/bang.lua" { bang_sources },
}

-------------------------------------------------------------------------------
-- Generate the release archives
-------------------------------------------------------------------------------

acc(release) {
    targets : map(function(target)
        local archive = archive(target)
        return {
            cp_to(archive/"bin") {
                "bin/bang.lua",
            },
            luax_build[target.name](archive/"bin/bang") {
                bang_sources,
            },
        }
    end)
}

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Documentation
-------------------------------------------------------------------------------

acc(doc) {
    build.lsvg.svg "doc/bang/bang-banner.svg" {"luax/doc/luax-logo.lua", args={1024, 192, "--name Bang"}},
    gfm2gfm "doc/bang/README.md" { "bang/doc/README.md" },
}

-------------------------------------------------------------------------------
-- Install Bang
-------------------------------------------------------------------------------

install "bin" {
    "bin/bang.lua",
    luax_build.native "$builddir/bin/bang" { bang_sources },
}

install "lib/luax" {
    libluax_luax_sources,
    loaders,
}

install "lib" {
    "lib/libluax.lua",
}
