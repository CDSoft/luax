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
-- sh
---------------------------------------------------------------------

local sh = require "sh"

local fs = require "fs"

return function()

    do
        local ok, exit, ret = sh.run{"exit", 0}
        eq(ok, true)
        eq(exit, "exit")
        eq(ret, 0)
    end

    do
        local ok, exit, ret = sh.run{"exit", 1}
        eq(ok, nil)
        eq(exit, "exit")
        eq(ret, 1)
    end

    eq(sh.read{"echo", "Hello"}, "Hello\n")
    eq(sh.read{"true"}, "")
    eq(sh.read"true", "")

    do
        local ok, exit, ret = sh.read{"exit", 42}
        eq(ok, nil)
        eq(exit, "exit")
        eq(ret, 42)
    end

    eq(fs.with_tmpfile(function(tmp)
        local res = {sh.write{"cat", "|", "tr", "a-z", "A-Z", ">", tmp} "Hello"}
        local content = io.open(tmp):read("a")
        return {res, content}
    end), {{true, "exit", 0}, "HELLO"})
end
