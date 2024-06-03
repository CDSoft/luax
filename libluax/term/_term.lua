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

-- Pure Lua implementation of term.c

local term = {}

local sh = require "sh"

local function file_descriptor(fd, def)
    if fd == nil then return def end
    if fd == io.stdin then return 0 end
    if fd == io.stdout then return 1 end
    if fd == io.stderr then return 2 end
    return fd
end

local _isatty = {}

function term.isatty(fd)
    fd = file_descriptor(fd, 0)
    _isatty[fd] = _isatty[fd] or sh.run("test -t", fd)~=nil
    return _isatty[fd]
end

function term.size(fd)
    fd = file_descriptor(fd, 1)
    local size = fd==0 and sh.read("stty", "size") or sh.read("tput lines; tput cols")
    return size and size
        : words()
        : map(tonumber):unpack()
end

return term
