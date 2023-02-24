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
-- arg is built by the runtime
---------------------------------------------------------------------

require "test"

return function()
    -- TODO: how to check arg[0]?
    eq(arg, {
        [-4] = arg[-4],
        [-3] = arg[-3],
        [-2] = arg[-2],
        [-1] = arg[-1],
        [0] = arg[0],
        "Lua", "is", "great"
    })
end
