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

local luax_config = require "luax_config"
local F = require "F"

local copyright_pattern = "(%S+%s+)(%S+%s*)(.*)"
local luax_name, luax_version, luax_copyright = luax_config.copyright:match(copyright_pattern)
local lua_name,  lua_version,  lua_copyright  = luax_config.lua_copyright:match(copyright_pattern)

local w_name = math.max(#luax_name, #lua_name)
local w_version = math.max(#luax_version, #lua_version)

io.stdout:write(F.str{luax_name:ljust(w_name), luax_version:ljust(w_version), luax_copyright}, "\n")
io.stdout:write(F.str{lua_name :ljust(w_name), lua_version :ljust(w_version), lua_copyright }:rtrim(), "\n")
