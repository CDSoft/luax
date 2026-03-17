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

    local toml = require "toml"
    assert(toml)

    local conf = [===[

        # This is a TOML document

        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00

        [database]
        enabled = true
        ports = [ 8000, 8001, 8002 ]
        data = [ ["delta", "phi"], [3.14] ]
        temp_targets = { cpu = 79.5, case = 72.0 }

        [servers]

        [servers.alpha]
        ip = "10.0.0.1"
        role = "frontend"

        [servers.beta]
        ip = "10.0.0.2"
        role = "backend"

    ]===]

    eq(toml.parse(conf, {load_from_string=true}), {
        title = "TOML Example",
        owner = { dob="1979-05-27T07:32:00-08:00", name="Tom Preston-Werner" },
        database = {
            enabled = true,
            ports = {8000, 8001, 8002},
            data = { {"delta", "phi"}, {0x1.91eb851eb851fp+1} },
            temp_targets = { cpu=0x1.3ep+6, case=0x1.2p+6 },
        },
        servers = {
            alpha = { ip="10.0.0.1", role="frontend" },
            beta = { ip="10.0.0.2", role="backend" },
        },
    })

end
