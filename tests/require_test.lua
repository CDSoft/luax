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
-- embeded modules can be loaded with require
---------------------------------------------------------------------

return function()
    local lib = require "lib"
    local traceback = lib.hello "World":gsub("\t", "    ")
    local expected_traceback = _LUAX_VERSION
        and [[
@lib.lua says: Hello World
Traceback test
stack traceback:
    lib.lua:25: in function 'lib.hello'
    require_test.lua:27: in function 'require_test'
    main.lua:26: in main chunk]]
        or [[
@tests/lib.lua says: Hello World
Traceback test
stack traceback:
    tests/lib.lua:25: in function 'lib.hello'
    tests/require_test.lua:27: in function 'require_test'
    tests/main.lua:26: in main chunk]]
    eq(traceback, expected_traceback)
end
