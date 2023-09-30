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

local byte = string.byte
local char = string.char

local function prng(seed)
    seed = seed*6364136223846793005 + 1
    seed = seed*6364136223846793005 + 1
    return function()
        seed = seed*6364136223846793005 + 1
        return seed
    end
end

local function hash(s)
    local h = 1844674407370955155*10+7
    h = h * 6364136223846793005 + 1
    for i = 1, #s do
        local c = byte(s, i)
        h = h * 6364136223846793005 + ((c << 1) | 1)
    end
    h = h * 6364136223846793005 + 1
    return h
end

local name, key = table.unpack(arg)
key = key : gsub("\\x(..)", function(h) return char(tonumber(h, 16)) end)

local function write(fmt, ...)
    io.stdout:write(fmt:format(...))
end

write("/* key: %s */\n", key)
write("#define %s(K) ", name)

local kxor = hash(key) % 256
local rot = hash(string.reverse(key)) % 4 + 2

local encrypted_key = {}
for i = 1, #key do
    local c = byte(key, i)
    c = (c<<rot) | (c>>(8-rot))
    c = c ~ kxor
    encrypted_key[i] = c & 0xff
end

local rnd = prng(hash(key))

local permutation = {}
for i = 1, #key do permutation[i] = i end
for i = 1, #key-1 do
    local j = i + (rnd() % (#key-i)) + 1
    permutation[i], permutation[j] = permutation[j], permutation[i]
end

write("unsigned char K[%d];", #key)
for i = 1, #key do
    local j = permutation[i]
    write("K[%d]=%d;", j-1, encrypted_key[j])
end

write("for(int i=0;i<%d;i++){", #key)
write("int c=K[i]^%d;", kxor)
write("K[i]=(unsigned char)((c>>%d)|(c<<%d));", rot, 8-rot)
write("}\n")
