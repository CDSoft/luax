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
-- Global variables
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"

local is_luax =
    (arg[0] and arg[0]:basename():match"^test%-")
    or (arg[-2] == "-l" and arg[-1]:basename():match"^libluax%-")

local luax_packages = F.flatten{
    "argparse",
    "cbor",
    "complex",
    "crypt",
    "F",
    "fs",
    "imath",
    "import",
    "json",
    "linenoise",
    os.getenv"USE_LZ4" and "lz4" or {},
    "lzip",
    "mathx",
    "package",
    "ps",
    "qmath",
    "serpent",
    "sh",
    "sys",
    "term",

    -- lpeg is only found in LuaX
    is_luax and {"lpeg", "re"} or {},

    -- socket is only found in LuaX
    os.getenv"USE_SOCKET" and is_luax and {
        "socket",
        "socket.core",
        "socket.ftp",
        "socket.headers",
        "socket.http",
        "socket.smtp",
        "socket.tp",
        "socket.url",
        package.config:match"^/" and {
            -- available on linux only
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

return function()
    -- Check that LuaX does not pollute the global environment
    local global_variables = F.keys(_G)
    local expected_global_variables = F{
        "_G",
        "_LUAX_VERSION",
        "_LUAX_DATE",
        "_LUAX_COPYRIGHT",
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
    local missing_variables = F.difference(expected_global_variables, global_variables):sort()
    eq(new_variables, F.flatten {
        arg[-3] and arg[-3]:basename() == "lua" and arg[-2] == "-l" and arg[-1] or {},
        arg[-3] == "pandoc lua" and {"PANDOC_API_VERSION","PANDOC_STATE","PANDOC_VERSION","lpeg","pandoc","re"} or {},
        arg[-3] == "pandoc lua" and arg[-2] == "-l" and arg[-1]:basename() or {},
    }:sort())
    eq(missing_variables, {})
end
