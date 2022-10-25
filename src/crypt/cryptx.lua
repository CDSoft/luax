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
s:hex_encode()          == crypt.hex_encode(s)
s:hex_decode()          == crypt.hex_decode(s)
s:base64_encode()       == crypt.base64_encode(s)
s:base64_decode()       == crypt.base64_decode(s)
s:base64url_encode()    == crypt.base64url_encode(s)
s:base64url_decode()    == crypt.base64url_decode(s)
s:crc32()               == crypt.crc32(s)
s:crc64()               == crypt.crc64(s)
s:rc4(key, drop)        == crypt.crc64(s, key, drop)
s:sha256()              == crypt.sha256(s)
s:hmac(key)             == crypt.hmac(s, key)
s:aes_encrypt(key)      == crypt.aes_encrypt(s, key)
s:aes_decrypt(key)      == crypt.aes_decrypt(s, key)
```
@@@]]

function string.hex_encode(s) return crypt.hex_encode(s) end
function string.hex_decode(s) return crypt.hex_decode(s) end
function string.base64_encode(s) return crypt.base64_encode(s) end
function string.base64_decode(s) return crypt.base64_decode(s) end
function string.base64url_encode(s) return crypt.base64url_encode(s) end
function string.base64url_decode(s) return crypt.base64url_decode(s) end
function string.rc4(s, k, d) return crypt.rc4(s, k, d) end
function string.crc32(s) return crypt.crc32(s) end
function string.crc64(s) return crypt.crc64(s) end

-- TinyCrypt functions

function string.sha256(s) return crypt.sha256(s) end
function string.hmac(s, k) return crypt.hmac(s, k) end
function string.aes_encrypt(s, k) return crypt.aes_encrypt(s, k) end
function string.aes_decrypt(s, k) return crypt.aes_decrypt(s, k) end
