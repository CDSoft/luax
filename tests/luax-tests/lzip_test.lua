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

---------------------------------------------------------------------
-- lzip
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq
local ne = test.ne

local fs = require "fs"
local lzip = require "lzip"
local crypt = require "crypt"

return function()
    do
        for i = 1, 5 do
            local s = ("a"):rep((1<<i)*1024)
            local z = lzip.lzip(s)
            assert(#z < #s/40)
            ne(z, s)
            eq(z, s:lzip())
            local t = lzip.unlzip(z)
            eq(t, s)
            eq(z:unlzip(), t)
        end
    end
    do
        local rng = crypt.prng(42)
        for i = 1, 5 do
            local s = rng:str((1<<i)*1024)
            local z = lzip.lzip(s)
            assert(#z > #s) -- uncompressible random data
            ne(z, s)
            eq(z, s:lzip())
            local t = lzip.unlzip(z)
            eq(t, s)
            eq(z:unlzip(), t)
        end
    end
    do
        local s = assert(fs.read_bin("tools/bang.luax"))
        local level_min     = s:lzip(0)        eq(level_min:unlzip(), s)
        local level_default = s:lzip(6)        eq(level_default:unlzip(), s)
        local level_max     = s:lzip(9)        eq(level_max:unlzip(), s)
        assert(#level_min > #level_default)
        assert(#level_default > #level_max)
        eq(level_default, s:lzip())
    end
end
