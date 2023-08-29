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

local test = require "test"
local startswith = test.startswith

return function()
    local lib = require "lib"
    local traceback = lib.hello "World":gsub("\t", "    ")
    local expected_traceback = [[
@tests/luax-tests/lib.lua says: Hello World
Traceback test
stack traceback:
    tests/luax-tests/lib.lua:25: in function 'lib.hello'
    tests/luax-tests/require_test.lua:30: in function 'require_test']]

    startswith(traceback, expected_traceback)

end
