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

-- Pure Lua implementation of ps.c

local ps = {}

function ps.sleep(n)
    io.popen("sleep "..tostring(n)):close()
end

ps.time = os.time

ps.clock = os.clock

function ps.profile(func)
    local clock = ps.clock
    local ok, dt = pcall(function()
        local t0 = clock()
        func()
        local t1 = clock()
        return t1 - t0
    end)
    if ok then
        return dt
    else
        return ok, dt
    end

end

return ps
