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

--@LOAD
local _, qmath = pcall(require, "_qmath")
qmath = _ and qmath

if not qmath then

    qmath = {}
    local mt = {__index={}}

    local imath = require "imath"
    local Z = imath.new
    local gcd = imath.gcd

    local function rat(num, den)
        if not den then
            if type(num) == "table" and num.num and num.den then return num end
            den = 1
        end
        num, den = Z(num), Z(den)
        assert(den ~= 0, "(qmath) result undefined")
        if den < 0 then num, den = -num, -den end
        if num:iszero() then
            den = Z(1)
        else
            local d = gcd(num, den)
            num, den = num/d, den/d
        end
        return setmetatable({num=num, den=den}, mt)
    end

    local rat_zero = rat(0)
    local rat_one = rat(1)

    local function rat_tostring(r)
        if r.den:isone() then return tostring(r.num) end
        return ("%s/%s"):format(r.num, r.den)
    end

    local function compare(a, b)
        return (a.num*b.den):compare(b.num*a.den)
    end

    mt.__add = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den + b.num*a.den, a.den*b.den) end
    mt.__div = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den, a.den*b.num) end
    mt.__eq = function(a, b) a, b = rat(a), rat(b); return compare(a, b) == 0 end
    mt.__le = function(a, b) a, b = rat(a), rat(b); return compare(a, b) <= 0 end
    mt.__lt = function(a, b) a, b = rat(a), rat(b); return compare(a, b) < 0 end
    mt.__mul = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.num, a.den*b.den) end
    mt.__pow = function(a, b)
        if type(b) == "number" and math.type(b) == "float" then
            error("bad argument #2 to 'pow' (number has no integer representation)")
        end
        if b == 0 then return rat_one end
        if a == 0 then return rat_zero end
        if a == 1 then return rat_one end
        if b < 0 then
            b = -b
            return rat(a.den^b, a.num^b)
        end
        return rat(a.num^b, a.den^b)
    end
    mt.__sub = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den - b.num*a.den, a.den*b.den) end
    mt.__tostring = rat_tostring
    mt.__unm = function(a) return rat(-a.num, a.den) end
    mt.__index.abs = function(a) return rat(a.num:abs(), a.den) end
    mt.__index.add = mt.__add
    mt.__index.compare = function(a, b) return compare(rat(a), rat(b)) end
    mt.__index.denom = function(a) return rat(a.den) end
    mt.__index.div = mt.__div
    mt.__index.int = function(a) return rat(a.num / a.den) end
    mt.__index.inv = function(a) return rat(a.den, a.num) end
    mt.__index.isinteger = function(a) return a.den:isone() end
    mt.__index.iszero = function(a) return a.num:iszero() end
    mt.__index.mul = mt.__mul
    mt.__index.neg = mt.__unm
    mt.__index.numer = function(a) return rat(a.num) end
    mt.__index.pow = mt.__pow
    mt.__index.sign = function(a) return compare(a, rat_zero) end
    mt.__index.sub = mt.__sub
    mt.__index.todecimal = function(a) return tostring(a.num // a.den) end
    mt.__index.tonumber = function(a) return a.num:tonumber()/a.den:tonumber() end

    qmath.abs = function(a) return rat(a):abs() end
    qmath.add = function(a, b) return rat(a) + rat(b) end
    qmath.compare = function(a, b) return rat(a):compare(rat(b)) end
    qmath.denom = function(a) return rat(a):denom() end
    qmath.div = function(a, b) return rat(a) / rat(b) end
    qmath.int = function(a) return rat(a):int() end
    qmath.inv = function(a) return rat(a):inv() end
    qmath.isinteger = function(a) return rat(a):isinteger() end
    qmath.iszero = function(a) return rat(a):iszero() end
    qmath.mul = function(a, b) return rat(a) * rat(b) end
    qmath.neg = function(a) return -rat(a) end
    qmath.new = rat
    qmath.numer = function(a) return rat(a):numer() end
    qmath.pow = function(a, b) return rat(a) ^ b end
    qmath.sign = function(a) return rat(a):sign() end
    qmath.sub = function(a, b) return rat(a) - rat(b) end
    qmath.todecimal = function(a) return rat(a):todecimal() end
    qmath.tonumber = function(a) return rat(a):tonumber() end
    qmath.tostring = mt.__tostring

end

local rat = qmath.new
local floor = math.floor
local abs = math.abs

function qmath.torat(n, eps)
    if n == 0 then return rat(0, 1) end
    eps = eps or 1e-6
    local absn = abs(n)
    local num, den
    if absn >= 1 then
        num, den = floor(absn), 1
    else
        num, den = 1, floor(1/absn)
    end
    local r = num / den
    while abs(absn-r) > eps do
        if r < absn then
            num = num + 1
        else
            den = den + 1
            num = floor(absn * den)
        end
        r = num / den
    end
    if n < 0 then num = -num end
    return rat(num, den)
end

return qmath
