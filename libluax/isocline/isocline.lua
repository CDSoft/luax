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
https://github.com/cdsoft/luax
--]]

--@LIB

local isocline = require "_isocline"

local term = require "term"

if not term.isatty(io.stdin) then
    -- readline does not work well on pipes.
    -- Empty lines make readline return nil instead of "".
    -- Some REPL may interpert it as an EOF instead of just an empty line.
    isocline.readline = term.prompt
end

function isocline.printf(fmt, ...)
    return isocline.print(string.format(fmt, ...))
end

return isocline
