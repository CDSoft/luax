--[[
This file is part of lsvg.

lsvg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

lsvg is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with lsvg.  If not, see <https://www.gnu.org/licenses/>.

For further information about lsvg you can visit
https://codeberg.org/cdsoft/luax
--]]

img {
    width = 1024,
    height = 1024,
    font_size = 312,
    text_anchor = "middle",
    font_family = "Liberation Sans",
}

local w = img.attrs.width
local h = img.attrs.height
local fh = img.attrs.font_size

local orbit_width = 15
local r_orbit = w/2-orbit_width
local r_planet = 384-20
local r_moon = r_planet/4 + 22

-- the origin is the center of the planet
local M0 = Point(r_planet, 0):rot(math.rad(-45))
local M1 = M0:unit() * (r_orbit+44)     -- center of the moon
local M2 = 2*M0 - M1                    -- center of the shadow of the moon

img:G {
    transform = ("translate(%d, %d)"):format(w/2, h/2),
    fill = "white",

    -- orbit and background
    Circle {
        r = r_orbit,
        stroke = "grey", stroke_width = orbit_width, stroke_dasharray = 50,
        transform = "rotate(-5)",
    },

    -- planet
    Circle { r = r_planet, fill = "blue" },
    Text "Lua" { xy = Point(0, fh*5/8) },

    -- moon and its shadow
    G {
        font_size = fh/2, font_weight = "bold",

        -- moon
        Circle { cxy = M1, r = r_moon, fill = "blue" },
        Text "X" { xy = M1+Point(0, fh*3/16) },

        -- shadow
        Circle { cxy = M2, r = r_moon },
        Text "X" { xy = M2+Point(0, fh*3/16), fill = "blue" },
    },
}
