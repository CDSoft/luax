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

-- This is the main test script
-- @MAIN

-- luax global environment
-- (shall be tested first before other tests add global variables)
require "G_test"()

-- Check the test environment first
require "test_test"()

-- luax builtins
require "arg_test"()
require "require_test"()

-- luax libraries
require "F_test"()
require "sys_test"()
require "fs_test"()
require "sh_test"()
require "ps_test"()
require "crypt_test"()
require "lpeg_test"()
require "complex_test"()
require "socket_test"()
require "inspect_test"()
require "serpent_test"()
require "cbor_test"()
require "lz4_test"()
require "mathx_test"()
require "imath_test"()
require "qmath_test"()
require "linenoise_test"()
require "package_test"()
require "resource_test"()
require "import_test"()

-- luax global environment
-- (also tested at the end to check that tests and new modules do not touch global variables)
require "G_test"()
