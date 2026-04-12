-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/bang

return function()
    -- get the current location in the first user script in the call stack

    local i = 2
    while true do
        local info = debug.getinfo(i)
        if not info then return "" end
        local file = info.source : match "^@(.*)"
        if file and not file:has_prefix "$" then
            return ("[%s:%d] "):format(file, info.currentline)
        end
        i = i + 1
    end

end
