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
https://github.com/cdsoft/luax
--]]

---------------------------------------------------------------------
-- Embeded resources
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"

return function()

    local rc = F.unlines {
        [[This string is embeded]],
        [[  as a "Lua module"]],
        [[    that returns 'this string'.]],
    }

    local test_num = tonumber(os.getenv "TEST_NUM")

    if test_num == 1 then

        eq(require "resource.txt", rc)
        eq(require "resource.txt.lz4" : unlz4(), rc)

    end

end
