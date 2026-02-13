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

--@LOAD=_

-- This module adds mathx functions to the math module.

--[=[-----------------------------------------------------------------------@@@
# math

The standard Lua package `math` is enhanced with the `mathx` functions.
@@@]=]

local mathx = require "mathx"

for n, f in pairs(mathx) do
    local t = type(f)
    if math[n] == nil and (t == "function" or t == "number") then
        math[n] = f
    end
end
