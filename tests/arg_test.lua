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
-- arg is built by the runtime
---------------------------------------------------------------------

require "test"

return function()
    local test_num = tonumber(os.getenv "TEST_NUM")

    if test_num == 1 then
        eq(arg, {
            [0] = ".build/test/test-"..sys.arch.."-"..sys.os.."-"..sys.abi,
            "Lua", "is", "great"
        })
        assert(sys.abi == "gnu")
        assert(not pandoc)
        assert(crypt.sha256)
        assert(not crypt.sha1)

    elseif test_num == 2 then
        eq(arg, {
            [-3] = ".build/tmp/lua",
            [-2] = "-l", [-1] = "libluax-"..sys.arch.."-"..sys.os.."-"..sys.abi,
            [0] = "tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.abi == "gnu")
        assert(not pandoc)
        assert(crypt.sha256)
        assert(not crypt.sha1)

    elseif test_num == 3 then
        eq(arg, {
            [-3] = ".build/tmp/lua",
            [-2] = "-l", [-1] = "luax",
            [0] = "tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.abi == "lua")
        assert(not pandoc)
        assert(not crypt.sha256)
        assert(not crypt.sha1)

    elseif test_num == 4 then
        eq(arg, {
            [-4] = "lua",
            [-3] = "-l", [-2] = "luax",
            [-1] = ".build/bin/luax-lua",
            [0] = "tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.abi == "lua")
        assert(not pandoc)
        assert(not crypt.sha256)
        assert(not crypt.sha1)

    elseif test_num == 5 then
        eq(arg, {
            [-3] = "pandoc lua",
            [-2] = "-l", [-1] = "luax",
            [0] = "tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.abi == "lua")
        assert(pandoc)
        assert(not crypt.sha256)
        assert(crypt.sha1)

    elseif test_num == 6 then
        eq(arg, {
            [-3] = "pandoc lua",
            [-2] = "-l", [-1] = "libluax-"..sys.arch.."-"..sys.os.."-"..sys.abi,
            [0] = "tests/main.lua",
            "Lua", "is", "great"
        })
        assert(sys.abi == "gnu")
        assert(pandoc)
        assert(crypt.sha256)
        assert(crypt.sha1)

    else
        error("Invalid test number: "..test_num)
    end
end
