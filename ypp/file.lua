--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
--]]

--[[@@@
* `f = file(name)`: return a file object that can be used to create files incrementally.
  Files are only saved once ypp succeed
* `f(s)`: add `s` to the file
* `f:ypp(s)`: preprocess and add `s` to the file
@@@]]

local F = require "F"

local file = {}
local file_mt = {__index={}}
local file_object_mt = {__index={}}

local outputs = F{}
file_mt.__index.outputs = outputs

local files = F{}
file_mt.__index.files = files

function file_mt:__call(name)
    outputs[#outputs+1] = name
    local f = setmetatable(F{name=name}, file_object_mt)
    files[#files+1] = f
    return f
end

function file_object_mt:__call(...)
    self[#self+1] = F.flatten{...}
end

function file_object_mt.__index:ypp(...)
    self[#self+1] = F.flatten{...}:map(ypp)
end

function file_object_mt.__index:flush()
    fs.mkdirs(self.name:dirname())
    fs.write(self.name, F.flatten(self):str())
end

return setmetatable(file, file_mt)
