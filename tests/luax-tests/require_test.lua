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

---------------------------------------------------------------------
-- embeded modules can be loaded with require
---------------------------------------------------------------------

local test = require "test"
local startswith = test.startswith

local F = require "F"

return function()
    local lib = require "lib"
    local traceback = lib.hello "World":gsub("\t", "    ")
    local expected_traceback = [[
@$test-luax:tests/luax-tests/lib.lua says: Hello World
Traceback test
stack traceback:
    $test-luax:tests/luax-tests/lib.lua:25: in function 'lib.hello'
    $test-luax:tests/luax-tests/require_test.lua:32: in function 'require_test']]

    local test_num = tonumber(os.getenv "TEST_NUM")
    if F.elem(test_num, {2, 3, 4, 5}) then
        expected_traceback = expected_traceback : gsub("%$test%-luax:", "")
    end

    if os.getenv "IS_COMPILED" == "true" then
        expected_traceback = expected_traceback : gsub("%$test%-luax:", "$"..(os.getenv"EXE_NAME"):basename()..":")
    end

    startswith(traceback, expected_traceback)

end
