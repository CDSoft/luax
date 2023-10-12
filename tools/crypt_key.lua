#!/usr/bin/env lua

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

-- hash function inspired by crypt.hash
local function hash(s)
    local h = 1844674407370955155*10+7
    h = h * 6364136223846793005 + 1
    for i = 1, #s do
        local c = s:byte(i)
        h = h * 6364136223846793005 + ((c << 1) | 1)
    end
    h = h * 6364136223846793005 + 1
    return h
end

local name, key = table.unpack(arg)
key = key : gsub("\\x(..)", function(h) return string.char(tonumber(h, 16)) end)

local function write(fmt, ...)
    io.stdout:write(fmt:format(...))
end

-- Linear congruential generator used to encrypt the decryption key
-- (see https://en.wikipedia.org/wiki/Linear_congruential_generator (Turbo Pascal random number generator)
local a = 134775813
local c = 1
local m = 32

-- Seed value of the generator
local r0 = (hash(key)>>32) % (1<<m)

a = a % (1<<m)

-- Drop some values to make it less predictable
for _ = 1, 3072 + (hash(key)&0xffff) do
    r0 = (r0*a + c) % (1<<m)
end

-- Encrypt the key by xoring bytes with pseudo random values
local encrypted_key = {}
local r = r0
for i = 1, #key do
    r = (r*a + c) % (1<<m)
    encrypted_key[i] = (key:byte(i) ~ (r>>(m/2))) & 0xff
end

-- The encrypted key is stored in a C source file
-- and is decrypted at runtime.

write("/* key: %s */\n", key)
write("#define %s(K) \\\n", name)

-- buffer where the key is decrypted
write("    uint8_t K[%d]; \\\n", #key)
write("    { \\\n")

-- encrypted key stored as a constant
write("        static const uint8_t k[%d] = {", #key)
for i = 1, #key do write("%d,", encrypted_key[i]) end
write("};\\\n")

-- The runtime uses the same algorithm to generate pseudo random values
-- used to decrypt the encrypted key

-- "volatile const" to avoid code optimizations that may decrypt the key at compilation time
write("        volatile const uint%d_t r0 = %d; \\\n", m, r0);
write("        uint%d_t r = r0; \\\n", m);
write("        for (int i = 0; i < %d; i++) { \\\n", #key)
write("            r = r*%d + %d; \\\n", a, c)
write("            K[i] = (uint8_t)(k[i] ^ (r>>%d)); \\\n", m/2)    assert(m/2 >= 8)
write("        } \\\n")

write("    }\n")
