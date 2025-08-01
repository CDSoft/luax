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

--@LIB

local F = require "F"
local fs = require "fs"
local sys = require "sys"
local term = require "term"
local linenoise = require "linenoise"

local help = require "luax_help"

local expected_files = F.flatten {
    (sys.libc=="gnu" or sys.libc=="musl") and "bin"/"luax"..sys.exe or {},
    "bin"/"luax.lua",
    "bin"/"luax-pandoc.lua",
    sys.libc=="gnu" and "lib"/"libluax"..sys.so or {},
    "lib"/"libluax.lar",
    "lib"/"libluax.lua",
}

local arg0 <const> = arg[0]

local function wrong_arg(a)
    help.err("unrecognized option '%s'", a)
end

local force = false
local interactive = term.isatty(0) and term.isatty(1)

do
    local i = 1
    while i <= #arg do
        local a = arg[i]
        if a == '-f' then
            force = true
        else
            wrong_arg(a)
        end
        i = i + 1
    end
end

local exe =
    fs.is_file(arg0) and arg0
    or (sys.exe ~= "" and fs.is_file(arg0..sys.exe) and arg0..sys.exe)
    or fs.findpath(arg0)
    or (sys.exe ~= "" and fs.findpath(arg0..sys.exe))

if not exe then
    help.err("%s: not found", arg0)
end

local prefix = assert(exe):dirname():dirname():realpath()
local bin = prefix/"bin"
local lib = prefix/"lib"
local new_files = expected_files : map(function(file) return prefix/file end)

print(_LUAX_COPYRIGHT)
print(("="):rep(#_LUAX_COPYRIGHT))

local found = term.color.green "✔"
local not_found = term.color.red "✖"
local recycle = term.color.yellow "♻"

local function confirm(msg, ...)
    local prompt = string.format(msg, ...).."? [y/N]"
    local ans = nil
    repeat
        ans = linenoise.read(prompt) : trim() : lower()
    until ans:match "^[yn]?$"
    return ans == "y"
end

-- Search for installed files

print("")
local all_found = true
new_files : foreach(function(file)
    local exists = fs.is_file(file)
    print((exists and found or not_found).." "..file)
    all_found = all_found and exists
end)

if not all_found then help.err("Some files are missing") end

-- Search for obsolete files

local obsolete_files = (fs.ls(bin) .. fs.ls(lib))
    : filter(function(file) return file:basename():match "luax" end)
    : filter(function(file) return new_files:not_elem(file) end)

if #obsolete_files > 0 then
    print("")
    obsolete_files : foreach(function(file)
        if force then
            print(string.format("%s remove %s", recycle, file))
            assert(fs.remove(file))
        elseif interactive then
            if confirm("%s remove obsolete LuaX file '%s'", recycle, file) then
                assert(fs.remove(file))
            end
        else
            print(string.format("%s %s is obsolete", recycle, file))
        end
    end)
end

