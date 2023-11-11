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

--@LIB
local _, sys = pcall(require, "_sys")
sys = _ and sys

if not sys then

    sys = {}

    local sh = require "sh"

    sys.arch = pandoc and pandoc.system.arch
    sys.os = pandoc and pandoc.system.os
    sys.abi = "lua"

    setmetatable(sys, {
        __index = function(_, param)
            if param == "os" then
                local os = sh.read("uname", "-s"):trim() ---@diagnostic disable-line: undefined-field
                os =   os == "Linux" and "linux"
                    or os == "Darwin" and "macos"
                    or os:match "^MINGW" and "windows"
                    or "unknown"
                sys.os = os
                return os
            elseif param == "arch" then
                local arch = sh.read("uname", "-m"):trim() ---@diagnostic disable-line: undefined-field
                arch =   arch:match "^i[3-6]86" and "x86"
                      or arch
                sys.arch = arch
                return arch
            end
        end,
    })

end

return sys
