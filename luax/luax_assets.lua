#!/usr/bin/env luax
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
local fs = require "fs"
local lar = require "lar"
local sys = require "sys"

local function findpath(name)
    if sys.os == "windows" and not name:lower():has_suffix(sys.exe:lower()) then
        name = name..sys.exe
    end
    if name:is_file() then return name:realpath() end
    local full_path = name:findpath()
    return full_path and full_path:realpath() or name
end

local function find_archive()

    local libdir = os.getenv "LUAX_LIB"
    if libdir then
        local archive = libdir/"libluax.lar"
        if archive:is_file() then return archive end
    end

    local N = F.keys(arg) : minimum()

    for i = 0, N, -1 do

        local path = findpath(arg[i])
        if path then
            local archive = path:dirname():dirname()/"lib"/"libluax.lar"
            if archive:is_file() then return archive end
        end

    end

end

local mt = {
    __index = {
        error = function() error("The LuaX runtime (lib/libluax.lar) is not installed or is corrupted") end,
    }
}

local archive = find_archive()
if not archive then return setmetatable({}, mt) end

local content = assert(fs.read_bin(archive))
local assets = assert(lar.unlar(content))

assets.path = archive

return setmetatable(assets, mt)
