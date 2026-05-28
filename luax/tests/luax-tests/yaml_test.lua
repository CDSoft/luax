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

    local yaml = require "yaml"
    assert(yaml)

    local t = yaml.parse [===[
---
receipt:     Oz-Ware Purchase Invoice
date:        2012-08-06
customer:
    given:   Dorothy
    family:  Gale

items:
    - part_no:   A4786
      descrip:   Water Bucket (Filled)
      price:     1.47
      quantity:  4

    - part_no:   E1628
      descrip:   High Heeled "Ruby" Slippers
      size:      8
      price:     100.27
      quantity:  1

specialDelivery:  >
    Follow the Yellow Brick
    Road to the Emerald City.
    Pay no attention to the
    man behind the curtain.
...
]===]

    eq(t, {
        receipt = "Oz-Ware Purchase Invoice",
        --date = "2012-08-06T00:00:00.000",
        date = {
            day = 6,
            fraction = 0,
            hour = 0,
            minute = 0,
            month = 8,
            second = 0,
            year = 2012,
        },
        customer = { family="Gale", given="Dorothy" },
        items = {
            {
                part_no = "A4786",
                descrip = "Water Bucket (Filled)",
                price = 0x1.7851eb851eb85p+0,
                quantity = 4,
            },
            {
                part_no = "E1628",
                descrip = "High Heeled \"Ruby\" Slippers",
                size = 8,
                price = 0x1.91147ae147ae1p+6,
                quantity = 1,
            },
        },
        specialDelivery = "Follow the Yellow Brick Road to the Emerald City. Pay no attention to the man behind the curtain.\n",
    })

end
