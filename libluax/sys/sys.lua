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
    {name="linux-x86_64",       uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86_64-musl",  uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"   },
    {name="linux-aarch64",      uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so"   },
    {name="linux-aarch64-musl", uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"   },
    {name="macos-x86_64",       uname_kernel="Darwin", uname_machine="x86_64",  os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      uname_kernel="Darwin", uname_machine="arm64",   os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    {name="windows-x86_64",     uname_kernel="MINGW",  uname_machine="x86_64",  os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll"  },
}
targets : foreach(function(target) targets[target.name] = target end)

if sys.libc == "lua" then

    if pandoc then

        sys.os   = pandoc.system.os
        sys.arch = pandoc.system.arch

        if sys.os:match"mingw" then sys.os = "windows" end

        targets : foreach(function(target)
            if not sys.name and sys.os == target.os and sys.arch == target.arch then
                sys.exe  = target.exe
                sys.so   = target.so
                sys.name = target.name
            end
        end)

    else

        local sh = require "sh"
        local os, arch = F(sh.read"uname -s -m" or "")
                            : words() ---@diagnostic disable-line: undefined-field
                            : unpack()
        local host = targets
            : filter(function(target) return os:match(target.uname_kernel) and arch:match(target.uname_machine) end)
            : head()
        if host then
            -- Linux/MacOS detected with uname
            sys.os   = host.os
            sys.arch = host.arch
            sys.exe  = host.exe
            sys.so   = host.so
            sys.name = host.name
        else
            local win_os = os.getenv "OS"
            if win_os:match "Windows" then
                -- Assuming Windows
                local win = targets
                    : filter(function(target) return target.os=="windows" end)
                    : head()
                sys.os   = win.os
                sys.arch = win.arch
                sys.exe  = win.exe
                sys.so   = win.so
                sys.name = win.name
            end
        end

    end

end

return setmetatable(sys, {
    __index = {
        targets = targets,
    },
})
