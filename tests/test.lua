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

local function is_a_list(t)
    for k, _ in pairs(t) do
        if type(k) ~= "number" then return false end
    end
    return true
end

function dump(t)
    if (getmetatable(t) or {}).imag then return t:tostring() end
    if type(t) ~= "table" then return ("%q"):format(t) end
    if is_a_list(t) then
        local s = {}
        for _,x in ipairs(t) do s[#s+1] = ("%s"):format(dump(x)) end
        return "{"..table.concat(s, ",").."}"
    else
        local s = {}
        for k,v in pairs(t) do s[#s+1] = ("%s=%s"):format(k, dump(v)) end
        return "{"..table.concat(s, ",").."}"
    end
end

local function same(a, b)
    local ta = type(a)
    local tb = type(b)
    if ta ~= tb then return false end
    if (getmetatable(a) or {}).imag and (getmetatable(a) or {}).imag then return (a-b):abs() < 1e-12 end
    if ta ~= "table" then return a == b end
    local function contains(a, b)
        for k, v in pairs(b) do
            if not same(a[k], v) then return false end
        end
        return true
    end
    return contains(a, b) and contains(b, a)
end

function eq(a, b)
    if same(a, b) then return end
    error(([[

Got     : %s
Expected: %s
]]):format(dump(a), dump(b)), 2)
end

function ne(a, b)
    if not same(a, b) then return end
    error(("Unexpected: %s"):format(dump(a)))
end

function bounded(x, a, b)
    if x >= a and x <= b then return end
    error(([[

Got     : %s
Expected: [%s, %s]
]]):format(x, a, b), 2)
end
