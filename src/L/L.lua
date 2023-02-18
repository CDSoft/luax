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

--[[------------------------------------------------------------------------@@@
# L: Pandoc List package

```lua
local L = require "L"
```

`L` is just a shortcut to `Pandoc.List`.

@@@]]

local L = pandoc and pandoc.List

if not L then

    local mt = {__index={}}

    L = {}

    function mt.__concat(l1, l2)
        return setmetatable(F.concat{l1, l2}, mt)
    end

    function mt.__eq(l1, l2)
        return F.ueq(l1, l2)
    end

    function mt.__index:clone()
        return setmetatable(F.clone(self), mt)
    end

    function mt.__index:extend(l)
        for i = 1, #l do
            self[#self+1] = l[i]
        end
    end

    function mt.__index:find(needle, init)
        for i = init or 1, #self do
            if F.ueq(self[i], needle) then
                return self[i], i
            end
        end
    end

    function mt.__index:find_if(pred, init)
        for i = init or 1, #self do
            if pred(self[i]) then
                return self[i], i
            end
        end
    end

    function mt.__index:filter(pred)
        return setmetatable(F.filter(pred, self), mt)
    end

    function mt.__index:includes(needle, init)
        for i = init or 1, #self do
            if F.ueq(self[i], needle) then
                return true
            end
        end
        return false
    end

    function mt.__index:insert(pos, value)
        return table.insert(self, pos, value)
    end

    function mt.__index:map(fn)
        return setmetatable(F.map(fn, self), mt)
    end

    function mt.__index:new(t)
        return setmetatable(t or {}, mt)
    end

    function mt.__index:remove(pos)
        return table.remove(self, pos)
    end

    function mt.__index:sort(comp)
        return table.sort(self, comp)
    end

    setmetatable(L, {
        __index = {
            __call = function(self) return L.new(self) end,
        },
    })

end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return L
