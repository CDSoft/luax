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
- encrypted with `rc4`

The Lua value is only encrypted if a key is provided.
@@@]]
local lar = {}

local MAGIC = "!<LuaX archive>"

local LZ4 = 1

--[[@@@
```lua
lar.lar(lua_value, [opt])
```
Returns a string with `lua_value` serialized, compressed and encrypted.

Options:

- `opt.compress`: compression algorithm (`"lz4"` by default):

    - `"none"`: no compression
    - `"lz4"`: compression with LZ4 (default compression level)
    - `"lz4-#"`: compression with LZ4 (compression level `#` with `#` between 0 and 12)

- `opt.key`: encryption key (no encryption by default)
@@@]]

function lar.lar(lua_value, opt)
    opt = opt or {}
    local compress, level = (opt.compress or "lz4"):split"%-":unpack()
    local compress_flag = 0

    local payload = cbor.encode(lua_value, {pairs=F.pairs})
    if compress == "lz4" then
        compress_flag = LZ4
        payload = assert(lz4.lz4(payload, tonumber(level)))
    end
    if opt.key then payload = crypt.rc4(payload, opt.key) end

    return string.pack("<zBs4", MAGIC, compress_flag, payload)
end

--[[@@@
```lua
lar.unlar(archive, [opt])
```
Returns the Lua value contained in a serialized, compressed and encrypted string.

Options:

- `opt.key`: encryption key (no encryption by default)
@@@]]

function lar.unlar(archive, opt)
    opt = opt or {}

    if type(archive)~="string" then
        error("bad argument #1 to 'unlar' (string expected, got "..type(archive)..")")
    end
    local ok, magic, compress_flag, payload = pcall(string.unpack, "<zBs4", archive)
    assert(ok and magic==MAGIC, "not a LuaX archive")

    if opt.key then payload = crypt.unrc4(payload, opt.key) end
    if compress_flag == LZ4 then payload = assert(lz4.unlz4(payload)) end

    return cbor.decode(payload)
end

return lar
