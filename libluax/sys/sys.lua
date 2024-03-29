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
local _, sys = pcall(require, "_sys")
sys = _ and sys or {
    libc = "lua",
}

local F = require "F"

local targets = F{
    {name="linux-x86_64",       uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86_64-musl",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"   },
    {name="linux-aarch64",      uname_machine="aarch64", os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so"   },
    {name="linux-aarch64-musl", uname_machine="aarch64", os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"   },
    {name="macos-x86_64",       uname_machine="x86_64",  os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      uname_machine="arm64",   os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    {name="windows-x86_64",     uname_machine="AMD64",   os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll"  },
}
targets : foreach(function(target) targets[target.name] = target end)

if sys.libc == "lua" then

    local function uname() return io.popen("uname -m", "r") : read "a" : trim() end

    -- the libraries extension in package.cpath is specific to the OS
    sys.so = package.cpath:match "%.[^%.]-$"
    sys.os = assert(targets : find(function(t) return t.so == sys.so end), "Unknown OS").os

    sys.arch = pandoc and pandoc.system.arch or
        (function()
            local machine = F.case(sys.os) {
                linux   = uname,
                macos   = uname,
                windows = function() return os.getenv "PROCESSOR_ARCHITECTURE" end,
            }()
            return assert(targets : find(function(t) return t.os==sys.os and t.uname_machine==machine end), "Unknown architecture").arch
        end)()

    local host = assert(targets : find(function(t) return t.os==sys.os and t.arch==sys.arch end), "Unknown platform")

    sys.exe  = host.exe
    sys.name = host.name

end

return setmetatable(sys, {
    __index = {
        targets = targets,
    },
})
