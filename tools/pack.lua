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

local F = require "F"
local fs = require "fs"
local lar = require "lar"

local args = (function ()
    local parser = require "argparse"() : name "pack.lua"
    parser : argument "inputs" : description "Files to archive" : args "*" : target "inputs"
    parser : option "-o" : description "Output file" : argname "output" : target "output"
    parser : option "-z" : description "Compression algorithm" : argname "algo" : target "compress"
    parser : option "-k" : description "Encryption key" : argname "key" : target "key"
    parser : option "-s" : description "Stripped prefix" : argname "prefix" : target "prefix"
    parser : flag "-v" : description "Verbose output" : target "verbose"
    return parser:parse(arg)
end)()

local opt = {
    compress = args.compress or "none",
    key = args.key,
}

local function size(n)
    if n > 8*1024*1024 then return ("%4d Mb"):format(n//(1024*1204)) end
    if n > 8*1024 then return ("%4d Kb"):format(n//1024) end
    return ("%4d b"):format(n)
end

local archive = {}

F.foreach(args.inputs, function(name)
    local content = assert(fs.read_bin(name))
    if args.prefix and name:has_prefix(args.prefix) then name = name:sub(#args.prefix+1) end
    if args.verbose then
        print(("read  %-32s %s"):format(name, size(#content)))
    end
    local path = fs.splitpath(name)
    local dir = archive
    for i = 1, #path-1 do
        if not dir[path[i]] then dir[path[i]] = {} end
        dir = dir[path[i]]
        assert(type(dir) == "table")
    end
    dir[path[#path]] = content
end)

if args.output then
    local content = lar.lar(archive, opt)
    if args.verbose then
        print(("write %-32s %s"):format(args.output, size(#content)))
    end
    fs.write_bin(args.output, content)
end

if args.verbose then
    print(("%s structure:"):format(args.output or "Archive"))
    local tab = "    "
    local function dump(t, indent)
        for k, v in F.pairs(t) do
            if type(v) == "table" then
                print(("%s%s = {"):format(indent, k))
                dump(v, indent..tab)
                print(("%s}"):format(indent))
            else
                print(("%-32s = %s"):format(("%s%s"):format(indent, k), size(#v)))
            end
        end
    end
    dump(archive, tab)
end
