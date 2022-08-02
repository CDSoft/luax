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
-- crypt
---------------------------------------------------------------------

local crypt = require "crypt"

require "test"

return function()
    do
        local x = "foo"
        local y = crypt.hex_encode(x)
        eq(y, "666f6f")
        eq(crypt.hex_decode(y), x)
    end
    do
        local x = "foo"
        local y = crypt.base64_encode(x)
        eq(y, "Zm9v")
        eq(crypt.base64_decode(y), x)
    end
    do
        local x = "foo123456789\n"
        local y = crypt.crc32(x)
        eq(y, 0x3b13cda7)
    end
    do
        local x = "foobar!"
        local key = 1337
        local y = crypt.rand_encode(key, x)
        local z = crypt.rand_decode(key, y)
        ne(y, x)
        eq(z, x)
    end
    do
        for _ = 1, 1000 do ne(crypt.rand(16), crypt.rand(16)) end
    end
end
