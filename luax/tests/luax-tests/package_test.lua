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
        F_test          = "luax/tests/luax-tests/F_test.lua",
        G_test          = "luax/tests/luax-tests/G_test.lua",
        arg_test        = "luax/tests/luax-tests/arg_test.lua",
        cbor_test       = "luax/tests/luax-tests/cbor_test.lua",
        complex_test    = "luax/tests/luax-tests/complex_test.lua",
        curl_test       = "luax/tests/luax-tests/curl_test.lua",
        crypt_test      = "luax/tests/luax-tests/crypt_test.lua",
        debug_test      = "luax/tests/luax-tests/debug_test.lua",
        fs_test         = "luax/tests/luax-tests/fs_test.lua",
        http_test       = "luax/tests/luax-tests/http_test.lua",
        imath_test      = "luax/tests/luax-tests/imath_test.lua",
        import_test     = "luax/tests/luax-tests/import_test.lua",
        json_test       = "luax/tests/luax-tests/json_test.lua",
        lib             = "luax/tests/luax-tests/lib.lua",
        readline_test   = "luax/tests/luax-tests/readline_test.lua",
        linenoise_test  = "luax/tests/luax-tests/linenoise_test.lua",
        lpeg_test       = "luax/tests/luax-tests/lpeg_test.lua",
        mathx_test      = "luax/tests/luax-tests/mathx_test.lua",
        package_test    = "luax/tests/luax-tests/package_test.lua",
        ps_test         = "luax/tests/luax-tests/ps_test.lua",
        qmath_test      = "luax/tests/luax-tests/qmath_test.lua",
        require_test    = "luax/tests/luax-tests/require_test.lua",
        resource_test   = "luax/tests/luax-tests/resource_test.lua",
        serpent_test    = "luax/tests/luax-tests/serpent_test.lua",
        sh_test         = "luax/tests/luax-tests/sh_test.lua",
        shell_env_test  = "luax/tests/luax-tests/shell_env_test.lua",
        sys_test        = "luax/tests/luax-tests/sys_test.lua",
        tar_test        = "luax/tests/luax-tests/tar_test.lua",
        toml_test       = "luax/tests/luax-tests/toml_test.lua",
        tomlx_test      = "luax/tests/luax-tests/tomlx_test.lua",
        test            = "luax/tests/luax-tests/test.lua",
        test_test       = "luax/tests/luax-tests/test_test.lua",
        version_test    = "luax/tests/luax-tests/version_test.lua",
    }
    or {}

    -- modules imported by the `import` function
    modpath["luax/tests/luax-tests/to_be_imported-1.lua"] = "luax/tests/luax-tests/to_be_imported-1.lua"
    modpath["luax/tests/luax-tests/to_be_imported-2.lua"] = "luax/tests/luax-tests/to_be_imported-2.lua"
    -- files read by the tomlx tests
    local tmp = os.getenv "TESTDIR" / os.getenv "TEST_NUM"
    modpath[tmp/"f1.toml"] = tmp/"f1.toml"
    modpath[tmp/"f2.toml"] = tmp/"f2.toml"
    modpath[tmp/"f3.toml"] = tmp/"f3.toml"
    modpath[tmp/"schema.toml"] = tmp/"schema.toml"

    eq(package.modpath, F.merge{modpath, {}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="luax/tests/luax-tests/test_lib/foo.lua"}})
    require "test_lib/bar"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="luax/tests/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="luax/tests/luax-tests/test_lib/bar.lua"}})
    require "test_lib/foo"
    eq(package.modpath, F.merge{modpath, {["test_lib/foo"]="luax/tests/luax-tests/test_lib/foo.lua", ["test_lib/bar"]="luax/tests/luax-tests/test_lib/bar.lua"}})

end
