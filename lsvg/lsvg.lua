#!/usr/bin/env luax

--[[
This file is part of lsvg.

lsvg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

lsvg is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with lsvg.  If not, see <https://www.gnu.org/licenses/>.

For further information about lsvg you can visit
https://codeberg.org/cdsoft/lsvg
--]]

local F = require "F"
local fs = require "fs"

require "luax-package"

local version = require "luax-version".version

local function parse_args()
    local parser = require "argparse"()
        : name "lsvg"
        : description(F.unlines {
            "SVG generator scriptable in LuaX",
            "",
            "Arguments after \"--\" are given to the input scripts",
        } : rtrim())
        : epilog "For more information, see https://codeberg.org/cdsoft/lsvg"

    parser : flag "-v"
        : description(('Print version ("%s")'):format(version))
        : action(function() print(version); os.exit() end)

    parser : option "-o"
        : description "Output file name (SVG, PNG, JPEG or PDF)"
        : argname "output"
        : target "output"

    parser : option "--MF"
        : description "Set the dependency file name (implies `--MD`)"
        : target "depfile"
        : argname "name"

    parser : flag "--MD"
        : description "Generate a dependency file"
        : target "gendep"

    parser : argument "input"
        : description "Lua script using the svg module to build an SVG image"
        : args "+"

    local lsvg_arg, script_arg = F.break_(F.partial(F.op.eq, "--"), arg)
    local args = parser:parse(lsvg_arg)
    _G.arg = script_arg:drop(1)

    return args
end

local args = parse_args()

local svg = require "svg".open()

-- The Lua script shall use the global variable `img` to describe the SVG image
_ENV.img = svg()

F.foreach(args.input, function(name)
    _G.arg[0] = name
    assert(loadfile(name))()
end)

if args.output then
    if not _ENV.img:save(args.output) then
        io.stderr:write(arg[0], ": can not save ", args.output, "\n")
        os.exit(1)
    end

    if args.gendep or args.depfile then
        local depfile = args.depfile or fs.splitext(args.output)..".d"
        local function mklist(...)
            return F.flatten{...}:from_set(F.const(true)):keys()
                :map(function(p) return p:gsub("^%."..fs.sep, "") end)
                :sort()
                :unwords()
        end
        local scripts = F.values(package.modpath)
        local deps = mklist(args.output).." : "..mklist(args.input, scripts)
        fs.mkdirs(depfile:dirname())
        fs.write(depfile, deps.."\n")
    end

end

