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

--@LOAD
local _, ps = pcall(require, "_ps")
ps = _ and ps

if not ps then
    ps = {}

    function ps.sleep(n)
        return sh.run("sleep", n)
    end

    function ps.time()
        return os.time()
    end

    function ps.profile(func)
        local t0 = os.time()
        func()
        local t1 = os.time()
        return t1 - t0
    end

end

return ps
