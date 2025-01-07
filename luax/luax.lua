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
https://github.com/cdsoft/luax
--]]

--@MAIN

local F = require "F"

local function command(name, drop)
    return function()
        for _ = 1, drop or 1 do table.remove(arg, 1) end
        require("luax_cmd_"..name)
    end
end

return F.case(arg[1]) {
    help    = command "help",
    version = command "version",
    [F.Nil] = command("run", 0),
    run     = command "run",
    compile = command "compile",
    c       = command "compile",
    env     = command "env",
}()
