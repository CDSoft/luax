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
https://github.com/cdsoft/luax
--]]

---------------------------------------------------------------------
-- debug
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local debug = require "debug"

return function()

    local function f(fx, fy)
        local a = 1                     ---@diagnostic disable-line: unused-local
        local function g(gx, gy)
            local b = 2                 ---@diagnostic disable-line: unused-local
            local function h(hx, hy)    ---@diagnostic disable-line: unused-local
                local c = 3             ---@diagnostic disable-line: unused-local
                eq(debug.locals(),  {hx=1000, hy=2000, c=3})
                eq(debug.locals(1), {hx=1000, hy=2000, c=3})
                eq(debug.locals(2), {gx=100,  gy=200,  b=2, h=h})
                eq(debug.locals(3), {fx=10,   fy=20,   a=1, g=g})
                eq(debug.locals(4), {f=f})

                eq(debug.locals(f), {"fx", "fy"})
                eq(debug.locals(g), {"gx", "gy"})
                eq(debug.locals(h), {"hx", "hy"})
            end
            h(gx*10, gy*10)
        end
        g(fx*10, fy*10)
    end

    f(10, 20)

end
