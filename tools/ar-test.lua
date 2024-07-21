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

-- Test archive files

local F = require "F"
local fs = require "fs"
local lar = require "lar"
local serpent = require "serpent"

local args = (function()
    local parser = require "argparse"() : name "ar-test.lua"
    parser : argument "archive" : description "Archive to test" : args "1" : target "input"
    parser : option "-k" : description "Encryption key" : argname "key" : target "key"
    return parser:parse(arg)
end)()

local opt = {
    key = args.key,
}

local content = assert(fs.read_bin(args.input))

local function fmt(x)
    if type(x) == "table" then
        return F.mapt(fmt, x)
    end
    if type(x) == "string" then
        local lines = x:lines()
        local first_line = lines:head()
        if #lines>1 or #first_line>64 then
            first_line = first_line:take(64).."…"
        end
        return first_line
    end
    return x
end
local t = fmt(assert(lar.unlar(content, opt)))
print(serpent.line(t, {comment=false, sortkeys=true, indent="    "}))
