#!/usr/bin/env luax

-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/bang

-- Use the Lua sources of bang to generate the build.ninja file
-- that will be used to compile and test bang...

local fs = require "fs"

-- set Lua search path to load modules that will later live in the bang executable
package.path = "src/?.lua"

-- Load bang libraries that would be automatically loaded by LuaX
local main = nil
fs.ls "src/*.lua" : foreach(function(name)
    local content = fs.read(name)
    if content:match "@LOAD" then
        local mod = name:basename():splitext()
        _G[mod] = require(mod)
    elseif content:match "@MAIN" then
        main = name
    end
end)
package.preload["bang-version"] = function() return "N/A" end

-- Execute the main bang Lua script
dofile(assert(main, "Main script not found"))
