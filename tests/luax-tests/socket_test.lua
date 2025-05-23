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

return function()
    if not os.getenv"USE_SOCKET" then return end

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

        do
            local s, code, _ = http.request"http://example.com"
            eq(s:match "Example Domain", "Example Domain")
            eq(code, 200)
        end

        if os.getenv "USE_SSL" then

            assert(require "ssl")
            assert(require "ssl.https")
            assert(require "ssl.context")
            assert(require "ssl.config")
            assert(require "ssl.core")
            assert(require "ssl.x509")

            local s, code, _ = http.request"https://example.com"
            eq(s:match "Example Domain", "Example Domain")
            eq(code, 200)

        end

    end
end
