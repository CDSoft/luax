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

--@LOAD
local _, linenoise = pcall(require, "_linenoise")
linenoise = _ and linenoise

if not linenoise then

    linenoise = {}

    function linenoise.read(prompt)
        io.stdout:write(prompt)
        io.stdout:flush()
        return io.stdin:read "l"
    end

    linenoise.read_mask = linenoise.read

    linenoise.add = F.const()
    linenoise.set_len = F.const()
    linenoise.save = F.const()
    linenoise.load = F.const()
    linenoise.multi_line = F.const()
    linenoise.mask = F.const()

    function linenoise.clear()
        io.stdout:write "\x1b[1;1H\x1b[2J"
    end

end

return linenoise
