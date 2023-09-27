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
--
local _, linenoise = pcall(require, "_linenoise")
linenoise = _ and linenoise

if not linenoise then

    local F = require "F"
    local term = require "term"

    local nop = F.const()

    linenoise = {}

    linenoise.read = term.prompt
    linenoise.read_mask = linenoise.read

    linenoise.add = nop
    linenoise.set_len = nop
    linenoise.save = nop
    linenoise.load = nop
    linenoise.multi_line = nop
    linenoise.mask = nop

    linenoise.clear = term.clear

end

return linenoise
