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
            eq(crypt.hash "", "25232284e49cf2cb")
            eq(crypt.hash "abc", "4b57410519a21fe7")
            eq(crypt.hash "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "3557b4cd045330dd")
            eq(crypt.hash "a", "8cec01864cdc63af")
            eq(crypt.hash "aa", "b79645b507439c08")
            eq(crypt.hash "ab", "6a9845b507449c08")
            eq(crypt.hash "0123456701234567012345670123456701234567012345670123456701234567", "e5b90e9ed5f6d6e1")
            ne(crypt.hash "aa", crypt.hash "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash(), crypt.hash(s))
                eq(s:hash(), crypt.hash64(s))
            end
        end
        do -- hash32
            eq(crypt.hash32 "", "c59d1c81")
            eq(crypt.hash32 "abc", "0be9471a")
            eq(crypt.hash32 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "5513dccc")
            eq(crypt.hash32 "a", "2c290ce4")
            eq(crypt.hash32 "b", "e52d0ce7")
            eq(crypt.hash32 "aa", "3704254c")
            eq(crypt.hash32 "ab", "ca05254d")
            eq(crypt.hash32 "0123456701234567012345670123456701234567012345670123456701234567", "8544765f")
            ne(crypt.hash32 "aa", crypt.hash32 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash32(), crypt.hash32(s))
            end
        end
        do -- hash64
            eq(crypt.hash64 "", "25232284e49cf2cb")
            eq(crypt.hash64 "abc", "4b57410519a21fe7")
            eq(crypt.hash64 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "3557b4cd045330dd")
            eq(crypt.hash64 "a", "8cec01864cdc63af")
            eq(crypt.hash64 "b", "a5f101864cdf63af")
            eq(crypt.hash64 "aa", "b79645b507439c08")
            eq(crypt.hash64 "ab", "6a9845b507449c08")
            eq(crypt.hash64 "0123456701234567012345670123456701234567012345670123456701234567", "e5b90e9ed5f6d6e1")
            ne(crypt.hash64 "aa", crypt.hash64 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash64(), crypt.hash64(s))
                eq(s:hash64(), crypt.hash(s))
            end
        end
        do -- hash128
            eq(crypt.hash128 "", "8dc595627521b8624201bb072e27626c")
            eq(crypt.hash128 "abc", "3b7faf7779bc6d8322588bec2c628da6")
            eq(crypt.hash128 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "4d37f102c9d44593ef797b31b724c0f5")
            eq(crypt.hash128 "a", "64894a4e702b9178af8c1a6f69cb28d2")
            eq(crypt.hash128 "b", "158d4a4e702b9178af8c1a7269cb28d2")
            eq(crypt.hash128 "aa", "2799b6553073a05ae91babba44958008")
            eq(crypt.hash128 "ab", "629ab6553073a05ae91babbb44958008")
            eq(crypt.hash128 "0123456701234567012345670123456701234567012345670123456701234567", "4d24b3296bef0d91f0aceef31a33074f")
            ne(crypt.hash128 "aa", crypt.hash128 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash128(), crypt.hash128(s))
            end
        end
        do -- hash256
            eq(crypt.hash256 "", "3505eecac8b42310b3bbb6476853b1c8cc76e5c484c3982d3650c5aabc8d26dd")
            eq(crypt.hash256 "abc", "4b6f731758d67fe90b770f34301dbd84173ade59e3c7d6907f831c2f8c650e8b")
            eq(crypt.hash256 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "450e86daf2a070222b3527e38539b093a04e1cf680478870b7aa9ee6eb471bbd")
            eq(crypt.hash256 "a", "7c63116871b283614f4966729ba9e64dfabd330a1d75dc28ec0353f3b03f3263")
            eq(crypt.hash256 "b", "a567116871b283614f4966729ba9e64dfabd330a1d78dc28ec0353f3b03f3263")
            eq(crypt.hash256 "aa", "37711c504373a03914a9d7a38f32dd061a72c025458419bbe4e1d0efc2a1f7f4")
            eq(crypt.hash256 "ab", "9a721c504373a03914a9d7a38f32dd061a72c025458519bbe4e1d0efc2a1f7f4")
            eq(crypt.hash256 "0123456701234567012345670123456701234567012345670123456701234567", "f5d39f76ead172b3a0bab7d80651dfb05ce81a4f6dc3e454809bbf270f51f345")
            ne(crypt.hash256 "aa", crypt.hash256 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash256(), crypt.hash256(s))
            end
        end
        do -- hash512
            eq(crypt.hash512 "", "d99ffe4aac2a98ac4be3565f41362018cee7db42c99ba72ef692c1348af648e9210d000000000000000000c959d087acac9099300fe5a1dc16441f17b1b06db8")
            eq(crypt.hash512 "abc", "d30081796e8bf2e950217a4fffdb75108b030c7dfdfb363ebd83bf1bb93a3269bd5f47961f00000000000062026cd7dc24881e91a8dba729b48ba748ed332414")
            eq(crypt.hash512 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "e1425909e49d9287aeddae1366bee9e5d7d0752f5e8efc0d4ed540bca26063e7987ece57a74fe9302f6fb820be27c6efe3773b2e33a00d9672f4a31c68cc2059")
            eq(crypt.hash512 "a", "88ff277bd82ce13f648a6abd96b128532295a394a8ba9182d8e75baf2c53c2906f9811000000000000000007ec2643d6856f6d693d3e49ded75afcc82d993ae4")
            eq(crypt.hash512 "b", "8d03287bd82ce13f648a6abd96b128532295a394a8ba9182d8e75baf2c53c2906f981100000000000000000aec2643d6856f6d693d3e49ded75afcc82d993ae4")
            eq(crypt.hash512 "aa", "2fe197020d16b396516cbfc9f7f0856bfdd02c27df1741f116a323f4de705df47a3d9317000000000000004a3d4e74ec7e4de0a5d2cedf6aecdf706ceddf1773")
            eq(crypt.hash512 "ab", "86e297020d16b396516cbfc9f7f0856bfdd02c27df1741f116a323f4de705df47a3d9317000000000000004b3d4e74ec7e4de0a5d2cedf6aecdf706ceddf1773")
            eq(crypt.hash512 "0123456701234567012345670123456701234567012345670123456701234567", "5983b2f7a1a0db0f05de441ed110b3e58fa55fffd79dc729629bcc4cef9fcbad965526d667fb4d4d69ff4a677047bc6904a687a8b1c32338157819e8d7d89eb4")
            ne(crypt.hash512 "aa", crypt.hash512 "ab")
            for _ = 1, N do
                local s = crypt.str(crypt.int()%1024)
                eq(s:hash512(), crypt.hash512(s))
            end
        end
        do -- hash1024
            eq(crypt.hash1024 "", "b390ee716cb1f4af213ba9c6c98cde6b55ae05c06c255f550a51342780736eebd7c6040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d9219ada7436da4ef33b6ca1adfd2342fc294bb72810595a6de5324dcc8e75767a5f000000000000000000")
            eq(crypt.hash1024 "abc", "4f8f9ce2d1e2f51648f5ff3cf9fd5349adae39b3dba34833c794e5a80730b500cf71f09ad0110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e2060642a825b9e66c171958a64baa7645ff8d66eaf55f92b9eb525efac5cdc7d28be88c86010000000000")
            eq(crypt.hash1024 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "3fdefc6d5901ef4699107163552cb513a491ba760af7a6e5713abd13a3d4865d11a967a746e4d22d62ce8d79e7122b2aea33724ad0b58fdd56d2d18ea8b8fdca98963e9ddac1cfdc88b9199fa75def6b71c7c089965ac57ab8e86395b6e14eab0a8f9a9389d3e738bec62b6e17350e1b1208e2b7f1acb649e760493b3198e2b0")
            eq(crypt.hash1024 "a", "aa95f6ae2c2577de3db37014e9542048785acfc8a5098d6406ad21ccbc1d491ad85c680700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000570ef572a3245bf87233821b0df3aefd87ca95ff90347d719f1b22df53e6bc9fc1d7980000000000000000")
            eq(crypt.hash1024 "b", "1d94f6ae2c2577de3db37014e9542048785acfc8a5098d6406ad21ccbc1d491ad85c680700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560ef572a3245bf87233821b0df3aefd87ca95ff90347d719f1b22df53e6bc9fc1d7980000000000000000")
            eq(crypt.hash1024 "aa", "cf4b66544ba6c4fef1f6c5b274ad23da874c8f6918f6b7eee9523990c81d63c320fbd77c0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b6d2fdf4a5f6ce03897c5abd3c406fb05c6f1a24828eb763498306d4cd4d3ad21cf46ef400000000000000")
            eq(crypt.hash1024 "ab", "284766544ba6c4fef1f6c5b274ad23da874c8f6918f6b7eee9523990c81d63c320fbd77c0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3d2fdf4a5f6ce03897c5abd3c406fb05c6f1a24828eb763498306d4cd4d3ad21cf46ef400000000000000")
            eq(crypt.hash1024 "0123456701234567012345670123456701234567012345670123456701234567", "f324b407d6d26993b2131f7638a6fa060a14a5b31ebf4b80264e29d9f78f171f9af1d98855518b348a88c2b6144dc96080b85915c2606fad5b53389e2826453d58694593e7f8225b62ef5aab999d9953e14ac7db5f729fbf77ee0e0e7e65493e4f59a4cd568625725ac6d23094e5db9554d13763d159f41864142bb434f152c2")
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
        eq(crypt.hash "Hello World!", "326e9efbd1c80e8c")
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
