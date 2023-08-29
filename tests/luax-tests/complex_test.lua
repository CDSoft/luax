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
-- complex
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

return function()

    local complex = require "complex"
    local C = complex.new
    local i = complex.I
    local pi = math.pi
    local e = math.exp(1)
    local atan2 = math.atan

    eq(tostring(C(12.1, 42.2)), "12.1+42.2i")
    eq(tostring(C(12.1)), "12.1")
    eq(tostring(C(12.1, -42.2)), "12.1-42.2i")
    eq(tostring(C(-12.1)), "-12.1")
    eq(tostring(C(1.5, 1)), "1.5+i")
    eq(tostring(C(1.5, -1)), "1.5-i")
    eq(tostring(C(0, 42.2)), "42.2i")
    eq(tostring(C(0, -42.2)), "-42.2i")
    eq(tostring(C(0, 1)), "i")
    eq(tostring(C(0, -1)), "-i")

    eq(i, C(0, 1))

    local x, y = 1.2, 2.4
    local z = C(x, y)
    eq(complex.real(z), x)              eq(z:real(), x)
    eq(complex.imag(z), y)              eq(z:imag(), y)
    eq(z, x+i*y)
    eq(complex.conj(z), C(x, -y))       eq(z:conj(), C(x, -y))

    eq(complex.abs(z), (x^2+y^2)^0.5)   eq(z:abs(), (x^2+y^2)^0.5)

    eq(complex.arg(z), atan2(y, x))     eq(z:arg(), atan2(y, x))

    eq(complex.exp(2*pi/3), C(e^(2*pi/3)))      eq(C(2*pi/3):exp(), C(e^(2*pi/3)))
    eq(complex.exp(i*2*pi/3), C(-0.5, 3^0.5/2)) eq(C(0, 2*pi/3):exp(), C(-0.5, 3^0.5/2))

    eq(complex.sqrt(9*C(e)^(2*pi/6)), 3*C(e)^(1*pi/6))  eq((9*C(e)^(2*pi/6)):sqrt(), 3*C(e)^(1*pi/6))
                                                        eq((9*C(e)^(2*pi/6))^2, 81*C(e)^(4*pi/6))

    eq(complex.sin(z), 5.1792919582667+1.9807305433225*i)    eq(z:sin(), 5.1792919582667+1.9807305433225*i)
    eq(complex.cos(z), 2.0136028971671-5.094739280002*i)     eq(z:cos(), 2.0136028971671-5.094739280002*i)
    eq(complex.tan(z), 0.011253606498179 +1.012148292624*i)  eq(z:tan(), 0.011253606498179 +1.012148292624*i)

    eq(complex.sinh(z), -1.1130673173333+1.2230311683876*i)  eq(z:sinh(), -1.1130673173333+1.2230311683876*i)
    eq(complex.cosh(z), -1.3351660363548+1.0195855680458*i)  eq(z:cosh(), -1.3351660363548+1.0195855680458*i)
    eq(complex.tanh(z), 0.96842614279949-0.17648580255556*i) eq(z:tanh(), 0.96842614279949-0.17648580255556*i)

    eq(complex.asin(z), 0.43755116403319+1.7014073225766*i)  eq(z:asin(), 0.43755116403319+1.7014073225766*i)
    eq(complex.acos(z), 1.1332451627617-1.7014073225766*i)   eq(z:acos(), 1.1332451627617-1.7014073225766*i)
    eq(complex.atan(z), 1.3861294979581+0.33529348145986*i)  eq(z:atan(), 1.3861294979581+0.33529348145986*i)

    eq(complex.asinh(z), 1.660002040247+1.077593900351*i)    eq(z:asinh(), 1.660002040247+1.077593900351*i)
    eq(complex.acosh(z), 1.701407322577+1.133245162762*i)    eq(z:acosh(), 1.701407322577+1.133245162762*i)
    eq(complex.atanh(z), 0.150749020891+1.241393308736*i)    eq(z:atanh(), 0.150749020891+1.241393308736*i)

    local z2 = C(-5.1, 3.5)
    eq(complex.pow(z, z2), -7.865467826157e-05-1.099372747984e-04*i)
    eq(z^z2, -7.865467826157e-05-1.099372747984e-04*i)

    eq(complex.log(z), 0.987040513011+1.107148717794*i)
    eq(z:log(), 0.987040513011+1.107148717794*i)

    eq(complex.log(12), C(math.log(12)))
    eq(complex.log(-12), C(math.log(12), pi))

    eq(i*i, complex.new(-1.0))
    eq(2*i*(4-8*i), 16 + 8*i)
    eq(2*i*(7-5*i)*(3-2*i), 58 + 22*i)
    eq(2*(24-23*i)/(4-6*i), 9 + 2*i)
    eq(complex.sqrt(i), 2^0.5/2 + 2^0.5/2*i)
    eq(complex.new(-1):sqrt(), i)
    eq(2*complex.exp(i*3*pi/4), -2^0.5 + 2^0.5*i)

end
