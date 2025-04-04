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

local test = {}

local F = require "F"

local function is_a_list(t)
    for k, _ in pairs(t) do
        if type(k) ~= "number" then return false end
        if math.type(k) ~= "integer" then return false end
        if k < 1 then return false end
    end
    return true
end

local function dump(t)
    if (getmetatable(t) or {}).imag then return t:tostring() end
    if (getmetatable(t) or {}).__tostring then return ("%q"):format(tostring(t)) end
    if type(t) == "function" then return tostring(t) end
    if type(t) ~= "table" then return ("%q"):format(t) end
    if is_a_list(t) then
        local s = {}
        for _,x in ipairs(t) do s[#s+1] = ("%s"):format(dump(x)) end
        return "{"..table.concat(s, ",").."}"
    else
        local s = {}
        for k,v in F.pairs(t) do s[#s+1] = ("%s=%s"):format(k, dump(v)) end
        return "{"..table.concat(s, ",").."}"
    end
end

local function same(a, b)
    local ta = type(a)
    local tb = type(b)
    if ta ~= tb then return false end
    if getmetatable(a) and getmetatable(a).__index and getmetatable(a).__index.imag
        and getmetatable(b) and getmetatable(b).__index and getmetatable(b).__index.imag
        then return (a-b):abs() < 1e-12 end
    if ta == "number" then
        -- absolute error for "small" numbers
        if math.max(math.abs(a), math.abs(b)) < 1000 then return math.abs(a-b) < 1e-12 end
        -- infinite numbers
        if a >= 1/0 and b >= 1/0 then return true end
        if a <= -1/0 and b <= -1/0 then return true end
        -- relative error for large numbers
        return math.abs((a-b)/b) < 1e-6
    end
    if ta ~= "table" then return a == b end
    local function contains(x, y)
        for k, v in pairs(y) do
            if not same(x[k], v) then return false end
        end
        return true
    end
    return contains(a, b) and contains(b, a)
end

function test.eq(a, b)
    if same(a, b) then return end
    error(([[

Got     : %s
Expected: %s
]]):format(dump(a), dump(b)), 2)
end

function test.ne(a, b)
    if not same(a, b) then return end
    error(("Unexpected: %s"):format(dump(a)))
end

function test.bounded(x, a, b)
    if x >= a and x <= b then return end
    error(([[

Got     : %s
Expected: [%s, %s]
]]):format(x, a, b), 2)
end

function test.startswith(a, b)
    if a:sub(1, #b) == b then return end
error(([[

Got     : %s
Expected: %s
]]):format(dump(a), dump(b)), 2)
end

return test
