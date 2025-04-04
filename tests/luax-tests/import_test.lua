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

---------------------------------------------------------------------
-- package
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local import = require "import"

return function()

    eq(import "tests/luax-tests/to_be_imported-1.lua", {global_variable=42})
    eq(import "tests/luax-tests/to_be_imported-1.lua", {global_variable=42})

    eq(import "tests/luax-tests/to_be_imported-2.lua", {global_variable_2=666*42})
    eq(import "tests/luax-tests/to_be_imported-2.lua", {global_variable_2=666*42})

    eq(import "tests/luax-tests/to_be_imported-1.lua", {global_variable=42})

    eq(package.modpath["tests/luax-tests/to_be_imported-1.lua"], "tests/luax-tests/to_be_imported-1.lua")
    eq(package.modpath["tests/luax-tests/to_be_imported-2.lua"], "tests/luax-tests/to_be_imported-2.lua")

end
