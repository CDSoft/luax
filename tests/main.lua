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

-- Check the test environment first
require "test_test"()

-- luax builtins
require "arg_test"()
require "require_test"()

-- luax libraries
require "fun_test"()
require "string_test"()
require "sys_test"()
require "fs_test"()
require "ps_test"()
require "crypt_test"()
require "lpeg_test"()
require "complex_test"()
require "socket_test"()
