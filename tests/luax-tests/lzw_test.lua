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

---------------------------------------------------------------------
-- lzw
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq
local ne = test.ne

local lzw = require "lzw"

local crypt = require "crypt"

return function()
    do
        for i = 1, 32 do
            local s = ("a"):rep(i*1024)
            local z = lzw.lzw(s)
            assert(#z < #s/10)
            ne(z, s)
            eq(z, s:lzw())
            local t = lzw.unlzw(z)
            eq(t, s)
            eq(z:unlzw(), t)
        end
    end
    do
        local rng = crypt.prng(42)
        for i = 1, 32 do
            local s = rng:str(i*1024)
            local z = lzw.lzw(s)
            assert(#z > #s) -- uncompressible random data
            ne(z, s)
            eq(z, s:lzw())
            local t = lzw.unlzw(z)
            eq(t, s)
            eq(z:unlzw(), t)
        end
    end
end
