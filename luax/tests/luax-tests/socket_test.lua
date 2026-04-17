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
-- luasocket
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local sys = require "sys"
local ps = require "ps"

local server = os.getenv "HTTP_SERVER"

return function()
    if sys.libc == "gnu" then

        assert(require "socket")
        assert(require "socket.core")
        assert(require "socket.ftp")
        assert(require "socket.headers")
        local http = assert(require "socket.http")
        assert(require "socket.smtp")
        assert(require "socket.tp")
        assert(require "socket.url")
        if sys.os == "linux" then
            assert(require "socket.unix")
            assert(require "socket.serial")
        end
        assert(require "mime")
        assert(require "mime.core")
        assert(require "mbox")
        assert(require "ltn12")

        if server then
            local port = os.getenv "HTTP_PORT_RANGE" + 3
            local httpd<close> = assert(io.popen(server.." "..port))
            ps.sleep(0.1)
            local s, code, _ = http.request("http://localhost:"..port)
            eq(s, "Hello, World!")
            eq(code, 200)
        end

    end
end
