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
-- luasocket
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"
local sys = require "sys"

return function()
    if sys.libc == "gnu" then

        local socket = assert(require "socket")
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

        local t = assert(http.request"http://time.cdelord.fr/time.php")
        assert(math.abs(t - os.time() ) < 5*60)
        assert(math.abs(t - socket.gettime() ) < 5*60)

        if os.getenv "USE_SSL" then

            assert(require "ssl")
            assert(require "ssl.https")
            assert(require "ssl.context")
            assert(require "ssl.config")
            assert(require "ssl.core")
            assert(require "ssl.x509")

            eq(F.take(2, {http.request"https://cdelord.fr/ssltest.txt"}), {"SSL test passed!\n", 200})

        end

    end
end
