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

--@LIB

-- Pure Lua implementation of lz4.lua

local lz4 = {}

local fs = require "fs"
local sh = require "sh"

function lz4.lz4(s, level)
    return fs.with_tmpfile(function(tmp)
        local n = #s
        assert(sh.write(
            "lz4 -q -z",
               n <=   64*1024 and "-B4"
            or n <=  256*1024 and "-B5"
            or n <= 1024*1024 and "-B6"
            or                    "-B7",
            "-"..(level or 9),
            "-BD --frame-crc -f -", tmp)(s))
        return assert(fs.read_bin(tmp))
    end)
end

function lz4.unlz4(s)
    return fs.with_tmpfile(function(tmp)
        assert(sh.write("lz4 -q -d -f -", tmp)(s))
        return assert(fs.read_bin(tmp))
    end)
end

return lz4
