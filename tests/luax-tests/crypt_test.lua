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
-- crypt
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq
local ne = test.ne
local bounded = test.bounded
local id = test.id

local crypt = require "crypt"

local F = require "F"
local sys = require "sys"

return function()
    local prng = crypt.prng()
    local N = sys.libc == "lua" and 100 or 1000
    do
        local x = "foobarbaz"
        local y = crypt.hex(x)
        local z = x:hex()
        eq(y, "666f6f62617262617a")
        eq(y, z)
        eq(crypt.unhex(y), x)
        eq(z:unhex(), x)
        for _ = 1, N do
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
        for i = 1, N do
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
            local key = "" -- arc4 shall not crash with an empty key
            local y = crypt.arc4(x, key)
            local z = crypt.unarc4(y, key)
            ne(y, x)
            eq(z, x)
        end
        do
            local x = "foobar!"
            local key = "arc4key"
            local y = crypt.arc4(x, key)
            local z = crypt.unarc4(y, key)
            ne(y, x)
            eq(z, x)
            eq(crypt.arc4(x, key), x:arc4(key))
            eq(crypt.unarc4(y, key), y:unarc4(key))
            eq(x:arc4(key):unarc4(key), x)
            for _ = 1, N do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:arc4(k):unarc4(k), s)
            end
        end
        for drop = 0, 10 do
            local x = "foobar!"
            local key = "arc4key"
            local y = crypt.arc4(x, key, drop)
            local z = crypt.unarc4(y, key, drop)
            ne(y, x)
            eq(z, x)
            eq(crypt.arc4(x, key, drop), x:arc4(key, drop))
            eq(crypt.unarc4(y, key, drop), y:unarc4(key, drop))
            eq(x:arc4(key, drop):unarc4(key, drop), x)
            for _ = 1, N do
                local s = prng:str(256)
                local k = prng:str(256)
                eq(s:arc4(k, drop):unarc4(k, drop), s)
            end
        end
        do
            for _ = 1, N do
                local s = prng:str(256)
                local k = prng:str(256)
                local drop = prng:int() % 4096
                eq(s:arc4(k, drop):unarc4(k, drop), s)
            end
        end
        do
            local s = "foobar!"
            ne(s:arc4(""), s:arc4("x"))
        end
        do
            local s = "foobar!"
            -- C and Lua implementations shall implement the same arc4 algorithm
            eq({s:arc4(""):byte(1, -1)}, {135,151,174,56,231,102,98})
            eq({s:arc4("key"):byte(1, -1)}, {217,183,168,237,133,97,233})
        end
        do -- hash
            eq(crypt.hash "", "a210e25fb829f210")
            eq(crypt.hash "abc", "473a5b2cad831f43")
            eq(crypt.hash "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "5abfe14fd7d84a50")
            eq(crypt.hash "a", "af98e34a6fabc2df")
            eq(crypt.hash "aa", "f8f53768bdc10cc1")
            eq(crypt.hash "ab", "9ef70ccf62d96810")
            eq(crypt.hash "0123456701234567012345670123456701234567012345670123456701234567", "22d90ed48e6ee869")
            ne(crypt.hash "aa", crypt.hash "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash(), crypt.hash(s))
                eq(s:hash(), crypt.hash64(s))
            end
        end
        do -- hash64
            eq(crypt.hash64 "", "a210e25fb829f210")
            eq(crypt.hash64 "abc", "473a5b2cad831f43")
            eq(crypt.hash64 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "5abfe14fd7d84a50")
            eq(crypt.hash64 "a", "af98e34a6fabc2df")
            eq(crypt.hash64 "b", "559ab8b114c31e2f")
            eq(crypt.hash64 "aa", "f8f53768bdc10cc1")
            eq(crypt.hash64 "ab", "9ef70ccf62d96810")
            eq(crypt.hash64 "0123456701234567012345670123456701234567012345670123456701234567", "22d90ed48e6ee869")
            ne(crypt.hash64 "aa", crypt.hash64 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash64(), crypt.hash64(s))
                eq(s:hash64(), crypt.hash(s))
            end
        end
        do -- hash128
            eq(crypt.hash128 "", "f281c81645637f3aba58f55c85723744")
            eq(crypt.hash128 "abc", "318597ea5617d4c7fdde016eeac7c86c")
            eq(crypt.hash128 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "5a532e4fa91f1755c2324897fb8bd8b3")
            eq(crypt.hash128 "a", "3bdf1c349379c91bc7e0f6473cf40713")
            eq(crypt.hash128 "b", "6983fd304f480a4b6de2cbaee10b6462")
            eq(crypt.hash128 "aa", "a6a1125e9bcd94049622e47f0d51071c")
            eq(crypt.hash128 "ab", "00a03df7f5b538b5687e03835182c6ec")
            eq(crypt.hash128 "0123456701234567012345670123456701234567012345670123456701234567", "323dd52aeee45f65faaffde7e729297b")
            ne(crypt.hash128 "aa", crypt.hash128 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash128(), crypt.hash128(s))
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
        local random_values = F{}
        for _ = 1, N do
            local x = prng:int()                              eq(type(x), "number") eq(math.type(x), "integer")
            bounded(x, 0, crypt.RAND_MAX)
            random_values[x] = true
        end
        for _ = 1, N do
            local x = prng:float()                            eq(type(x), "number") eq(math.type(x), "float")
            bounded(x, 0.0, 1.0)
            random_values[x] = true
        end
        for _ = 1, N do
            local x = prng:str(16)                            eq(type(x), "string")
            eq(#x, 16)
            random_values[x] = true
        end
        bounded(#random_values:keys(), 3*N-1, 3*N) -- mostly all generated values must be different
        for _ = 1, N do
            bounded(prng:int(), 0, crypt.RAND_MAX)
            bounded(prng:int(15), 0, 15)
            bounded(prng:int(5, 15), 5, 15)
            bounded(prng:float(), 0.0, 1.0)
            bounded(prng:float(3.5), 0.0, 3.5)
            bounded(prng:float(2.5, 3.5), 2.5, 3.5)
        end
    end
    do
        local r1 = crypt.prng(42, 13)
        local r2 = crypt.prng(42, 13)
        local r3 = crypt.prng(43, 13)
        for _ = 1, N do
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
        for _ = 1, N do
            bounded(r1:int(), 0, crypt.RAND_MAX)
            bounded(r1:int(15), 0, 15)
            bounded(r1:int(5, 15), 5, 15)
            bounded(r1:float(), 0.0, 1.0)
            bounded(r1:float(3.5), 0.0, 3.5)
            bounded(r1:float(2.5, 3.5), 2.5, 3.5)
        end
    end
    do
        -- compare C and Lua prng implementations
        local r = crypt.prng(1337, 1)
        local xs = F.range(16):map(function(_) return r:int() end)
        eq(xs, {
            1366936323, 2922103962, 3074544265, 4240721341, 2529631336, 316793424, 2144597218, 2478277350,
            4254537736, 2560294415, 843227611, 3842418420, 690197939, 2249917264, 3773173077, 3200169535
        })
        eq(crypt.hash "Hello World!", "ec307c5cbcaa6427")
        do
            -- test setting the seed after initialization
            local r1 = crypt.prng(666, 1)
            local r2 = crypt.prng(42, 1)
            F.range(100):foreach(function(_) ne(r1:int(), r2:int()) end)
            r1 = crypt.prng(666, 1)
            r2:seed(666, 1)
            F.range(100):foreach(function(_) eq(r1:int(), r2:int()) end)
        end
        do
            -- test setting the increment after initialization
            local r1 = crypt.prng(666, 1)
            local r2 = crypt.prng(666, 3)
            F.range(100):foreach(function(_) ne(r1:int(), r2:int()) end)
            r1 = crypt.prng(666, 1)
            r2:seed(666, 1)
            F.range(100):foreach(function(_) eq(r1:int(), r2:int()) end)
        end
        do
            local s = crypt.prng(1337, 1)
            eq(s:str(1):hex(), "03")
            eq(s:str(3):hex(), "9ac42b")
            eq(s:str(4):hex(), "89d241b7")
            eq(s:str(5):hex(), "bd45c4fc68")
            eq(s:str(6):hex(), "50e2e112e2f4")
            eq(s:str(7):hex(), "e682b793081897")
            eq(s:str(8):hex(), "0ffe9a98dba14232")
            for i = 0, 20 do
                eq(#s:str(i), i)
            end
        end
    end
    do
        -- test crypt.choose
        local xs = F.range(0, 15):map(function(i) return string.char(i + string.byte"A") end)
        local ys = F{}
        for i = 1, 1000 do
            ys[i] = crypt.choose(xs)
            eq(F.elem(ys[i], xs), true)
        end
        ys = ys:from_set(F.const(true)):keys()
        eq(ys, xs)
    end
    do
        -- test prng:choose
        local xs = F.range(0, 15):map(function(i) return string.char(i + string.byte"A") end)
        local ys = F{}
        for i = 1, 1000 do
            ys[i] = prng:choose(xs)
            eq(F.elem(ys[i], xs), true)
        end
        ys = ys:from_set(F.const(true)):keys()
        eq(ys, xs)
    end
    do
        -- test crypt.shuffle
        local xs = F.range(0, 15):map(function(i) return string.char(i + string.byte"A") end):sort()
        local ys = crypt.shuffle(xs)
        local zs = crypt.shuffle(xs)
        ne(ys, xs)
        ne(zs, xs)
        ne(zs, ys)
        eq(ys:sort(), xs)
        eq(zs:sort(), xs)
    end
    do
        -- test prng:shuffle
        local xs = F.range(0, 15):map(function(i) return string.char(i + string.byte"A") end):sort()
        local ys = prng:shuffle(xs)
        local zs = prng:shuffle(xs)
        ne(ys, xs)
        ne(zs, xs)
        ne(zs, ys)
        eq(ys:sort(), xs)
        eq(zs:sort(), xs)
    end
    do
        -- test prng:clone
        local r1 = crypt.prng()
        local r2 = r1:clone()
        ne(id(r1), id(r2))
        for _ = 1, 1000 do
            eq(r1:int(), r2:int())
            eq(r1:float(), r2:float())
            eq(r1:str(16), r2:str(16))
        end
    end
    do
        -- checks seed returns the prng
        local r = crypt.prng()
        eq(r:seed(), r)
    end
end
