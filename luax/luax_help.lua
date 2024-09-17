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

--@LIB

local F = require "F"

local arg0 = arg[0]

local function usage()
    local I = (F.I % "%%{}") (F.patch(require "luax_config", {
        arg0 = arg0,
        lua_init = { "LUA_INIT_".._VERSION:words()[2]:gsub("%.", "_"), "LUA_INIT" },
    }))
    return (I[===[
usage: %{arg0:basename()} [cmd] [options]

Commands:
  "help"    (or "-h")   Show this help
  "version" (or "-v")   Show LuaX version
  "run"     (or none)   Run scripts
  "compile" (or "c")    Compile scripts
  "env"                 Set LuaX environment variables

"run" options:
  -e stat         execute string 'stat'
  -i              enter interactive mode after executing 'script'
  -l name         require library 'name' into global 'name'
  -l g=name       require library 'name' into global 'g'
  -l _=name       require library 'name' (no global variable)
  -v              show version information
  --              stop handling options
  -               stop handling options and execute stdin
  script [args]   script to execute

"compile" options:
  -t target       name of the targetted platform
  -t list         list available targets
  -o file         name the executable file to create
  -b              compile to Lua bytecode
  -s              emit bytecode without debug information
  -k key          script encryption key
  -q              quiet compilation (error messages only)
  scripts         scripts to compile

Environment variables:

  %{lua_init[1]}, %{lua_init[2]}
                code executed before handling command line
                options and scripts (not in compilation
                mode). When %{lua_init[1]} is defined,
                %{lua_init[2]} is ignored.

  PATH          PATH shall contain the bin directory where
                LuaX is installed

  LUA_PATH      LUA_PATH shall point to the lib directory
                where the Lua implementation of LuaX
                lbraries are installed

  LUA_CPATH     LUA_CPATH shall point to the lib directory
                where LuaX shared libraries are installed

PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
with "luax env".
E.g.: eval $(luax env)

"luax env" can also generate shell variables from a script.
E.g.: eval $(luax env script.lua)
]===]):trim()
end

local function print_usage()
    local welcome = require "luax_welcome"
    welcome()
    print(usage())
end

local function print_error(fmt, ...)
    print("")
    print(("error: %s"):format(fmt:format(...)))
    print("")
    os.exit(1)
end

return {
    print = print_usage,
    err = print_error,
}
