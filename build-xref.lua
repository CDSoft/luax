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

local has = require "build-detection"

-------------------------------------------------------------------------------
section "Cross references"
-------------------------------------------------------------------------------

if has.req then

    acc(xref) {
        build "$builddir/xref.txt" {
            command = "req -g -f -o $out || req -g -f",
            implicit_in = { compile, test, doc, ls "build*.lua", ls "tools/**" },
            pool = "console",
        }
    }

end
