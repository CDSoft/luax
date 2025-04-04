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

--@LIB
local qmath = require "_qmath"

--[[@@@
## qmath additional functions
@@@]]

--[[@@@
```lua
q = qmath.torat(x, [eps])
```
approximates a floating point number `x` with a rational value.
The rational number `q` is an approximation of `x` such that $|q - x| < eps$.
The default `eps` value is $10^{-6}$.
@@@]]

local rat = qmath.new
local floor = math.floor
local abs = math.abs

local function frac(a)
    local q = rat(a[#a])
    for i = #a-1, 1, -1 do
        q = a[i] + 1/q
    end
    return q
end

function qmath.torat(x, eps)
    eps = eps or 1e-6
    local x0 = x
    local a = {floor(x)}
    x = x - a[1]
    local q = frac(a)
    while abs(x0 - q:tonumber()) > eps and #a < 64 do
        local y = 1/x
        a[#a+1] = floor(y)
        x = y - a[#a]
        q = frac(a)
    end
    return q
end

return qmath
