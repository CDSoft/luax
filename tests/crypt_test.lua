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
    local prng = crypt.prng()
    do
        local x = "foobarbaz"
        local y = crypt.hex(x)
        local z = x:hex()
        eq(y, "666f6f62617262617a")
        eq(y, z)
        eq(crypt.unhex(y), x)
        eq(z:unhex(), x)
        for _ = 1, 1000 do
            local s = prng:str(256)
            eq(s:hex():unhex(), s)
        end
    end
    do
        do
            local x = "foobarbaz"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        do
            local x = "foobarbaz1"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6MQ==")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        do
            local x = "foobarbaz12"
            local y = crypt.base64(x)
            local z = x:base64()
            eq(y, "Zm9vYmFyYmF6MTI=")
            eq(y, z)
            eq(crypt.unbase64(y), x)
            eq(z:unbase64(), x)
        end
        eq((""):base64():unbase64(), "")
        for i = 0, 255 do
            eq(string.char(i):base64():unbase64(), string.char(i))
        end
        for i = 1, 1000 do
            local s = prng:str(256 + i%3)
            eq(s:base64():unbase64(), s)
            eq(s:base64url():unbase64url(), s)
            eq(s:base64url(), s:base64():gsub("+", "-"):gsub("/", "_"))
        end
    end
    do
        local x = "foo123456789"
        local y = crypt.crc32(x)
        local z = x:crc32()
        eq(y, 0x72871f0c)
        eq(y, z)
    end
    do
        local x = "foo123456789"
        local y = crypt.crc64(x)
        local z = x:crc64()
        eq(y, 0xd85c06f88a2a27d8)
        eq(y, z)
    end
    do
        do
            local x = "foobar!"
            local key = "rc4key"
            local y = crypt.rc4(x, key)
            local z = crypt.unrc4(y, key)
            ne(y, x)
            eq(z, x)
            eq(crypt.rc4(x, key), x:rc4(key))
            eq(crypt.unrc4(y, key), y:unrc4(key))
            eq(x:rc4(key):unrc4(key), x)
            for _ = 1, 1000 do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:rc4(k):unrc4(k), s)
            end
        end
        for drop = 0, 10 do
            local x = "foobar!"
            local key = "rc4key"
            local y = crypt.rc4(x, key, drop)
            local z = crypt.unrc4(y, key, drop)
            ne(y, x)
            eq(z, x)
            eq(crypt.rc4(x, key, drop), x:rc4(key, drop))
            eq(crypt.unrc4(y, key, drop), y:unrc4(key, drop))
            eq(x:rc4(key, drop):unrc4(key, drop), x)
            for _ = 1, 1000 do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:rc4(k, drop):unrc4(k, drop), s)
            end
        end
        do
            for _ = 1, 1000 do
                local s = prng:str(256)
                local k = prng:str(256)
                local drop = prng:int() % 4096
                eq(s:rc4(k, drop):unrc4(k, drop), s)
            end
        end
        do
            eq(crypt.sha1 "abc", "a9993e364706816aba3e25717850c26c9cd0d89d")
            eq(crypt.sha1 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
            eq(crypt.sha1 "a", "86f7e437faa5a7fce15d1ddcb9eaeaea377667b8")
            eq(crypt.sha1 "0123456701234567012345670123456701234567012345670123456701234567", "e0c094e867ef46c350ef54a7f59dd60bed92ae83")
            ne(crypt.sha1 "aa", crypt.sha1 "ab")
            for _ = 1, sys.abi=="lua" and 10 or 1000 do
                local s = crypt.str(crypt.int()%1024)
                eq(s:sha1(), crypt.sha1(s))
            end
        end
        do
            eq(crypt.hash "abc", "cb4c8381f780cbd2")
            eq(crypt.hash "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "ccf85c25fd40b59f")
            eq(crypt.hash "a", "c7e49f6a0a944b08")
            eq(crypt.hash "0123456701234567012345670123456701234567012345670123456701234567", "d97bdf31cf8cda13")
            ne(crypt.hash "aa", crypt.hash "ab")
            for _ = 1, sys.abi=="lua" and 10 or 1000 do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash(), crypt.hash(s))
            end
        end
    end
    do
        local str = {}
        local i = 0
        local done = false
        while not done and i < 10000 do
            i = i+1
            local x = prng:int(0, 100)                        eq(type(x), "number") eq(math.type(x), "integer")
            bounded(x, 0, 100)
            str[x] = true
            done = true
            for y = 0, 100 do done = done and str[y] end
        end
        eq(done, true)
        bounded(i, 100, 2000)
        for _ = 1, 1000 do
            local x = prng:int()                              eq(type(x), "number") eq(math.type(x), "integer")
            local y = prng:int()                              eq(type(y), "number") eq(math.type(y), "integer")
            bounded(x, 0, crypt.RAND_MAX)
            bounded(y, 0, crypt.RAND_MAX)
            ne(x, y)
        end
        for _ = 1, 1000 do
            local x = prng:float()                             eq(type(x), "number") eq(math.type(x), "float")
            local y = prng:float()                             eq(type(y), "number") eq(math.type(y), "float")
            bounded(x, 0.0, 1.0)
            bounded(y, 0.0, 1.0)
            ne(x, y)
        end
        for _ = 1, 1000 do
            local x = prng:str(16)                           eq(type(x), "string")
            local y = prng:str(16)                           eq(type(y), "string")
            eq(#x, 16)
            eq(#y, 16)
            ne(x, y)
        end
        for _ = 1, 1000 do
            bounded(prng:int(), 0, crypt.RAND_MAX)
            bounded(prng:int(15), 0, 15)
            bounded(prng:int(5, 15), 5, 15)
            bounded(prng:float(), 0.0, 1.0)
            bounded(prng:float(3.5), 0.0, 3.5)
            bounded(prng:float(2.5, 3.5), 2.5, 3.5)
        end
    end
    do
        local r1 = crypt.prng(42)
        local r2 = crypt.prng(42)
        local r3 = crypt.prng(43)
        for _ = 1, 1000 do
            local x1 = r1:int()                                eq(type(x1), "number") eq(math.type(x1), "integer")
            local x2 = r2:int()                                eq(type(x2), "number") eq(math.type(x2), "integer")
            local x3 = r3:int()                                eq(type(x2), "number") eq(math.type(x3), "integer")
            eq(x1, x2)
            ne(x1, x3)
            local s1 = r1:str(32)                             eq(type(s1), "string") eq(#s1, 32)
            local s2 = r2:str(32)                             eq(type(s2), "string") eq(#s2, 32)
            local s3 = r3:str(32)                             eq(type(s3), "string") eq(#s3, 32)
            eq(s1, s2)
            ne(s1, s3)
            local f1 = r1:float()                               eq(type(f1), "number") eq(math.type(f1), "float")
            local f2 = r2:float()                               eq(type(f2), "number") eq(math.type(f2), "float")
            local f3 = r3:float()                               eq(type(f3), "number") eq(math.type(f3), "float")
            eq(f1, f2)
            ne(f1, f3)
        end
        for _ = 1, 1000 do
            bounded(r1:int(), 0, crypt.RAND_MAX)
            bounded(r1:int(15), 0, 15)
            bounded(r1:int(5, 15), 5, 15)
            bounded(r1:float(), 0.0, 1.0)
            bounded(r1:float(3.5), 0.0, 3.5)
            bounded(r1:float(2.5, 3.5), 2.5, 3.5)
        end
    end
    do
        -- compare C and Lua prng implemenrations
        local r = crypt.prng(1337, 12)
        local xs = F.range(16):map(function(_) return r:int() end)
        eq(xs, {
            1306753901, 4044912387, 1648085481, 2633988900, 4079560644, 3769468295, 3245996943, 1721887037,
            3063376457, 2280948516, 2012680803, 3957139778, 3740370758, 2086760861, 3024349504, 434537368,
        })
        eq(crypt.hash "Hello World!", "b2e381f8a79a747b")
        do
            -- test setting the seed after initialization
            local r1 = crypt.prng(666)
            local r2 = crypt.prng()
            F.range(100):map(function(_) ne(r1:int(), r2:int()) end)
            r1 = crypt.prng(666)
            r2:seed(666)
            F.range(100):map(function(_) eq(r1:int(), r2:int()) end)
        end
        do
            -- test setting the seed and inc after initialization
            local r1 = crypt.prng(666, 42)
            local r2 = crypt.prng(666)
            F.range(100):map(function(_) ne(r1:int(), r2:int()) end)
            r1 = crypt.prng(666, 42)
            r2:seed(666, 42)
            F.range(100):map(function(_) eq(r1:int(), r2:int()) end)
        end
    end

end
