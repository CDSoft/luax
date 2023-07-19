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
-- Global variables
---------------------------------------------------------------------

local F = require "F"
local fs = require "fs"

-- load test.lua in a local environment
local test = F.clone(_G)
assert(loadfile("tests/test.lua", "t", test))()

return function()
    -- Check that LuaX does not pollute the global environment
    local global_variables = F.keys(_G)
    local expected_global_variables = F{
        "_G",
        "_LUAX_VERSION",
        "_VERSION",
        "arg",
        "assert",
        "collectgarbage",
        "coroutine",
        "debug",
        "dofile",
        "error",
        "getmetatable",
        "io",
        "ipairs",
        "load",
        "loadfile",
        "math",
        "next",
        "os",
        "package",
        "pairs",
        "pcall",
        "print",
        "rawequal",
        "rawget",
        "rawlen",
        "rawset",
        "require",
        "select",
        "setmetatable",
        "string",
        "table",
        "tonumber",
        "tostring",
        "type",
        "utf8",
        "warn",
        "xpcall",
    }
    local new_variables = F.difference(global_variables, expected_global_variables):sort()
    test.eq(new_variables, F.flatten {
        arg[-3] and fs.basename(arg[-3]) == "lua" and arg[-2] == "-l" and arg[-1] or {},
        arg[-3] == "pandoc lua" and {"PANDOC_API_VERSION","PANDOC_STATE","PANDOC_VERSION","lpeg","pandoc","re"} or {},
        arg[-3] == "pandoc lua" and arg[-2] == "-l" and fs.basename(arg[-1]) or {},
    }:sort())
end
