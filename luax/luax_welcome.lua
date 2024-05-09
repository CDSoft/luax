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

local sys = require "sys"
local F = require "F"
local term = require "term"

local I = (F.I % "%%{}")(_G){sys=sys}

local welcome = I[===[
 _               __  __  |  https://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version %{_LUAX_VERSION} (%{_LUAX_DATE})
| |__| |_| | (_| |/  \   |  Powered by %{_VERSION}
|_____\__,_|\__,_/_/\_\  |%{PANDOC_VERSION and "  and Pandoc "..tostring(PANDOC_VERSION) or ""}
                         |  %{sys.os:cap()} %{sys.arch} %{sys.libc}
]===]

local welcome_already_printed = false

local function print_welcome()
    if welcome_already_printed then return end
    if term.isatty() then
        print(welcome)
    end
    welcome_already_printed = true
end

return print_welcome
