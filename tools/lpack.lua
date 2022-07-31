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

local fun = require "fun"
local fs = require "fs"
local sys = require "sys"

local welcome = fun.I(_G)[[
LuaX application packager version $(_LUAX_VERSION)
Copyright (C) 2021-2022 Christophe Delord (http://cdelord.fr/luax)
Based on $(_VERSION)
]]

local usage = fun.I(_G){fs=fs}[[
usage: $(fs.basename(arg[0])) <main Lua script> [Lua libraries] [options]

options:
    -o <file>   name the executable file to create
    -t <target> name of the lpack binary compiled for the targetted platform
                (cross-compilation)
]]

print(welcome)

local function err(msg)
    print("ERROR: "..msg)
    print("")
    print(usage)
    os.exit(1)
end

local output = nil
local target = nil
local scripts = {}

do
    local i = 1
    while i <= #arg do
        if arg[i] == "-h" then
            print(usage)
            os.exit()
        elseif arg[i] == "-o" then
            if output then err "Multiple -o option" end
            i = i+1
            output = arg[i]
        elseif arg[i] == "-t" then
            if target ~= nil then err "Multiple -o option" end
            i = i+1
            target = arg[i]
        elseif arg[i]:match "^%-" then err("Unknown option: "..arg[i])
        elseif fs.is_file(arg[i]) then
            scripts[#scripts+1] = arg[i]
        else err("File not found: "..arg[i])
        end
        i = i+1
    end
end

if #scripts == 0 then err "No input script specified" end
if output == nil then err "No output specified (option -o)" end

local function search_in_path(name)
    local sep = sys.os == "windows" and ";" or ":"
    local pathes = os.getenv("PATH"):split(sep)
    for i = 1, #pathes do
        local path = fs.join(pathes[i], fs.basename(name))
        if fs.is_file(path) then return path end
    end
end

actual_target = target or arg[0]
if not fs.is_file(actual_target) then
    actual_target = search_in_path(actual_target) or actual_target
end
if not fs.is_file(actual_target) then
    local lpack = search_in_path(arg[0])
    actual_target = fs.join(fs.dirname(lpack), fs.basename(actual_target))
end
if not fs.is_file(actual_target) then
    err("Can not find "..target)
end

local function log(k, fmt, ...)
    print(("%-8s: %s"):format(k, fmt:format(...)))
end

log("target", "%s", actual_target)
log("output", "%s", output)
log("scripts", "%s", scripts[1])
for i = 2, #scripts do log("", "%s", scripts[i]) end

local bundle = require "bundle"
local exe, chunk = bundle.combine(actual_target, scripts)
log("Chunk", "%7d bytes", #chunk)
log("Total", "%7d bytes", #exe)

local f = io.open(output, "wb")
if f == nil then err("Can not create "..output)
else
    f:write(exe)
    f:close()
end

fs.chmod(output, fs.aX|fs.aR|fs.uW)
