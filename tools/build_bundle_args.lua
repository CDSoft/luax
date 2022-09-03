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

local autoexec = {
    ["src/crypt/cryptx.lua"]    = true,
    ["src/fs/fsx.lua"]          = true,
    ["src/std/stringx.lua"]     = true,
}

local submodule = {
    ["src/socket/luasocket/ftp.lua"]        = "socket.ftp",
    ["src/socket/luasocket/headers.lua"]    = "socket.headers",
    ["src/socket/luasocket/http.lua"]       = "socket.http",
    ["src/socket/luasocket/smtp.lua"]       = "socket.smtp",
    ["src/socket/luasocket/tp.lua"]         = "socket.tp",
    ["src/socket/luasocket/url.lua"]        = "socket.url",
}

local function emit(x) io.stdout:write(x, " ") end

for i = 1, #arg do

    if autoexec[arg[i]] then
        emit "-autoexec"
    end

    local submodule_name = submodule[arg[i]]
    if submodule_name then
        arg[i] = arg[i]..":"..submodule_name
    end

    emit(arg[i])

end
