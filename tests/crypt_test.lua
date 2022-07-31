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
        local y = crypt.hex.encode(x)
        eq(y, "666f6f")
        eq(crypt.hex.decode(y), x)
    end
    do
        local x = "foo"
        local y = crypt.base64.encode(x)
        eq(y, "Zm9v")
        eq(crypt.base64.decode(y), x)
    end
    do
        local x = "foo123456789\n"
        local y = crypt.crc32(x)
        eq(y, 0x3b13cda7)
    end
    do
        local x = "foobar!"
        local aes1 = crypt.AES("password", 128)
        local aes2 = crypt.AES("password", 128)
        local y1 = aes1.encrypt(x)
        local y2 = aes2.encrypt(x)
        local z1 = aes1.decrypt(y1)
        local z2 = aes2.decrypt(y2)
        ne(y1, x)
        ne(y2, x)
        ne(y1, y2)
        eq(z1, x)
        eq(z2, x)
    end
    do
        local x = "foobar!"
        local btea_1 = crypt.BTEA("password")
        local btea_2 = crypt.BTEA("password")
        local y = btea_1.encrypt(x)
        local z = btea_2.decrypt(y)
        ne(y, x)
        eq(z:sub(1, #x), x)
    end
    do
        local x = "foobar!"
        local rc4_1 = crypt.RC4("password", 4)
        local rc4_2 = crypt.RC4("password", 4)
        local y = rc4_1(x)
        local z = rc4_2(y)
        ne(y, x)
        eq(z, x)
    end
    do
        for _ = 1, 1000 do ne(crypt.random(16), crypt.random(16)) end
    end
end
