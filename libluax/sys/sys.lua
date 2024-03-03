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
    os   = pandoc and pandoc.system.os,
    arch = pandoc and pandoc.system.arch,
    libc = "lua",
}

local F = require "F"

--[[@@@
```lua
sys.build
```
Build platform used to compile LuaX.

```lua
sys.host
```
Host platform where LuaX is currently running.
@@@]]


local targets = F{
    {name="linux-x86_64",       uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so" },
    {name="linux-x86_64-musl",  uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"},
    {name="linux-aarch64",      uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so" },
    {name="linux-aarch64-musl", uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"},
    {name="macos-x86_64",       uname_kernel="Darwin", uname_machine="x86_64",  os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      uname_kernel="Darwin", uname_machine="arm64",   os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    {name="windows-x86_64",     uname_kernel="MINGW",  uname_machine="x86_64",  os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll" },
}
targets : foreach(function(target) targets[target.name] = target end)

sys.build = targets
    : filter(function(target) return target.os == sys.os and target.arch == sys.arch and target.libc == sys.libc end)
    : head()

local function detect(field)
    local sh = require "sh"
    local os, arch = assert(sh.read"uname -s -m", "can not detect the current platform with uname")
                        : words() ---@diagnostic disable-line: undefined-field
                        : unpack()
    local host = targets
        : filter(function(target) return os:match(target.uname_kernel) and arch:match(target.uname_machine) end)
        : head()
    if host then
        sys.os = host.os
        sys.arch = host.arch
        sys.host = host
        return rawget(sys, field)
    end
    error("Unknown platform: "..os.." "..arch)
end

setmetatable(sys, {
    __index = function(_, param)
        if param == "os"      then return detect "os" end
        if param == "arch"    then return detect "arch" end
        if param == "host"    then return detect "host" end
        if param == "build"   then sys.build = sys.host; return sys.build end -- assume build == host when using the Lua implementation
        if param == "targets" then return targets end
    end,
})

return sys
