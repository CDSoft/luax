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

--[[------------------------------------------------------------------------@@@
# Interpolation of strings

```lua
local I = require "I"
```
@@@]]

local I = {}

local M = require "Map"

local function interpolate(s, t)
    return (s:gsub("%$(%b())", function(x)
        local y = ((assert(load("return "..x, nil, "t", t)))())
        if type(y) == "table" then y = tostring(y) end
        return y
    end))
end

local function Interpolator(t)
    return function(x)
        if type(x) == "table" then return Interpolator(M.union(x, t)) end
        if type(x) == "string" then return interpolate(x, t) end
    end
end

--[[@@@
```lua
I(t)
```
> returns a string interpolator that replaces `$(...)` by
  the value of `...` in the environment defined by the table `t`. An interpolator
  can be given another table to build a new interpolator with new values.
@@@]]

return setmetatable({}, {
    __call = function(_, t) return Interpolator(M.clone(t)) end,
})
