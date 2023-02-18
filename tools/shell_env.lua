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

local function shell_env()

    local path = os.getenv "PATH" or ""
    local lua_cpath = os.getenv "LUA_CPATH" or ""

    local exe = fs.is_file(arg[0]) and arg[0] or fs.findpath(arg[0])

    local bin = fs.realpath(fs.dirname(exe))
    local lib = fs.join(
        fs.dirname(bin), "lib",
           sys.os == "linux"   and "?-"..sys.arch.."-linux-gnu.so"
        or sys.os == "macos"   and "?-"..sys.arch.."-macos-gnu.dylib"
        or sys.os == "windows" and "?-"..sys.arch.."-windows-gnu.dll"
    )

    return F{
        path:split(fs.path_sep):elem(bin)
            and ('# PATH already contains %s'):format(bin)
            or ('PATH="%s%s$PATH"; export PATH'):format(bin, fs.path_sep),
        lua_cpath:split";":elem(lib)
            and ('# LUA_CPATH already contains %s'):format(lib)
            or ('LUA_CPATH="%s;$LUA_CPATH"; export LUA_CPATH'):format(lib),
    } : unlines()
end

return shell_env
