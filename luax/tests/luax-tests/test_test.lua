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

Software freedom is inseparable from freedom of thought. Fascism -
in all its forms - is incompatible with the values this project stands
on, even though the GPL itself cannot and does not restrict who may
use this software. See FREEDOM.md.

You should have received a copy of the GNU General Public License
along with luax.  If not, see <https://www.gnu.org/licenses/>.

For further information about luax you can visit
https://codeberg.org/cdsoft/luax
--]]

---------------------------------------------------------------------
-- Check the test environment
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq
local ne = test.ne

return function()

    -- eq

    eq(1, 1)
    assert(not pcall(eq, 1, 2))
    assert(not pcall(eq, 1, "1"))

    eq("1", "1")
    assert(not pcall(eq, "1", "2"))
    assert(not pcall(eq, "1", 1))

    eq({"Lua","is","great",{"sub","list"}}, {"Lua","is","great",{"sub","list"}})
    assert(not pcall(eq, {"Lua","is","great",{"sub","list"}}, {"Lua","is","super","great",{"sub","list"}}))
    assert(not pcall(eq, {"Lua","is","super","great",{"sub","list"}}, {"Lua","is","great",{"sub","list"}}))

    eq({x=1, y=2}, {x=1, y=2})
    assert(not pcall(eq, {x=1, y=2}, {x=1, y=3}))
    assert(not pcall(eq, {x=1, y=2}, {x=1, y=2, z=3}))

    -- ne

    assert(not pcall(ne, 1, 1))
    ne(1, 2)
    ne(1, "1")

    assert(not pcall(ne, "1", "1"))
    ne("1", "2")
    ne("1", 1)

    assert(not pcall(ne, {"Lua","is","great",{"sub","list"}}, {"Lua","is","great",{"sub","list"}}))
    ne({"Lua","is","great",{"sub","list"}}, {"Lua","is","super","great",{"sub","list"}})
    ne({"Lua","is","super","great",{"sub","list"}}, {"Lua","is","great",{"sub","list"}})

    assert(not pcall(ne, {x=1, y=2}, {x=1, y=2}))
    ne({x=1, y=2}, {x=1, y=3})
    ne({x=1, y=2}, {x=1, y=2, z=3})

end
