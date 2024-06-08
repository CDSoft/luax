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

--@LIB

local F = require "F"
local lz4 = require "lz4"
local cbor = require "cbor"
local crypt = require "crypt"

--[[------------------------------------------------------------------------@@@
## Lua Archive
@@@]]

--[[@@@
```lua
local lar = require "lar"
```

`lar` is a simple archive format for Lua values (e.g. Lua tables).
It contains a Lua value:

- serialized with `cbor`
- compressed with `lz4`
- encrypted with `rc4` (e.g. to avoid unintended modifications)
@@@]]
local lar = {}

--[[@@@
```lua
lar.lar(lua_value, [key])
```
Returns a string with `lua_value` serialized, compressed and encrypted.
@@@]]

function lar.lar(lua_value, key)
    local serialized = assert(cbor.encode(lua_value, {pairs=F.pairs}))
    local compressed = assert(lz4.lz4(serialized))
    local encrypted  = crypt.rc4(compressed, key or "")
    return encrypted
end

--[[@@@
```lua
lar.unlar(archive, [key])
```
Returns the Lua value contained in serialized, compressed and encrypted string.
@@@]]

function lar.unlar(encrypted, key)
    local decrypted    = crypt.unrc4(encrypted, key or "")
    local decompressed = assert(lz4.unlz4(decrypted))
    local lua_value    = assert(cbor.decode(decompressed))
    return lua_value
end

return lar
