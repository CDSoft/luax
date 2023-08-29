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

local sys = require "sys"

local eps = sys.abi == "lua" and 1 or 0.01

local function time_test()
    assert(math.abs(ps.time() - os.time()) <= 1.0)

    -- time and clock variations shall be the same
    if sys.abi == "gnu" or sys.abi == "musl" then
        local t0, c0 = ps.time(), os.clock()
        local dt, dc = 0, 0
        while dt < 0.15 do
            -- active loop since os.clock only counts the CPU time used by the program
            local t1, c1 = ps.time(), os.clock()
            dt = t1-t0
            dc = c1-c0
        end
        assert(math.abs(dt - dc) <= math.max(dt*1e-2, 1e-2))
    end

    -- ps.clock shall follow os.clock
    do
        local t0, c0 = ps.clock(), os.clock()
        local dt, dc = 0, 0
        while dt < 0.15 do
            -- active loop since os.clock only counts the CPU time used by the program
            local t1, c1 = ps.clock(), os.clock()
            dt = t1-t0
            dc = c1-c0
        end
        assert(math.abs(dt - dc) <= 1e-3)
        assert(math.abs(t0 - c0) <= 1e-3)
    end
end

local function sleep_test(n)

    local t0, c0 = ps.time(), ps.clock()
    ps.sleep(n)
    local t1, c1 = ps.time(), ps.clock()

    -- ps.time measures the global execution time
    local dt = t1 - t0
    assert(n-1e-6 <= dt and dt <= n+eps, ("Expected delay: %f, actual delay: %f"):format(n, dt))

    -- ps.clock measures the CPU time (no idle time)
    local dc = c1 - c0
    assert(dc <= 1e-1, ("Expected delay: %f, actual delay: %f"):format(0, dc))
end

local function profile_test(n)
    local dt, err = ps.profile(function()
        local t = os.clock() + n
        repeat until os.clock() >= t
    end)
    assert(dt, err)
    assert(n-1e-6 <= dt and dt <= n+eps, ("Expected delay: %f, actual delay: %f"):format(n, dt))
end

return function()
    time_test()
    if sys.abi == "gnu" or sys.abi == "musl" then
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
