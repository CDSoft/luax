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

local test = require "test"
local eq = test.eq

return function()

    local cbor = require "cbor"
    assert(cbor)

    local function check(t)
        local encoded = cbor.encode(t)
        eq(type(encoded), "string")
        eq(cbor.decode(encoded), t)
    end

    check(42)
    check("Hello")

    check({})
    check({1, 2, 3})
    check({x=1, y=2, z=3})
    check({a={x=1, y=2}, {x=3, y=4}, 5, 6})

    check({
        "a", "b",
        p = {x=10, y=20},
        refs = {},
    })

end
