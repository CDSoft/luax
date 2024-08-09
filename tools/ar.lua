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

-- Archive files to a CBOR/LZ4/Lzip file

local F = require "F"
local fs = require "fs"
local lar = require "lar"

local args = (function()
    local parser = require "argparse"() : name "ar.lua"
    parser : argument "inputs" : description "Files to archive" : args "*" : target "inputs"
    parser : option "-o" : description "Output file" : argname "output" : target "output"
    parser : option "-z" : description "Compression algorithm" : argname "algo" : target "compress"
    parser : option "-k" : description "Encryption key" : argname "key" : target "key"
    return parser:parse(arg)
end)()

local opt = {
    compress = args.compress or "lzip",
    key = args.key,
}

local files = F(args.inputs)
: map(function(name)
    local content = assert(fs.read_bin(name))
    if name:ext() == ".lar" then
        -- extract the input lar file and store it as a field of the final lar file
        return {name:basename():splitext(), assert(lar.unlar(content, opt))}
    else
        return {name:basename(), content}
    end
end)
: from_list()

if args.output then
    fs.write_bin(args.output, lar.lar(files, opt))
end
