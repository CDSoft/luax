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


local F = require "F"
local fs = require "fs"
local cbor = require "cbor"
local crypt = require "crypt"
local version = require "luax-version"

local salt = tostring(version)

local args = (function()
    local parser = require "argparse"() : name "packlib"
    parser : argument "files" : description "Input files" : args "+"
    parser : option "-o" : description "Output file" : count "1"
    return parser:parse(arg)
end)()

local lib = {
    lua = {},
    ext = {},
    loader = {},
}

for _, file in ipairs(args.files) do

    local name = file:basename()
    local content = assert(fs.read_bin(file))

    if name:ext() == ".lua" and file:match "/ext/" then lib.ext[file] = content
    elseif name:ext() == ".lua"                    then lib.lua[file] = content
    elseif name:has_prefix "luax-loader-"          then lib.loader[name] = content
    else error(file..": can not be added to "..args.o)
    end

end

local data = cbor.encode(lib, {pairs=F.pairs})

assert(fs.write_bin(args.o, data, crypt.hash64(salt..data):unhex()))
