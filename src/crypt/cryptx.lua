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

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `crypt` package are added to the string module:

@@@]]

local crypt = require "crypt"

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
s:sha256()          == crypt.sha256(s)
s:hmac(key)         == crypt.hmac(s, key)
s:aes(key)          == crypt.aes(s, key)
s:unaes(key)        == crypt.unaes(s, key)
```
@@@]]

function string.hex(s)          return crypt.hex(s) end
function string.unhex(s)        return crypt.unhex(s) end
function string.base64(s)       return crypt.base64(s) end
function string.unbase64(s)     return crypt.unbase64(s) end
function string.base64url(s)    return crypt.base64url(s) end
function string.unbase64url(s)  return crypt.unbase64url(s) end
function string.rc4(s, k, d)    return crypt.rc4(s, k, d) end
function string.unrc4(s, k, d)  return crypt.unrc4(s, k, d) end
function string.crc32(s)        return crypt.crc32(s) end
function string.crc64(s)        return crypt.crc64(s) end

-- TinyCrypt functions

function string.sha256(s)       return crypt.sha256(s) end
function string.hmac(s, k)      return crypt.hmac(s, k) end
function string.aes(s, k)       return crypt.aes(s, k) end
function string.unaes(s, k)     return crypt.unaes(s, k) end
