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

if not _LUAX_VERSION then return function() end end

return function()
    local complex = require "complex"
    local i = complex.I
    local pi = math.pi

    eq(i*i, complex.new(-1.0))
    eq(2*i*(4-8*i), 16 + 8*i)
    eq(2*i*(7-5*i)*(3-2*i), 58 + 22*i)
    eq(2*(24-23*i)/(4-6*i), 9 + 2*i)
    eq(complex.sqrt(i), 2^0.5/2 + 2^0.5/2*i)
    eq(complex.new(-1):sqrt(), i)
    eq(2*complex.exp(i*3*pi/4), -2^0.5 + 2^0.5*i)
end
