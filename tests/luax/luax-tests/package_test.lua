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

local F = require "F"

local test_num = tonumber(os.getenv"TEST_NUM")

return function()

    local modpath =
    F.elem(test_num, {2, 3, 4, 5, 6}) and {
        F_test          = "tests/luax/luax-tests/F_test.lua",
        G_test          = "tests/luax/luax-tests/G_test.lua",
        arg_test        = "tests/luax/luax-tests/arg_test.lua",
        cbor_test       = "tests/luax/luax-tests/cbor_test.lua",
        complex_test    = "tests/luax/luax-tests/complex_test.lua",
        curl_test       = "tests/luax/luax-tests/curl_test.lua",
        crypt_test      = "tests/luax/luax-tests/crypt_test.lua",
        debug_test      = "tests/luax/luax-tests/debug_test.lua",
        fs_test         = "tests/luax/luax-tests/fs_test.lua",
        imath_test      = "tests/luax/luax-tests/imath_test.lua",
        import_test     = "tests/luax/luax-tests/import_test.lua",
        json_test       = "tests/luax/luax-tests/json_test.lua",
        lib             = "tests/luax/luax-tests/lib.lua",
        readline_test   = "tests/luax/luax-tests/readline_test.lua",
        linenoise_test  = "tests/luax/luax-tests/linenoise_test.lua",
        lpeg_test       = "tests/luax/luax-tests/lpeg_test.lua",
        mathx_test      = "tests/luax/luax-tests/mathx_test.lua",
        package_test    = "tests/luax/luax-tests/package_test.lua",
        ps_test         = "tests/luax/luax-tests/ps_test.lua",
        qmath_test      = "tests/luax/luax-tests/qmath_test.lua",
        require_test    = "tests/luax/luax-tests/require_test.lua",
        resource_test   = "tests/luax/luax-tests/resource_test.lua",
        serpent_test    = "tests/luax/luax-tests/serpent_test.lua",
        sh_test         = "tests/luax/luax-tests/sh_test.lua",
        shell_env_test  = "tests/luax/luax-tests/shell_env_test.lua",
        sys_test        = "tests/luax/luax-tests/sys_test.lua",
        tar_test        = "tests/luax/luax-tests/tar_test.lua",
        toml_test       = "tests/luax/luax-tests/toml_test.lua",
        tomlx_test      = "tests/luax/luax-tests/tomlx_test.lua",
        test            = "tests/luax/luax-tests/test.lua",
        test_test       = "tests/luax/luax-tests/test_test.lua",
        version_test    = "tests/luax/luax-tests/version_test.lua",
    }
    or {}

    -- modules imported by the `import` function
    modpath["tests/luax/luax-tests/to_be_imported-1.lua"] = "tests/luax/luax-tests/to_be_imported-1.lua"
    modpath["tests/luax/luax-tests/to_be_imported-2.lua"] = "tests/luax/luax-tests/to_be_imported-2.lua"
    -- files read by the tomlx tests
    local tmp = os.getenv "TESTDIR" / os.getenv "TEST_NUM"
    modpath[tmp/"f1.toml"] = tmp/"f1.toml"
    modpath[tmp/"f2.toml"] = tmp/"f2.toml"
    modpath[tmp/"f3.toml"] = tmp/"f3.toml"
    modpath[tmp/"schema.toml"] = tmp/"schema.toml"

    eq(package.modpath, F.merge{modpath, {}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax/luax-tests/test_lib/foo.lua"}})
    require "test_lib/bar"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="tests/luax/luax-tests/test_lib/bar.lua"}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="tests/luax/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="tests/luax/luax-tests/test_lib/bar.lua"}})

end
