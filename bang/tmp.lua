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
local fs = require "fs"

local tmp = {}

local unique_index = setmetatable({_=0}, {
    __index = function(self, k)
        local idx = ("%x"):format(self._)
        self._ = self._ + 1
        self[k] = idx
        return idx
    end,
})

function tmp.clean(path)
    local n = 0
    return fs.join(fs.splitpath(path)
        : map(function(dir)
            if dir == "$builddir" then
                n = n + 1
                return n <= 1 and dir or nil
            end
            return dir
        end))
end

function tmp.index(root, ...)
    local ps = {...}
    return tmp.clean(root / unique_index[fs.join(F.init(ps))] / F.last(ps):splitext())
end

function tmp.hash(root, ...)
    local ps = {...}
    return tmp.clean(root / fs.join(F.init(ps)):hash() / F.last(ps):splitext())
end

function tmp.short(root, ...)
    local root_components = fs.splitpath(root)
    local path = fs.join(F.init{...})
        : splitpath()
        : reverse()
        : nub()
        : reverse()
        : filter(function(p) return F.not_elem(p, root_components) end)
    path[#path] = path[#path]..".tmp"
    local file = F.last{...} : splitext()
    return tmp.clean(fs.join(F.flatten { root, path, file }))
end

return setmetatable(tmp, {__call = function(self, ...) return self.short(...) end})
