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

--@LIB

local F = require "F"
local cbor = require "cbor"
local crypt = require "crypt"
local lz4 = require "lz4"
local lzip = require "lzip"

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
- compressed with `lz4` or `lzip`
- encrypted with `arc4`

The Lua value is only encrypted if a key is provided.
@@@]]
local lar = {}

local MAGIC = "!<LuaX archive>"

local RAW  <const> = 0
local LZ4  <const> = 1
local LZIP <const> = 2

local compression_options = {
    { algo=nil,    flag=RAW,  compress=F.id,      decompress=F.id   },
    { algo="lz4",  flag=LZ4,  compress=lz4.lz4,   decompress=lz4.unlz4  },
    { algo="lzip", flag=LZIP, compress=lzip.lzip, decompress=lzip.unlzip },
}

local function find_options(x)
    for i = 1, #compression_options do
        local opt = compression_options[i]
        if x==opt.algo or x==opt.flag then return opt end
    end
    return compression_options[1]
end

--[[@@@
```lua
lar.lar(lua_value, [opt])
```
Returns a string with `lua_value` serialized, compressed and encrypted.

Options:

- `opt.compress`: compression algorithm (`"lzip"` by default):

    - `"none"`: no compression
    - `"lz4"`: compression with LZ4 (default compression level)
    - `"lz4-#"`: compression with LZ4 (compression level `#` with `#` between 0 and 12)
    - `"lzip"`: compression with lzip (default compression level)
    - `"lzip-#"`: compression with lzip (compression level `#` with `#` between 0 and 9)

- `opt.key`: encryption key (no encryption by default)
@@@]]

function lar.lar(lua_value, lar_opt)
    lar_opt = lar_opt or {}
    local algo, level = (lar_opt.compress or "lzip"):split"%-":unpack()
    local compress_opt = find_options(algo)

    local payload = cbor.encode(lua_value, {pairs=F.pairs})
    payload = assert(compress_opt.compress(payload, tonumber(level)))
    if lar_opt.key then payload = crypt.arc4(payload, lar_opt.key) end

    return string.pack("<zBs4", MAGIC, compress_opt.flag, payload)
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

    if opt.key then payload = crypt.unarc4(payload, opt.key) end
    local compress_opt = find_options(compress_flag)
    payload = assert(compress_opt.decompress(payload))

    return cbor.decode(payload)
end

return lar
