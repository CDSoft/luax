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

local F = require "F"

local tmp = require "tmp"

local prepro = {}
local prepro_mt = { __index={} }

function prepro_mt.__index:new(t)
    local new_prepro = {}
    new_prepro.dir = t.dir or self.dir
    new_prepro.pp = t.pp or self.pp
    return setmetatable(new_prepro, prepro_mt)
end

function prepro_mt.__call(self, ...)
    local dir = self.dir or "$builddir"
    local pp = self.pp or build.ypp
    return F.flatten{...} : map(function(src)
        local out = tmp.clean(dir/src:gsub("%.in$", ""))
        return pp(out) { src }
    end)
end

return setmetatable(prepro, prepro_mt)
