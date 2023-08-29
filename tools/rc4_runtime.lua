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

--@LOAD

-- Override crypt.rc4 to use the runtime key if no key is given.
-- This script is used with bundle.lua when it is run with a standard Lua interpreter
-- (e.g. to bootstrap the first LuaX runtime).
-- It is not embedded in the final LuaX binaries.

local crypt = require "crypt"

local runtime_key = assert(os.getenv "CRYPT_KEY") : gsub("\\x", "") : unhex()
local runtime_drop = 3072

local rc4 = crypt.rc4

local function runtime_rc4(input, key, drop)
    if key == nil then
        key, drop = runtime_key, runtime_drop
    end
    return rc4(input, key, drop)
end

crypt.rc4   = runtime_rc4
crypt.unrc4 = runtime_rc4
