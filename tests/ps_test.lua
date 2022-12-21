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

---------------------------------------------------------------------
-- ps
---------------------------------------------------------------------

local ps = require "ps"

local eps = on "lua" and 1 or 0.001

local function sleep_test(n)
    local t0 = ps.time()
    ps.sleep(n)
    local t1 = ps.time()
    local dt = t1 - t0
    assert(n <= dt and dt <= n+eps, ("Expected delay: %f, actual delay: %f"):format(n, dt))
end

local function profile_test(n)
    local dt, err = ps.profile(function() ps.sleep(n) end)
    assert(dt, err)
    assert(n <= dt and dt <= n+eps, ("Expected delay: %f, actual delay: %f"):format(n, dt))
end

return function()
    if on{"static", "dynamic"} then
        sleep_test(0)
        sleep_test(0.142)
        profile_test(0)
        profile_test(0.142)
    else
        sleep_test(0)
        sleep_test(2)
        profile_test(0)
        profile_test(2)
    end
end
