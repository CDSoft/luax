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
https://codeberg.org/cdsoft/luax
--]]

-- Use the Lua sources of luax to execute a LuaX script
-- before LuaX is actually compiled.
--
-- Note: This script is a minimal and incomplete LuaX implementation in Lua.
--       It is not meant to be used outside the LuaX build system.

-- set Lua search path to load modules that will later live in the luax executable
package.path = table.concat({
    "luax/?.lua",

    "libluax/crypt/?.lua",
    "libluax/F/?.lua",
    "libluax/fs/?.lua",
    "libluax/import/?.lua",
    "libluax/mathx/?.lua",
    "libluax/sh/?.lua",
    "libluax/sys/?.lua",
    "libluax/term/?.lua",
    "libluax/lar/?.lua",

    "ext/lua/argparse/?.lua",
    "ext/lua/cbor/?.lua",
}, ";")

-- Install LuaX hooks
dofile "libluax/package/package_hook.lua"

-- Execute the main LuaX script
dofile "luax/luax.lua"
