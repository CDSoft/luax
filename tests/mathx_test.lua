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

---------------------------------------------------------------------
-- mathx
---------------------------------------------------------------------

local COSH = {
    [0] = 1.000000000000000e+00,
    [1] = 1.543080634815244e+00,
    [2] = 3.762195691083631e+00,
    [3] = 1.006766199577777e+01,
    [4] = 2.730823283601649e+01,
    [5] = 7.420994852478785e+01,
}

local SINH = {
    [0] = 0,
    [1] = 1.175201193643801e+00,
    [2] = 3.626860407847019e+00,
    [3] = 1.001787492740990e+01,
    [4] = 2.728991719712775e+01,
    [5] = 7.420321057778875e+01,
}

local TANH = {
    [0] = 0,
    [1] = 0.761594155955765,
    [2] = 0.964027580075817,
    [3] = 0.995054753686730,
    [4] = 0.999329299739067,
    [5] = 0.999909204262595,
}

local ACOSH = {
    [1] = 0,
    [2] = 1.316957896924817,
    [3] = 1.762747174039086,
    [4] = 2.063437068895561,
    [5] = 2.292431669561178,
}

local ASINH = {
    [ 0] = 0,
    [ 1] = 0.881373587019543,
    [ 2] = 1.443635475178810,
    [ 3] = 1.818446459232067,
    [ 4] = 2.094712547261101,
    [ 5] = 2.312438341272752,
}

local ATANH = {
    [0.00] = 0,
    [0.25] = 0.255412811882995,
    [0.50] = 0.549306144334055,
    [0.75] = 0.972955074527657,
    [0.90] = 1.472219489583220,
    [0.99] = 2.646652412362246,
}

local function cbrt(x)
    if x < 0 then return -(-x)^(1/3) end
    return x^(1/3)
end

return function()

    local mathx = require "mathx"

    for x = -10, 10, 0.25 do
        eq(mathx.fabs(x), math.abs(x))
        eq(mathx.cbrt(x), cbrt(x))
        eq(mathx.ceil(x), math.ceil(x))
        for y = -1, 1, 0.25 do
            eq(mathx.copysign(x, y),
                y > 0 and math.abs(x)
                or y < 0 and -math.abs(x)
                or math.abs(x)
            )
        end
        eq(mathx.cos(x), math.cos(x))
        eq(mathx.deg(x), math.deg(x))
        eq(mathx.exp(x), math.exp(x))
        eq(mathx.exp2(x), 2^x)
        for y = -10, 10, 0.25 do
            eq(mathx.fdim(x, y), math.max(x-y, 0))
            for z = -1, 1, 0.25 do
                eq(mathx.fma(x, y, z), x*y + z)
            end
            eq(mathx.fmax(x, y), math.max(x, y))
            eq(mathx.fmin(x, y), math.min(x, y))
            if y ~= 0 then
                eq(mathx.fmod(x, y), math.fmod(x, y))
            end
            eq(mathx.hypot(x, y), (x^2+y^2)^0.5)
            if x > 0 then
                eq(mathx.pow(x, y), x^y)
            elseif x == 0 and y > 0 then
                eq(mathx.pow(x, y), 0)
            elseif x == 0 and y == 0 then
                eq(mathx.pow(x, y), 1)
            end
        end
        eq(mathx.floor(x), math.floor(x))
        do
            local m, e = mathx.frexp(x)
            eq(m*2^e, x)
        end
        eq(mathx.isfinite(x), true)
        eq(mathx.isfinite(1/0), false)
        eq(mathx.isinf(x), false)
        eq(mathx.isinf(1/0), true)
        eq(mathx.isnan(x), false)
        eq(mathx.isnan(0/0), true)
        for y = -5, 5 do
            eq(mathx.ldexp(x, y), x*2^y)
        end
        if x > 0 then
            eq(mathx.log(x), math.log(x))
            for y = 2, 10 do
                eq(mathx.log(x, y), math.log(x, y))
            end
            eq(mathx.log10(x), math.log(x, 10))
            eq(mathx.log1p(x), math.log(1+x))
            eq(mathx.log2(x), math.log(x, 2))
        end
        eq(mathx.modf(x), math.modf(x))
        eq(mathx.nearbyint(x), (function()
            local m = math.modf(x)
            if m%2 == 0 then
                return x < 0 and math.floor(x+0.5) or math.ceil(x-0.5)
            else
                return x >= 0 and math.floor(x+0.5) or math.ceil(x-0.5)
            end
        end)())
        for y = -5, 5 do
            eq(("%q"):format(mathx.nextafter(x, y)), ("%q"):format((function()
                if x == y then return x end
                if x == 0 then
                    if y > 0 then return 0x0.0000000000001p-1022 end
                    if y < 0 then return -0x0.0000000000001p-1022 end
                end
                local i = string.unpack("i8", string.pack("d", x))
                i = i + (  y > x and x < 0 and -1
                        or y < x and x < 0 and 1
                        or y > x and x > 0 and 1
                        or y < x and x > 0 and -1
                        )
                return string.unpack("d", string.pack("i8", i))
            end)()))
        end
        eq(mathx.round(x), x >= 0 and math.floor(x+0.5) or math.ceil(x-0.5))
        eq(mathx.rad(x), math.rad(x))
        eq(mathx.sin(x), math.sin(x))
        if x >= 0 then
            eq(mathx.sqrt(x), math.sqrt(x))
        end
        eq(mathx.tan(x), math.tan(x))
        eq(mathx.trunc(x), x >= 0 and math.floor(x) or math.ceil(x))
    end
    for x = -2, 2, 0.1 do
        eq(mathx.expm1(x), math.exp(x)-1)
    end
    for x = -1, 1, 0.25 do
        eq(mathx.acos(x), math.acos(x))
        eq(mathx.asin(x), math.asin(x))
        eq(mathx.atan(x), math.atan(x))
        for y = -1, 1, 0.25 do
            eq(mathx.atan2(y, x), math.atan(y, x))
        end
    end

    for x, y in pairs(ACOSH) do eq(mathx.acosh(x), y) end
    for x, y in pairs(ASINH) do
        eq(mathx.asinh(x), y)
        eq(mathx.asinh(-x), -y)
    end
    for x, y in pairs(ATANH) do
        eq(mathx.atanh(x), y)
        eq(mathx.atanh(-x), -y)
    end
    for x, y in pairs(COSH) do
        eq(mathx.cosh(x), y)
        eq(mathx.cosh(-x), y)
    end
    for x, y in pairs(SINH) do
        eq(mathx.sinh(x), y)
        eq(mathx.sinh(-x), -y)
    end
    for x, y in pairs(TANH) do
        eq(mathx.tanh(x), y)
        eq(mathx.tanh(-x), -y)
    end

end
