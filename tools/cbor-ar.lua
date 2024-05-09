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
http://cdelord.fr/luax
--]]

-- Archive a directory to a CBOR file

local F = require "F"
local cbor = require "cbor"
local fs = require "fs"

local function parse_args(args)
    local parser = require "argparse"()
        : name "cbor-ar"
    parser : argument "directory"
        : description "Directory to archive"
        : args "1"
        : target "directory"
    parser : option "-o"
        : description "Output file"
        : argname "output"
        : target "output"
    return parser:parse(args)
end

local args = parse_args(arg)

local files = fs.ls(args.directory/"**")
: filter(fs.is_file)
: map(function(name)
    local content = assert(fs.read_bin(name))
    return {name:basename(), content}
end)
: from_list()

local archive = cbor.encode(files, {pairs=F.pairs}) : lz4()

if args.output then
    fs.write_bin(args.output, archive)
end
