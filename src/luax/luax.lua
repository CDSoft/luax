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

local luax = {}

local F = require "fun"

luax.F = F

local float_format = "%s"
local int_format = "%s"

function luax.precision(len, frac)
    float_format =
        type(len) == "string"                               and len
        or type(len) == "number" and type(frac) == "number" and ("%%%s.%sf"):format(len, frac)
        or type(len) == "number" and frac == nil            and ("%%%sf"):format(len, frac)
        or "%s"
end

function luax.base(b)
    int_format =
        type(b) == "string" and b
        or b == 10          and "%s"
        or b == 16          and "0x%x"
        or b == 8           and "0o%o"
        or "%s"
end

function luax.pretty(x, int_fmt, float_fmt)
    return F.show(x, int_fmt or int_format, float_fmt or float_format)
end

luax.inspect = require "inspect"

function luax.printi(x)
    print(luax.inspect(x))
end

return luax
