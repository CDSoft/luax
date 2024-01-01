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

local function luax_env(arg0)

    local path = os.getenv "PATH" or ""
    local lua_path = os.getenv "LUA_PATH" or ""
    local lua_cpath = os.getenv "LUA_CPATH" or ""

    local exe = assert(fs.is_file(arg0) and arg0 or fs.findpath(arg0))

    local abi = F.case(sys.os) { linux="gnu", macos="none",  windows="gnu" }
    local ext = F.case(sys.os) { linux="so",  macos="dylib", windows="dll" }

    local bin = exe:dirname():realpath()
    local prefix = bin:dirname()
    local lib_lua = prefix / "lib" / "?.lua"
    local lib_so = prefix / "lib" / F{"?", sys.arch, sys.os, abi, ext}:str("-", ".")

    return F{
        path:split(fs.path_sep):elem(bin)
            and ('# PATH already contains %s'):format(bin)
            or ('export PATH="%s%s$PATH";'):format(bin, fs.path_sep),
        lua_path:split";":elem(lib_lua)
            and ('# LUA_PATH already contains %s'):format(lib_lua)
            or ('export LUA_PATH="%s;$LUA_PATH";'):format(lib_lua),
        lua_cpath:split";":elem(lib_so)
            and ('# LUA_CPATH already contains %s'):format(lib_so)
            or ('export LUA_CPATH="%s;$LUA_CPATH";'):format(lib_so),
    } : unlines()
end

local function user_env(args)
    local import = require "import"
    local script = {}
    local function dump(t, p)
        if type(t) == "table" then
            F.foreachk(t, function(k, v)
                dump(v, (p and p.."_" or "")..k)
            end)
        else
            local s = tostring(t)
                  : gsub("\n", "\\n")
                  : gsub("\'", "\\'")
            script[#script+1] = "export "..p:upper().."='"..s.."';"
        end
    end
    dump(import(args[1]))
    return F.unlines(script)
end

return function(arg0, args)
    if not args or #args == 0 then
        return luax_env(arg0)
    else
        return user_env(args)
    end
end
