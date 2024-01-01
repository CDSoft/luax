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
-- shell_env
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"
local fs = require "fs"
local sys = require "sys"

return function()
    local test_num = tonumber(os.getenv "TEST_NUM")
    if F.elem(test_num, {1}) then
        local shell_env = require "shell_env"
        local libext = F.case(sys.os) { linux="so",  macos="dylib", windows="dll" }

        local cwd = fs.getcwd()

        eq(shell_env(os.getenv"LUAX"),
F.I{CWD=cwd, sys=sys, libext=libext}[[
export PATH="$(CWD)/.build/bin:$PATH";
export LUA_PATH="$(CWD)/.build/lib/?.lua;$LUA_PATH";
export LUA_CPATH="$(CWD)/.build/lib/?-$(sys.arch)-$(sys.os)-$(sys.abi).$(libext);$LUA_CPATH";
]])

        eq(shell_env(os.getenv"LUAX", {}),
F.I{CWD=cwd, sys=sys, libext=libext}[[
export PATH="$(CWD)/.build/bin:$PATH";
export LUA_PATH="$(CWD)/.build/lib/?.lua;$LUA_PATH";
export LUA_CPATH="$(CWD)/.build/lib/?-$(sys.arch)-$(sys.os)-$(sys.abi).$(libext);$LUA_CPATH";
]])

        fs.with_tmpdir(function(tmp)
            local script = tmp/"script.lua"
            fs.write(script, [[
                VAR_A = "this is the first variable"
                VAR_B = "this is the second variable"
                STRUCT = { X=1, Y=2, Z={a=10, b=20},
                    ARRAY = {"a", "b", "c"},
                }
                ARRAY = {"d", "e", "f",
                    STRUCT = { X=100, Y=200, Z={a=1000, b=2000} },
                }
            ]])
            eq(shell_env(os.getenv"LUAX", {script}),
[===[
export ARRAY_1='d';
export ARRAY_2='e';
export ARRAY_3='f';
export ARRAY_STRUCT_X='100';
export ARRAY_STRUCT_Y='200';
export ARRAY_STRUCT_Z_A='1000';
export ARRAY_STRUCT_Z_B='2000';
export STRUCT_ARRAY_1='a';
export STRUCT_ARRAY_2='b';
export STRUCT_ARRAY_3='c';
export STRUCT_X='1';
export STRUCT_Y='2';
export STRUCT_Z_A='10';
export STRUCT_Z_B='20';
export VAR_A='this is the first variable';
export VAR_B='this is the second variable';
]===]
)
        end)

    end
end
