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

--[[@@@
* `atexit(func)`: execute `func` when the whole output is computed, before actually writing the output.
@@@]]

local F = require "F"

local _functions = F{}

return setmetatable({}, {
    __call = function(_, func)
        _functions[#_functions+1] = func
    end,
    __index = {
        run = function(_)
            while #_functions > 0 do
                local fs = _functions
                _functions = F{}
                fs:foreach(F.call)
            end
        end,
    },
})
