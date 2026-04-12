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
-- https://codeberg.org/cdsoft/luax

local fs = require "fs"
local F = require "F"

local flatten = require "flatten"

local file_mt = {__index = {}}

function file_mt.__call(self, ...)
    self.chunks[#self.chunks+1] = {...}
    return self.name -- return the filename to easily add it to a filelist in the build file
end

function file_mt.__index:close()
    local new_content = flatten(self.chunks):str()
    local old_content = fs.read(self.name)
    if old_content == new_content then
        return -- keep the old file untouched
    end
    fs.mkdirs(self.name:dirname())
    fs.write(self.name, new_content)
end

local open_files = F{}

local function file(name)
    name = vars%name
    if open_files[name] then
        error(name..": multiple file creation")
    end
    local f = setmetatable({name=name, chunks={}}, file_mt)
    open_files[name] = f
    return f
end

return setmetatable({}, {
    __call = function(_, name) return file(name) end,
    __index = {
        flush = function()
            open_files:foreacht(function(f) f:close() end)
        end,
    },
})
