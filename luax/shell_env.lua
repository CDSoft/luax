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
local fs = require "fs"
local sys = require "sys"

local function shell_env()

    local path = os.getenv "PATH" or ""
    local lua_path = os.getenv "LUA_PATH" or ""
    local lua_cpath = os.getenv "LUA_CPATH" or ""

    local exe = assert(fs.is_file(arg[0]) and arg[0] or fs.findpath(arg[0]))

    local abi = { linux="gnu", macos="none",  windows="gnu" }
    local ext = { linux="so",  macos="dylib", windows="dll" }

    local bin = exe:dirname():realpath()
    local prefix = bin:dirname()
    local lib_lua = prefix / "lib" / "?.lua"
    local lib_so = prefix / "lib" / F{"?", sys.arch, sys.os, abi[sys.os], ext[sys.os]}:str("-", ".")

    return F.flatten{
        path:split(fs.path_sep):elem(bin)
            and ('# PATH already contains %s'):format(bin)
            or ('PATH="%s%s$PATH"; export PATH;'):format(bin, fs.path_sep),
        lua_path:split";":elem(lib_lua)
            and ('# LUA_PATH already contains %s'):format(lib_lua)
            or ('LUA_PATH="%s;$LUA_PATH"; export LUA_PATH;'):format(lib_lua),
        lua_cpath:split";":elem(lib_so)
            and ('# LUA_CPATH already contains %s'):format(lib_so)
            or ('LUA_CPATH="%s;$LUA_CPATH"; export LUA_CPATH;'):format(lib_so),
    } : unlines()
end

return shell_env
