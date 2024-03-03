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

local targets = {
    {name="linux-x86_64",       uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="gnu" },
    {name="linux-x86_64-musl",  uname_kernel="Linux",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="musl"},
    {name="linux-aarch64",      uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="gnu" },
    {name="linux-aarch64-musl", uname_kernel="Linux",  uname_machine="aarch64", os="linux",   arch="aarch64", libc="musl"},
    {name="macos-x86_64",       uname_kernel="Darwin", uname_machine="x86_64",  os="macos",   arch="x86_64",  libc="none"},
    {name="macos-aarch64",      uname_kernel="Darwin", uname_machine="arm64",   os="macos",   arch="aarch64", libc="none"},
    {name="windows-x86_64",     uname_kernel="MINGW",  uname_machine="x86_64",  os="windows", arch="x86_64",  libc="gnu" },
}
for _, target in ipairs(targets) do
    targets[target.name] = target
end

local function detect_target(field)
    local sh = require "sh"
    local os, arch = assert(sh.read"uname -s -m", "can not detect the current platform with uname")
                        : words() ---@diagnostic disable-line: undefined-field
                        : unpack()
    for _, target in ipairs(targets) do
        if os:match(target.uname_kernel) and arch:match(target.uname_machine) then
            sys.os = target.os
            sys.arch = target.arch
            return rawget(sys, field)
        end
    end
    error("Unknown platform: "..os.." "..arch)
end

setmetatable(sys, {
    __index = function(_, param)
        if param == "os"      then return detect_target "os" end
        if param == "arch"    then return detect_target "arch" end
        if param == "targets" then return targets end
    end,
})

return sys
