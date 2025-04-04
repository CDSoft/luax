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

---------------------------------------------------------------------
-- curl
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"

return function()

    local curl = require "curl"

    do
        local s, msg, err = curl "https://example.com"
        eq(s:match "Example Domain", "Example Domain")
        eq(msg, nil)
        eq(err, nil)
    end

    do
        local silent_curl = F.partial(curl.request, "-s")
        local s, msg, err = silent_curl "https://not-in-this-world.com"
        eq(s, nil)
        eq(msg, "Could not resolve host. The given remote host could not be resolved.")
        eq(err, 6)
    end

end
