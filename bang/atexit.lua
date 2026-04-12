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

local F = require "F"

local registered_functions = F{}

return setmetatable({}, {
    __call = function(_, f)
        if type(f) ~= "function" then error(tostring(f).." is not a function", 2) end
        registered_functions[#registered_functions+1] = f
    end,
    __index = {
        run = function()
            while not registered_functions:null() do
                local funcs = registered_functions
                registered_functions = F{}
                funcs:foreach(F.call)
            end
        end,
    },
})
