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
-- qmath
---------------------------------------------------------------------

return function()

    local qmath = require "qmath"
    local Q = qmath.new

    local pi = math.pi
    local abs = math.abs

    local x = Q(3*5*2*2*2, 2*2*3*3*7)
    local y = Q(37, 3*17)

    eq(x, Q(2*5, 3*7))          eq({x:numer(), x:denom()}, {Q(10), Q(21)})
                                eq({qmath.numer(x), qmath.denom(x)}, {x:numer(), x:denom()})
    eq(tostring(x), "10/21")    eq(qmath.tostring(x), tostring(x))

    eq(x + y, Q(143, 119))      eq(qmath.add(x, y), x+y)
    eq(x / y, Q(170, 259))      eq(qmath.div(x, y), x/y)
    eq(y / x, Q(259, 170))

    eq(x == x, true)
    eq(x == y, false)
    eq(x <= x, true)
    eq(x <= y, true)
    eq(x < x, false)
    eq(x < y, true)
    eq(y == y, true)
    eq(y == x, false)
    eq(y <= y, true)
    eq(y <= x, false)
    eq(y < y, false)
    eq(y < x, false)
    eq(qmath.compare(x, x), 0)
    eq(qmath.compare(x, y), -1)
    eq(qmath.compare(y, x), 1)

    eq(x * y, Q(370, 1071))     eq(qmath.mul(x, y), x*y)

    eq(x ^ 3, Q(1000, 9261))        eq(qmath.pow(x, 3), x^3)
    eq(x ^ 1, x)                    eq(qmath.pow(x, 1), x^1)
    eq(x ^ 0, Q(1))                 eq(qmath.pow(x, 0), x^0)
    eq(x ^ -3, 1/Q(1000, 9261))     eq(qmath.pow(x, -3), x^-3)
    eq(x ^ -1, 1/x)                 eq(qmath.pow(x, -1), x^-1)

    eq(x:sign(), 1)                 eq(qmath.sign(x), 1)
    eq((-x):sign(), -1)             eq(qmath.sign(-x), -1)
    eq((x-x):sign(), 0)             eq(qmath.sign(x-x), 0)

    eq(x - y, Q(-89, 357))          eq(qmath.sub(x, y), x-y)
    eq(y - x, Q(89, 357))           eq(qmath.sub(y, x), y-x)
    eq(x - x, Q(0))                 eq(qmath.sub(x, x), x-x)

    eq(x:todecimal(), "0")          eq(qmath.todecimal(x), "0")
    eq((1/x):todecimal(), "2")      eq(qmath.todecimal(1/x), "2")

    eq(x:tonumber(), 10/21)         eq(qmath.tonumber(x), 10/21)
    eq((1/x):tonumber(), 21/10)     eq(qmath.tonumber(1/x), 21/10)

    eq(qmath.abs(x), x)
    eq(qmath.abs(-x), x)

    eq(qmath.int(x), Q(0))      eq(x:int(), Q(0))
    eq(qmath.int(1/x), Q(2))    eq((1/x):int(), Q(2))
    eq(qmath.inv(x), 1/x)       eq(x:inv(), 1/x)

    eq(qmath.isinteger(x), false)       eq(x:isinteger(), false)
    eq(qmath.isinteger(1/x), false)     eq((1/x):isinteger(), false)
    eq(qmath.isinteger(Q(42)), true)    eq(Q(42):isinteger(), true)

    eq(qmath.iszero(x), false)          eq(x:iszero(), false)
    eq(qmath.iszero(x-x), true)         eq((x-x):iszero(), true)

    eq(qmath.neg(x), -x)    eq(x:neg(), -x)     eq(-x, Q(-10, 21))

    eq(qmath.torat(pi),       Q(355, 113))      assert(abs(qmath.torat(pi)      :tonumber() - pi) < 1e-6)
    eq(qmath.torat(pi, 1e-3), Q(201, 64))       assert(abs(qmath.torat(pi, 1e-3):tonumber() - pi) < 1e-3)
    eq(qmath.torat(pi, 1e-2), Q(22, 7))         assert(abs(qmath.torat(pi, 1e-2):tonumber() - pi) < 1e-2)
    eq(qmath.torat(pi, 1e-9), Q(103993, 33102)) assert(abs(qmath.torat(pi, 1e-9):tonumber() - pi) < 1e-9)

end
