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
-- wget
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"
local ps = require "ps"

local server = os.getenv "HTTP_SERVER"

return function()

    local wget = require "wget"

    if server then
        local port = os.getenv "HTTP_PORT_RANGE" + 2
        local httpd<close> = assert(io.popen(server.." "..port))
        ps.sleep(0.1)
        local s, msg, err = wget { "http://localhost:"..port, "-O -" }
        eq(s:match "Hello, World!", "Hello, World!")
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
