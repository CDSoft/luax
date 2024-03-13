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

    local exe = assert(fs.is_file(arg0) and arg0 or fs.findpath(arg0))

    local bin = exe:dirname():realpath()
    local prefix = bin:dirname()
    local lib_lua = prefix / "lib" / "?.lua"
    local lib_so = prefix / "lib" / "?"..sys.so

    local function update(var_name, separator, new_path)
        return F{
            "export ", var_name, "=\"",
            F.flatten {
                new_path,
                (os.getenv(var_name) or "") : split(separator),
            } : nub() : str(separator),
            "\";",
        } : str()
    end

    local lua_path_sep = package.config:words()[2]

    return F.unlines {
        update("PATH",      fs.path_sep,  bin),
        update("LUA_PATH",  lua_path_sep, lib_lua),
        update("LUA_CPATH", lua_path_sep, lib_so),
    }
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
