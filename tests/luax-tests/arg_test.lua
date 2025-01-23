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

---------------------------------------------------------------------
-- arg is built by the runtime
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local sys = require "sys"
local fs = require "fs"

return function()
    local test_num = tonumber(os.getenv "TEST_NUM")

    if test_num == 1 then
        if os.getenv "IS_COMPILED" == "true" then
            eq(arg, {
                [0] = ".build/test/test-compiled-"..os.getenv "TEST_CASE",
                "Lua", "is", "great"
            })
            assert(sys.libc == os.getenv"LIBC")
            assert(not pandoc)
        else
            eq(arg, {
                [-2] = "luax",
                [-1] = "--",
                [0] = ".build/test/test-luax",
                "Lua", "is", "great"
            })
            eq(fs.findpath(arg[-2]), ".build/bin/luax")
            assert(sys.libc == "gnu")
            assert(not pandoc)
        end

    elseif test_num == 2 then
        eq(arg, {
            [-3] = ".build/bin/lua",
            [-2] = "-l", [-1] = "libluax",
            [0] = "tests/luax-tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.libc == "gnu")
        assert(not pandoc)

    elseif test_num == 3 then
        eq(arg, {
            [-3] = ".build/bin/lua",
            [-2] = "-l", [-1] = "luax",
            [0] = "tests/luax-tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.libc == "lua")
        assert(not pandoc)

    elseif test_num == 4 then
        eq(arg, {
            [-2] = "lua",
            [-1] = ".build/bin/luax.lua",
            [0] = "tests/luax-tests/main.lua",
            "Lua", "is", "great"
        })
        eq(fs.findpath(arg[-2]), ".build/bin/lua")
        assert(sys.libc == "lua")
        assert(not pandoc)

    elseif test_num == 5 then
        eq(arg, {
            [-3] = "pandoc lua",
            [-2] = "-l", [-1] = "luax",
            [0] = "tests/luax-tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.libc == "lua")
        assert(pandoc)

    elseif test_num == 6 then
        eq(arg, {
            [-3] = "pandoc lua",
            [-2] = "-l", [-1] = "libluax",
            [0] = "tests/luax-tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.libc == "gnu")
        assert(pandoc)

    else
        error("Invalid test number: "..test_num)
    end
end
