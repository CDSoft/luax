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

local test = require "test"
local eq = test.eq

return function()

    local tomlx = require "tomlx"
    assert(tomlx)

    local conf = [===[

        # This is a TOML document

        title = "TOML(x) Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00

        [extension]
        name = "Christophe Delord"

        [database]
        enabled = true
        base = 8000
        ports = [ "=base+0", "=base+1", "=base+2" ]
        data = [ ["delta", "phi"], [3.14] ]
        temp_targets = { cpu = 79.5, case = 72.0 }
        pi = "=math.pi"
        made_by = "=__up.owner.name"
        extended_by = "=extension.name"
        title = "=__root.title"

        [servers]

        [servers.alpha]
        ip = "10.0.0.1"
        role = "frontend"

        [servers.beta]
        ip = "10.0.0.2"
        role = "backend"

    ]===]

    local lua_table = {
        title = "TOML(x) Example",
        owner = { dob="1979-05-27T07:32:00-08:00", name="Tom Preston-Werner" },
        extension = { name="Christophe Delord" },
        database = {
            enabled = true,
            base = 8000,
            ports = {8000, 8001, 8002},
            data = { {"delta", "phi"}, {0x1.91eb851eb851fp+1} },
            temp_targets = { cpu=0x1.3ep+6, case=0x1.2p+6 },
            pi = math.pi,
            made_by = "Tom Preston-Werner",
            extended_by = "Christophe Delord",
            title = "TOML(x) Example",
        },
        servers = {
            alpha = { ip="10.0.0.1", role="frontend" },
            beta = { ip="10.0.0.2", role="backend" },
        },
    }

    eq(tomlx.decode(conf, {env=_G}), lua_table)

    local bad_conf = [[
    [foo]
    bar = 42
    baz = {
        array = [ 1, 2, "= foo.bar + baz" ],
    }
    ]]

    eq({pcall(tomlx.decode, bad_conf)}, {
        false,
        "foo.baz.array[3]: foo.bar + baz:1: attempt to perform arithmetic on a table value (global 'baz')",
    })

end
