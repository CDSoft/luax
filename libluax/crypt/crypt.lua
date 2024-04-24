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

-- Load crypt.lua to add new methods to strings
--@LOAD=_

local crypt = require "_crypt"

local F = require "F"

--[[------------------------------------------------------------------------@@@
## Random array access

@@@]]

--[[@@@
```lua
prng:choose(xs)
crypt.choose(xs)    -- using the global PRNG
```
returns a random item from `xs`
@@@]]

local prng_mt = getmetatable(crypt.prng())

function prng_mt.__index.choose(prng, xs)
    return xs[prng:int(1, #xs)]
end

function crypt.choose(xs)
    return xs[crypt.int(1, #xs)]
end

--[[@@@
```lua
prng:shuffle(xs)
crypt.shuffle(xs)    -- using the global PRNG
```
returns a shuffled copy of `xs`
@@@]]

function prng_mt.__index.shuffle(prng, xs)
    local ys = F.clone(xs)
    for i = 1, #ys-1 do
        local j = prng:int(i, #ys)
        ys[i], ys[j] = ys[j], ys[i]
    end
    return ys
end

function crypt.shuffle(xs)
    local ys = F.clone(xs)
    for i = 1, #ys-1 do
        local j = crypt.int(i, #ys)
        ys[i], ys[j] = ys[j], ys[i]
    end
    return ys
end

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `crypt` package are added to the string module:

@@@]]

--[[@@@
```lua
s:hex()             == crypt.hex(s)
s:unhex()           == crypt.unhex(s)
s:base64()          == crypt.base64(s)
s:unbase64()        == crypt.unbase64(s)
s:base64url()       == crypt.base64url(s)
s:unbase64url()     == crypt.unbase64url(s)
s:crc32()           == crypt.crc32(s)
s:crc64()           == crypt.crc64(s)
s:rc4(key, drop)    == crypt.rc4(s, key, drop)
s:unrc4(key, drop)  == crypt.unrc4(s, key, drop)
s:hash()            == crypt.hash(s)
```
@@@]]

string.hex          = crypt.hex
string.unhex        = crypt.unhex
string.base64       = crypt.base64
string.unbase64     = crypt.unbase64
string.base64url    = crypt.base64url
string.unbase64url  = crypt.unbase64url
string.rc4          = crypt.rc4
string.unrc4        = crypt.unrc4
string.hash         = crypt.hash
string.crc32        = crypt.crc32
string.crc64        = crypt.crc64

return crypt
