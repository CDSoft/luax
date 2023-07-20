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
local sys = require "sys"

local is_luax =
    (arg[0] and fs.basename(arg[0]):match"^test%-")
    or (arg[-2] == "-l" and fs.basename(arg[-1]):match"^libluax%-")

local luax_packages = F.flatten{
    "F",
    "L",
    "argparse",
    "complex",
    "crypt",
    "fs",
    "imath",
    "inspect",
    "lz4",
    "mathx",
    "ps",
    "qmath",
    "serpent",
    "sh",
    "sys",
    "term",

    -- lpeg is only found in LuaX
    is_luax and {"lpeg", "re"} or {},

    -- socket is only found in LuaX
    is_luax and {
        "socket",
        "socket.core",
        "socket.ftp",
        "socket.headers",
        "socket.http",
        "socket.smtp",
        "socket.tp",
        "socket.url",
        sys.os == "linux" and {
            "socket.unix",
            "socket.serial",
        } or {},
        "mime",
        "mime.core",
        "mbox",
        "ltn12",
    } or {},
}

-- load all LuaX packages to check they won't interfere with the Lua global environment
luax_packages:foreach(require)

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
