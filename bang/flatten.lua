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
-- Software freedom is inseparable from freedom of thought. Fascism -
-- in all its forms - is incompatible with the values this project stands
-- on, even though the GPL itself cannot and does not restrict who may
-- use this software. See FREEDOM.md.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

return function(xs)
    return F.filter_ne(F.Nil, F.flatten(xs))
end
