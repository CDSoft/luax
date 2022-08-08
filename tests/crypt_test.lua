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
        local x = "foobarbaz"
        local y = crypt.hex_encode(x)
        eq(y, "666f6f62617262617a")
        eq(crypt.hex_decode(y), x)
    end
    do
        do
            local x = "foobarbaz"
            local y = crypt.base64_encode(x)
            eq(y, "Zm9vYmFyYmF6")
            eq(crypt.base64_decode(y), x)
        end
        do
            local x = "foobarbaz1"
            local y = crypt.base64_encode(x)
            eq(y, "Zm9vYmFyYmF6MQ==")
            eq(crypt.base64_decode(y), x)
        end
        do
            local x = "foobarbaz12"
            local y = crypt.base64_encode(x)
            eq(y, "Zm9vYmFyYmF6MTI=")
            eq(crypt.base64_decode(y), x)
        end
    end
    do
        local x = "foo123456789"
        local y = crypt.crc32(x)
        eq(y, 0x72871f0c)
    end
    do
        local x = "foo123456789"
        local y = crypt.crc64(x)
        eq(y, 0xd85c06f88a2a27d8)
    end
    do
        local x = "foobar!"
        local key = "rc4key"
        local y = crypt.rc4(key, x)
        local z = crypt.rc4(key, y)
        ne(y, x)
        eq(z, x)
    end
    do
        local rands = {}
        local i = 0
        local done = false
        while not done and i < 10000 do
            i = i+1
            local x = crypt.rand() % 100
            bounded(x, 0, 100)
            rands[x] = true
            done = true
            for y = 0, 99 do done = done and rands[y] end
        end
        eq(done, true)
        bounded(i, 100, 1000)
        for _ = 1, 1000 do
            local x = crypt.rand()
            local y = crypt.rand()
            bounded(x, 0, crypt.RAND_MAX)
            bounded(y, 0, crypt.RAND_MAX)
            ne(x, y)
        end
        for _ = 1, 1000 do
            local x = crypt.frand()
            local y = crypt.frand()
            bounded(x, 0.0, 1.0)
            bounded(y, 0.0, 1.0)
            ne(x, y)
        end
        for _ = 1, 1000 do
            local x = crypt.rand(16)
            local y = crypt.rand(16)
            eq(#x, 16)
            eq(#y, 16)
            ne(x, y)
        end
    end
    do
        local r1 = crypt.prng(42)
        local r2 = crypt.prng(42)
        local r3 = crypt.prng(43)
        for _ = 1, 1000 do
            local x1 = r1:rand()
            local x2 = r2:rand()
            local x3 = r3:rand()
            eq(x1, x2)
            ne(x1, x3)
            local s1 = r1:rand(32)
            local s2 = r2:rand(32)
            local s3 = r3:rand(32)
            eq(s1, s2)
            ne(s1, s3)
            local f1 = r1:rand()
            local f2 = r2:rand()
            local f3 = r3:rand()
            eq(f1, f2)
            ne(f1, f3)
        end
    end
end
