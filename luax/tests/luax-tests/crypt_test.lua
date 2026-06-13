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
local sh = require "sh"
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
        for i = 0, 32 do
            local s = ("a"):rep(i)
            eq(#s, i)
            eq(s:base64():unbase64(), s)
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
            eq(s:arc4(""):bytes(), {135,151,174,56,231,102,98})
            eq(s:arc4("key"):bytes(), {217,183,168,237,133,97,233})
            -- Test vectors: https://en.wikipedia.org/wiki/RC4
            eq(crypt.arc4("Plaintext", "Key", 0):hex(), "bbf316e8d940af0ad3")
            eq(crypt.arc4("pedia", "Wiki", 0):hex(), "1021bf0420")
            eq(crypt.arc4("Attack at dawn", "Secret", 0):hex(), "45a01f645fc35b383552544b9bf5")
        end
        do -- hash
            eq(crypt.hash "", "cbf29ce484222325")
            eq(crypt.hash "abc", "e71fa2190541574b")
            eq(crypt.hash "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "dd305304cdb45735")
            eq(crypt.hash "a", "af63dc4c8601ec8c")
            eq(crypt.hash "aa", "089c4307b54596b7")
            eq(crypt.hash "ab", "089c4407b545986a")
            eq(crypt.hash "0123456701234567012345670123456701234567012345670123456701234567", "e1d6f6d59e0eb9e5")
            ne(crypt.hash "aa", crypt.hash "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash(), crypt.hash(s))
                eq(s:hash(), crypt.hash64(s))
            end
        end
        do -- hash32
            eq(crypt.hash32 "", "811c9dc5")
            eq(crypt.hash32 "abc", "1a47e90b")
            eq(crypt.hash32 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "ccdc1355")
            eq(crypt.hash32 "a", "e40c292c")
            eq(crypt.hash32 "b", "e70c2de5")
            eq(crypt.hash32 "aa", "4c250437")
            eq(crypt.hash32 "ab", "4d2505ca")
            eq(crypt.hash32 "0123456701234567012345670123456701234567012345670123456701234567", "5f764485")
            ne(crypt.hash32 "aa", crypt.hash32 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash32(), crypt.hash32(s))
            end
        end
        do -- hash64
            eq(crypt.hash64 "", "cbf29ce484222325")
            eq(crypt.hash64 "abc", "e71fa2190541574b")
            eq(crypt.hash64 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "dd305304cdb45735")
            eq(crypt.hash64 "a", "af63dc4c8601ec8c")
            eq(crypt.hash64 "b", "af63df4c8601f1a5")
            eq(crypt.hash64 "aa", "089c4307b54596b7")
            eq(crypt.hash64 "ab", "089c4407b545986a")
            eq(crypt.hash64 "0123456701234567012345670123456701234567012345670123456701234567", "e1d6f6d59e0eb9e5")
            ne(crypt.hash64 "aa", crypt.hash64 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash64(), crypt.hash64(s))
                eq(s:hash64(), crypt.hash(s))
            end
        end
        do -- hash128
            eq(crypt.hash128 "", "6c62272e07bb014262b821756295c58d")
            eq(crypt.hash128 "abc", "a68d622cec8b5822836dbc7977af7f3b")
            eq(crypt.hash128 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "f5c024b7317b79ef9345d4c902f1374d")
            eq(crypt.hash128 "a", "d228cb696f1a8caf78912b704e4a8964")
            eq(crypt.hash128 "b", "d228cb69721a8caf78912b704e4a8d15")
            eq(crypt.hash128 "aa", "08809544baab1be95aa0733055b69927")
            eq(crypt.hash128 "ab", "08809544bbab1be95aa0733055b69a62")
            eq(crypt.hash128 "0123456701234567012345670123456701234567012345670123456701234567", "4f07331af3eeacf0910def6b29b3244d")
            ne(crypt.hash128 "aa", crypt.hash128 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash128(), crypt.hash128(s))
            end
        end
        do -- hash256
            eq(crypt.hash256 "", "dd268dbcaac550362d98c384c4e576ccc8b1536847b6bbb31023b4c8caee0535")
            eq(crypt.hash256 "abc", "8b0e658c2f1c837f90d6c7e359de3a1784bd1d30340f770be97fd65817736f4b")
            eq(crypt.hash256 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "bd1b47ebe69eaab770884780f61c4ea093b03985e327352b2270a0f2da860e45")
            eq(crypt.hash256 "a", "63323fb0f35303ec28dc751d0a33bdfa4de6a99b7266494f6183b2716811637c")
            eq(crypt.hash256 "b", "63323fb0f35303ec28dc781d0a33bdfa4de6a99b7266494f6183b271681167a5")
            eq(crypt.hash256 "aa", "f4f7a1c2efd0e1e4bb19844525c0721a06dd328fa3d7a91439a07343501c7137")
            eq(crypt.hash256 "ab", "f4f7a1c2efd0e1e4bb19854525c0721a06dd328fa3d7a91439a07343501c729a")
            eq(crypt.hash256 "0123456701234567012345670123456701234567012345670123456701234567", "45f3510f27bf9b8054e4c36d4f1ae85cb0df5106d8b7baa0b372d1ea769fd3f5")
            ne(crypt.hash256 "aa", crypt.hash256 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash256(), crypt.hash256(s))
            end
        end
        do -- hash512
            eq(crypt.hash512 "", "b86db0b1171f4416dca1e50f309990acac87d059c90000000000000000000d21e948f68a34c192f62ea79bc942dbe7ce182036415f56e34bac982aac4afe9fd9")
            eq(crypt.hash512 "abc", "142433ed48a78bb429a7dba8911e8824dcd76c02620000000000001f96475fbd69323ab91bbf83bd3e36fbfd7d0c038b1075dbff4f7a2150e9f28b6e798100d3")
            eq(crypt.hash512 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "5920cc681ca3f472960da0332e3b77e3efc627be20b86f2f30e94fa757ce7e98e76360a2bc40d54e0dfc8e5e2f75d0d7e5e9be6613aeddae87929de4095942e1")
            eq(crypt.hash512 "a", "e43a992dc8fc5ad7de493e3d696d6f85d64326ec07000000000000000011986f90c2532caf5be7d88291baa894a395225328b196bd6a8a643fe12cd87b27ff88")
            eq(crypt.hash512 "b", "e43a992dc8fc5ad7de493e3d696d6f85d64326ec0a000000000000000011986f90c2532caf5be7d88291baa894a395225328b196bd6a8a643fe12cd87b28038d")
            eq(crypt.hash512 "aa", "7317dfed6c70dfec6adfced2a5e04d7eec744e3d4a0000000000000017933d7af45d70def423a316f14117df272cd0fd6b85f0f7c9bf6c5196b3160d0297e12f")
            eq(crypt.hash512 "ab", "7317dfed6c70dfec6adfced2a5e04d7eec744e3d4b0000000000000017933d7af45d70def423a316f14117df272cd0fd6b85f0f7c9bf6c5196b3160d0297e286")
            eq(crypt.hash512 "0123456701234567012345670123456701234567012345670123456701234567", "b49ed8d7e81978153823c3b1a887a60469bc4770674aff694d4dfb67d6265596adcb9fef4ccc9b6229c79dd7ff5fa58fe5b310d11e44de050fdba0a1f7b28359")
            ne(crypt.hash512 "aa", crypt.hash512 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash512(), crypt.hash512(s))
            end
        end
        do -- hash1024
            eq(crypt.hash1024 "", "0000000000000000005f7a76758ecc4d32e56d5a591028b74b29fc4223fdada16c3bf34eda3674da9a21d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004c6d7eb6e73802734510a555f256cc005ae556bde8cc9c6a93b21aff4b16c71ee90b3")
            eq(crypt.hash1024 "abc", "000000000001868ce88bd2c7cdc5fa5e52ebb9925ff5ea668dff4576aa4ba65819176ce6b925a8420606e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011d09af071cf00b53007a8e594c73348a3dbb339aead4953fdf93cfff54816f5e2d1e29c8f4f")
            eq(crypt.hash1024 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "b0e298313b4960e749b6acf1b7e208121b0e35176e2bc6be38e7d389939a8f0aab4ee1b69563e8b87ac55a9689c0c7716bef5da79f19b988dccfc1da9d3e9698cafdb8a88ed1d256dd8fb5d04a7233ea2a2b12e7798dce622dd2e446a767a9115d86d4a313bd3a71e5a6f70a76ba91a413b52c556371109946ef01596dfcde3f")
            eq(crypt.hash1024 "a", "000000000000000098d7c19fbce653df221b9f717d3490ff95ca87fdaef30d1b823372f85b24a372f50e570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007685cd81a491dbccc21ad06648d09a5c8cf5a78482054e91470b33dde77252caef695aa")
            eq(crypt.hash1024 "b", "000000000000000098d7c19fbce653df221b9f717d3490ff95ca87fdaef30d1b823372f85b24a372f50e560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007685cd81a491dbccc21ad06648d09a5c8cf5a78482054e91470b33dde77252caef6941d")
            eq(crypt.hash1024 "aa", "00000000000000f46ef41cd23a4dcdd406834963b78e82241a6f5cb06f403cbd5a7c8903cef6a5f4fdd2b60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b7cd7fb20c3631dc8903952e9eeb7f618698f4c87da23ad74b2c5f6f1fec4a64b54664bcf")
            eq(crypt.hash1024 "ab", "00000000000000f46ef41cd23a4dcdd406834963b78e82241a6f5cb06f403cbd5a7c8903cef6a5f4fdd2b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b7cd7fb20c3631dc8903952e9eeb7f618698f4c87da23ad74b2c5f6f1fec4a64b54664728")
            eq(crypt.hash1024 "0123456701234567012345670123456701234567012345670123456701234567", "c252f134b42b146418f459d16337d15495dbe59430d2c65a72258656cda4594f3e49657e0e0eee77bf9f725fdbc74ae153999d99ab5aef625b22f8e7934569583d4526289e38535bad6f60c21559b88060c94d14b6c2888a348b515588d9f19a1f178ff7d9294e26804bbf1eb3a5140a06faa638761f13b29369d2d607b424f3")
            ne(crypt.hash1024 "aa", crypt.hash1024 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash1024(), crypt.hash1024(s))
            end
        end
        do -- sha1
            eq(crypt.sha1 "", "da39a3ee5e6b4b0d3255bfef95601890afd80709")
            eq(crypt.sha1 "abc", "a9993e364706816aba3e25717850c26c9cd0d89d")
            eq(crypt.sha1 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
            eq(crypt.sha1 "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "a49b2446a02c645bf419f995b67091253a04a259")
            eq(crypt.sha1 "The quick brown fox jumps over the lazy dog", "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
            for i = 0, N do
                local s = crypt.str(i)
                eq(s:sha1(), crypt.sha1(s))
                eq(s:sha1(), sh.pipe("sha1sum")(s):words():head())
            end
        end
        do -- sha256
            eq(crypt.sha256 "", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
            eq(crypt.sha256 "abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
            eq(crypt.sha256 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
            eq(crypt.sha256 "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")
            eq(crypt.sha256 "The quick brown fox jumps over the lazy dog", "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
            for i = 0, N do
                local s = crypt.str(i)
                eq(s:sha256(), crypt.sha256(s))
                eq(s:sha256(), sh.pipe("sha256sum")(s):words():head())
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
        for n = 0, 20 do
            eq(#crypt.str(n), n)
        end
        for n = -20, 0 do
            eq(#crypt.str(n), 0)
        end
        bounded(#random_values:keys(), 3*N-1, 3*N) -- mostly all generated values must be different
        for _ = 1, N do
            bounded(prng:int(), 0, crypt.RAND_MAX)
            bounded(prng:int(15), 1, 15)
            bounded(prng:int(5, 15), 5, 15)
            bounded(prng:int(-15, -5), -15, -5)
            bounded(prng:int(-15, 5), -15, 5)
            bounded(prng:float(), 0.0, 1.0)
            bounded(prng:float(3.5), 0.0, 3.5)
            bounded(prng:float(2.5, 3.5), 2.5, 3.5)
            bounded(prng:float(-3.5, -2.5), -3.5, -2.5)
            bounded(prng:float(-3.5, 2.5), -3.5, 2.5)
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
            bounded(r1:int(15), 1, 15)
            bounded(r1:int(5, 15), 5, 15)
            bounded(r1:float(), 0.0, 1.0)
            bounded(r1:float(3.5), 0.0, 3.5)
            bounded(r1:float(2.5, 3.5), 2.5, 3.5)
        end
        do
            local r = crypt.prng(1337, 7)
            local function gen(a, b)
                return F.range(100)
                    : map(function() return r:int(a, b) end)
                    : nub()
                    : sort()
            end
            eq(gen(15)   , F.range(1, 15))
            eq(gen(1, 15), F.range(1, 15))
            eq(gen(0, 15), F.range(0, 15))
            eq(gen(-5, 0), F.range(-5, 0))
            eq(gen(-5, 5), F.range(-5, 5))
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
        eq(crypt.hash "Hello World!", "8c0ec8d1fb9e6e32")
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
            for i = -20, 0 do
                eq(#s:str(i), 0)
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
