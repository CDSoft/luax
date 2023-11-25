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

    local json = require "json"
    assert(json)

    -- numbers
    do
        local t = {
            [ "123.456"       ] = 123.456,
            [ "-123"          ] = -123,
            [ "-567.765"      ] = -567.765,
            [ "12.3"          ] = 12.3,
            [ "0"             ] = 0,
            [ "0.10000000012" ] = 0.10000000012,
        }
        for k, v in pairs(t) do
            local res = json.decode(k)
            eq(res, v)
            res = json.encode(v)
            eq(res, k)
        end
        eq(json.decode("13e2"), 13e2)
        eq(json.decode("13E+2"), 13e2)
        eq(json.decode("13e-2"), 13e-2)
    end

    -- literals
    do
        eq(json.decode("true"), true)
        eq(json.encode(true), "true")
        eq(json.decode("false"), false)
        eq(json.encode(false), "false")
        eq(json.decode("null"), nil)
        eq(json.encode(nil), "null")
    end

    -- strings, unicode, arrays, objects
    do
        local tests = {
            "", "\\", "Hello, World!", "\0 \13 \27", "\0\r\n\8",
            "こんにちは世界",
            {"cat", "dog", "owl"},
            {x = 10, y = 20, z = 30},
        }
        for _, t in ipairs(tests) do
            eq(json.decode(json.encode(t)), t)
        end
    end

end
