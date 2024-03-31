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

    -- order
    do
        local F = require "F"
        local function reversed_pairs(xs)
            local rxs = F.items(xs):reverse()
            local i = 0
            return function()
                i = i+1
                if i <= #rxs then
                    return table.unpack(rxs[i])
                end
            end
        end
        local tests = {
            { {x=1, y=2, z=3, t={a=1, b=2, c=3}}, {pairs=F.pairs},        [[\xa4At\xa3Aa\x01Ab\x02Ac\x03Ax\x01Ay\x02Az\x03]] },
            { {x=1, y=2, z=3, t={a=1, b=2, c=3}}, {pairs=reversed_pairs}, [[\xa4Az\x03Ay\x02Ax\x01At\xa3Ac\x03Ab\x02Aa\x01]] },
        }
        local function esc(s)
            return s : gsub("[^%g%s]", function(c) return ("\\x%02x"):format(c:byte()) end)
        end
        for _, t in ipairs(tests) do
            eq(esc(cbor.encode(t[1], t[2])), t[3])
            eq(cbor.decode(cbor.encode(t[1], t[2])), t[1])
        end
    end

end
