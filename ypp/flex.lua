--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
--]]

local F = require "F"

-- A flex function is a curried function with a variable number of parameters.
-- It is implemented with a callable table.
-- The actual value is computed when evaluated as a string.
-- It takes several arguments:
--      - exactly one string (the argument)
--      - zero or many option tables (they are all merged until tostring is called)

-- e.g.:
--      function f(s, opt)
--          ...
--      end
--
--      g = flex(f)
--
--      g "foo" {x=1}       => calls f("foo", {x=1})
--      g {y=2} "foo" {x=1} => calls f("foo", {x=1, y=2})
--
--      h = g{z=3} -- kind of "partial application"
--
--      h "foo"             => calls f("foo", {z=3})
--      h "foo" {x=1}       => calls f("foo", {x=1, z=3})

local flex_str_mt = {}

function flex_str_mt:__call(x)
    local xmt = getmetatable(x)
    if type(x) ~= "table" or (xmt and xmt.__tostring) then
        -- called with a string or a table with a __tostring metamethod
        -- ==> store the string
        if self.s ~= F.Nil then ypp.error "multiple argument" end
        return setmetatable({s=tostring(x), opt=self.opt, f=self.f}, flex_str_mt)
    else
        -- called with an option table
        -- ==> add the new options to the current ones
        return setmetatable({s=self.s, opt=self.opt:patch(x), f=self.f}, flex_str_mt)
    end
end

function flex_str_mt:__tostring()
    -- string value requested
    -- convert to string and call f on this string
    if self.s == F.Nil then ypp.error "missing argument" end
    return tostring(self.f(self.s, self.opt))
end

function flex_str_mt:__index(k)
    -- string method requested but the object is not a string yet
    -- ==> make a string proxy
    if string[k] then
        return function(s, ...)
            return string[k](tostring(s), ...)
        end
    end
end

local function flex_str(f)
    return setmetatable({s=F.Nil, opt=F{}, f=f}, flex_str_mt)
end

-- flex_array is similar to flex_str but cumulates any number of parameters in an array

local flex_array_mt = {}

function flex_array_mt:__call(x)
    local xmt = getmetatable(x)
    if type(x) ~= "table" or (xmt and xmt.__tostring) then
        -- called with a string or a table with a __tostring metamethod
        -- ==> store the string
        return setmetatable({xs=self.xs..{x}, opt=self.opt, f=self.f}, flex_array_mt)
    else
        -- called with an option table
        -- ==> add the new options to the current ones
        return setmetatable({xs=self.xs, opt=self.opt:patch(x), f=self.f}, flex_array_mt)
    end
end

function flex_array_mt:__tostring()
    -- string value requested
    -- convert the result of f to a string
    return tostring(self.f(self.xs, self.opt))
end

local function flex_array(f)
    return setmetatable({xs=F{}, opt=F{}, f=f}, flex_array_mt)
end

return {
    str = flex_str,
    array = flex_array,
}
