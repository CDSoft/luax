#!/usr/bin/env luax
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
https://github.com/cdsoft/luax
--]]

-- bundle a set of scripts into a single Lua script that can be added to the runtime

local bundle = require "luax_bundle"

local F = require "F"
local fs = require "fs"

local function parse_args(args)
    local parser = require "argparse"()
        : name "bundle"
    parser : argument "script"
        : description "Lua script"
        : args "+"
        : target "scripts"
    parser : option "-o"
        : description "Output file"
        : argname "output"
        : target "output"
    parser : option "-t"
        : description "Target"
        : argname "target"
        : target "target"
        : choices { "lib", "luax", "lua", "pandoc", "c" }
    parser : option "-e"
        : description "Entry type"
        : argname "entry"
        : target "entry"
        : choices { "lib", "app" }
    parser : option "-n"
        : description "Product name"
        : argname "product_name"
        : target "product_name"
    parser : flag "-b"
        : description "Compile scripts to Lua bytecode"
        : target "bytecode"
    parser : flag "-s"
        : description "Strip debug information"
        : target "strip"
    parser : option "-k"
        : description "Encryption key"
        : argname "key"
        : target "key"
    parser : option "-z"
        : description "Compression algorithm"
        : argname "zip"
        : target "compress"
    return F{
        scripts = nil,              -- Lua script list
        output = nil,               -- output file
        target = "luax",            -- lib, lua, luax, c
        entry = "app",              -- lib, app
        bytecode = nil,             -- compile to Lua bytecode
        strip = nil,                -- strip Lua bytecode
        key = nil,                  -- encryption key
        compress = nil,             -- compression algorithm
    } : patch(parser:parse(args))
end

local function main(args)
    bundle.bundle(parse_args(args)) : foreachk(fs.write)
end

main(arg)
