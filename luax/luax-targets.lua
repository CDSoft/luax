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

--[[ Target definitions:

Field       Description                         Value
----------- ----------------------------------- -------------------------------------------------------------
name        LuaX target name                    "OS"-"ARCH"[-musl]
machine     architecture name                   uname -m on Linux/MacOS, %PROCESSOR_ARCHITECTURE% on Windows
kernel      OS kernel                           uname -s on Linux/MacOS, %OS% on Windows
os          OS name known by LuaX               linux, macos, windows
arch        architecture name known by LuaX     x86_64, x86, aarch64
libc        C library name                      gnu, musl, none
exe         executable file extension           .exe on Windows
so          shared library file extension       .so on Linux, .dylib on MacOS, .dll on Windows

--]]

return F{
    -- 64-bit Linux
    {name="linux-x86_64",       machine="x86_64",  kernel="Linux",      os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86_64-musl",  machine="x86_64",  kernel="Linux",      os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"   },
    {name="linux-aarch64",      machine="aarch64", kernel="Linux",      os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so"   },
    {name="linux-aarch64-musl", machine="aarch64", kernel="Linux",      os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"   },
    -- 32-bit Linux
    {name="linux-x86",          machine="i686",    kernel="Linux",      os="linux",   arch="x86",     libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86-musl",     machine="i686",    kernel="Linux",      os="linux",   arch="x86",     libc="musl",  exe="",     so=".so"   },
    -- 64-bit macos
    {name="macos-x86_64",       machine="x86_64",  kernel="Darwin",     os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      machine="arm64",   kernel="Darwin",     os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    -- 64-bit Windows
    {name="windows-x86_64",     machine="AMD64",   kernel="Windows_NT", os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll"  },
    {name="windows-aarch64",    machine="ARM64",   kernel="Windows_NT", os="windows", arch="aarch64", libc="gnu",   exe=".exe", so=".dll"  },
    -- 32-bit Windows
    {name="windows-x86",        machine="x86",     kernel="Windows_NT", os="windows", arch="x86",     libc="gnu",   exe=".exe", so=".dll"  },
}
