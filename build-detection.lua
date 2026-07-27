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

local F = require "F"
local sh = require "sh"

local has = {}

-------------------------------------------------------------------------------
-- Pandoc detection
-------------------------------------------------------------------------------

local minimal_pandoc_version = {3, 1, 12, 3}
local pandoc_version = (sh"pandoc --version 2>/dev/null" or "0") : match"[%d%.]+" : split"%." : map(tonumber)

has.pandoc = F.op.uge(pandoc_version, minimal_pandoc_version)

-------------------------------------------------------------------------------
-- Return the feature table
-------------------------------------------------------------------------------

return has
