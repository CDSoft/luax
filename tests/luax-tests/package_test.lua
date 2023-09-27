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

---------------------------------------------------------------------
-- package
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local F = require "F"

local test_num = tonumber(os.getenv"TEST_NUM")

return function()

    local modpath = F.elem(test_num, {2, 3, 4, 5, 6}) and {
        F_test          = "tests/luax-tests/F_test.lua",
        G_test          = "tests/luax-tests/G_test.lua",
        arg_test        = "tests/luax-tests/arg_test.lua",
        cbor_test       = "tests/luax-tests/cbor_test.lua",
        complex_test    = "tests/luax-tests/complex_test.lua",
        crypt_test      = "tests/luax-tests/crypt_test.lua",
        fs_test         = "tests/luax-tests/fs_test.lua",
        imath_test      = "tests/luax-tests/imath_test.lua",
        inspect_test    = "tests/luax-tests/inspect_test.lua",
        lib             = "tests/luax-tests/lib.lua",
        linenoise_test  = "tests/luax-tests/linenoise_test.lua",
        lpeg_test       = "tests/luax-tests/lpeg_test.lua",
        lz4_test        = "tests/luax-tests/lz4_test.lua",
        mathx_test      = "tests/luax-tests/mathx_test.lua",
        package_test    = "tests/luax-tests/package_test.lua",
        ps_test         = "tests/luax-tests/ps_test.lua",
        qmath_test      = "tests/luax-tests/qmath_test.lua",
        require_test    = "tests/luax-tests/require_test.lua",
        serpent_test    = "tests/luax-tests/serpent_test.lua",
        sh_test         = "tests/luax-tests/sh_test.lua",
        socket_test     = "tests/luax-tests/socket_test.lua",
        sys_test        = "tests/luax-tests/sys_test.lua",
        test            = "tests/luax-tests/test.lua",
        test_test       = "tests/luax-tests/test_test.lua",
    } or {}

    eq(package.modpath, F.merge{modpath, {}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax-tests/test_lib/foo.lua"}})
    require "test_lib/bar"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="tests/luax-tests/test_lib/bar.lua"}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="tests/luax-tests/test_lib/bar.lua"}})

end
