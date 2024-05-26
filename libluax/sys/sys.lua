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

-- Pure Lua implementation of sys.c

local sys = {
    libc = "lua",
}

local F = require "F"

local targets = require "targets"

local kernel, machine

if package.config:sub(1, 1) == "/" then
    -- Search for a Linux-like target
    kernel, machine = io.popen("uname -s -m", "r") : read "a" : trim() : words() : unpack()
else
    -- Search for a Windows target
    kernel, machine = os.getenv "OS", os.getenv "PROCESSOR_ARCHITECTURE"
end

local target = targets:find(function(t) return t.kernel==kernel and t.machine==machine end)

if not target then
    io.stderr:write("ERROR: Unknown architecture\n",
        "Please report the bug with this information:\n",
        "    config  = "..package.config:lines():head().."\n",
        "    kernel  = "..tostring(kernel).."\n",
        "    machine = "..tostring(machine).."\n",
        ">> https://github.com/CDSoft/luax/issues <<\n"
    )
    os.exit(1)
end

sys.name = target.name
sys.os = target.os
sys.arch = target.arch
sys.exe = target.exe
sys.so = target.so

return sys
