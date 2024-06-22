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
http://cdelord.fr/luax
--]]

--@LIB

local fs = require "fs"
local lar = require "lar"

local F = require "F"

local function findpath(name)
    if name:is_file() then return name:realpath() end
    local full_path = name:findpath()
    return full_path and full_path:realpath() or name
end

local function find_archive()

    local libdir = os.getenv "LUAX_LIB"
    if libdir then
        local archive = libdir/"luax.lar"
        if archive:is_file() then return archive end
    end

    local N = F.keys(arg) : minimum()

    for i = N, 0 do

        local exe = arg[i]
        local path = findpath(exe)
        if path then
            local archive = path:dirname():dirname()/"lib"/"luax.lar"
            if archive:is_file() then return archive end
        end

    end

end

local archive = find_archive()
if not archive then return {} end
local content = assert(fs.read_bin(archive))
local assets = assert(lar.unlar(content))
assets.path = archive
return assets
