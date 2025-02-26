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
-- wget
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"

return function()

    local wget = require "wget"

    do
        local s, msg, err = wget { "https://example.com", "-O -" }
        eq(s:match "Example Domain", "Example Domain")
        eq(msg, nil)
        eq(err, nil)
    end

    do
        local silent_wget = F.partial(wget.request, "-q", "-O -")
        local s, msg, err = silent_wget "https://not-in-this-world.com"
        eq(s, nil)
        eq(msg, "Network failure.")
        eq(err, 4)
    end

end
