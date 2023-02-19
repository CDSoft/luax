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
-- lz4
---------------------------------------------------------------------

if sys.abi == "lua" then return function() end end

local lz4 = require "lz4"

local crypt = require "crypt"

require "test"

return function()
    do
        for i = 1, 256 do
            local s = ("a"):rep(i*1024)
            local z = lz4.lz4(s)
            assert(#z < #s/20)
            ne(z, s)
            eq(z, s:lz4())
            local t = lz4.unlz4(z)
            eq(t, s)
            eq(z:unlz4(), t)
        end
    end
    do
        for i = 1, 256 do
            local s = crypt.str(i*1024)
            local z = lz4.lz4(s)
            assert(#z > #s) -- uncompressible random data
            ne(z, s)
            eq(z, s:lz4())
            local t = lz4.unlz4(z)
            eq(t, s)
            eq(z:unlz4(), t)
        end
    end
end
