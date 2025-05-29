local license = [[
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
]]

local F = require "F"
local crypt = require "crypt"

local opt = (function()
    local parser = require "argparse"() : name "LuaX logo generator"
    parser : flag "--sky" : description "Add stars in the sky"
    parser : option "--name" : description "Set the name printed on the planet"
    parser : option "--text" : description "Set the text printed below the planet"
    parser : argument "size" : description "Image resolution" : args "0-2"
    return parser:parse(arg)
end)()

img {
    Raw (F.unlines { "<!--",
        license:trim(), ---@diagnostic disable-line: undefined-field
        "-->"
    })
}

local w = tonumber(opt.size[1]) or 1024
local h = tonumber(opt.size[2]) or w
local fh = h/4

img {
    width = w,
    height = h,
    font_size = fh,
    text_anchor = "middle",
    font_family = "Liberation Sans Bold",
    transparent = "white",
}

local r_planet = h*3/8
local r_ring = r_planet * 1.25
local ring_width = h*5/64
local r_moon = r_planet/4 + h*3/128
local r_orbit = h/2 - h*5/64
local inclination = 15
local number_of_stars = 30
local r_star = h * 4/1024

img {
    Raw [===[
        <defs>
            <linearGradient id="PlanetGradient" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stop-color="lightgrey"/>
                <stop offset="15%" stop-color="cyan"/>
                <stop offset="30%" stop-color="orange"/>
                <stop offset="70%" stop-color="green"/>
                <stop offset="85%" stop-color="blue"/>
                <stop offset="100%" stop-color="lightgrey"/>
            </linearGradient>
            <linearGradient id="MoonGradient" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stop-color="darkgrey"/>
                <stop offset="50%" stop-color="lightgrey"/>
                <stop offset="100%" stop-color="darkgrey"/>
            </linearGradient>
            <linearGradient id="TopRingGradient" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stop-color="black" stop-opacity="0"/>
                <stop offset="49%" stop-color="grey" stop-opacity="0"/>
                <stop offset="50%" stop-color="grey" stop-opacity="1"/>
                <stop offset="100%" stop-color="darkgrey" stop-opacity="1"/>
            </linearGradient>
            <linearGradient id="BottomRingGradient" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stop-color="black" stop-opacity="1"/>
                <stop offset="50%" stop-color="grey" stop-opacity="1"/>
                <stop offset="51%" stop-color="grey" stop-opacity="0"/>
                <stop offset="100%" stop-color="darkgrey" stop-opacity="0"/>
            </linearGradient>
        </defs>
    ]===],
}

local function planet()
    return Circle {
        r = r_planet,
        fill = "url(#PlanetGradient)",
    }
end

local function moon()
    return Circle {
        cxy = Point(r_orbit, 0):rot(-math.pi/4),
        r = r_moon,
        fill = "url(#MoonGradient)",
    }
end

local function ring(dir)
    return Ellipse {
        rx = r_ring,
        ry = r_ring*0.33,
        fill_opacity = 0,
        stroke = dir > 0 and "url(#TopRingGradient)" or "url(#BottomRingGradient)",
        stroke_width = ring_width,
    }
end

local function sky()
    local stars = G {
        stroke_width = h * 3/1024,
        stroke_linecap = "round",
    }
    local star_colors = { "gold", "red", "cyan", "brown" }
    local rnd = crypt.prng(42, 1)
    for _ = 1, number_of_stars do
        local x = F.floor(rnd:float(h))
        local y = F.floor(rnd:float(h))
        local l = r_star * 2
        local c = star_colors[rnd:int(1, #star_colors)]
        -- periodic sky, the square h*h around the planet repeats
        -- xi = x + i*h + w/2 ∈ [0, w]
        -- xi > 0 <=> i > (-w/2 - x)/h
        -- xi < w <=> i < (w - w/2 - x)/h
        for i = F.floor((-w/2-x)/h), F.ceiling((w/2-x)/h) do
            local xi = x + i*h + w/2
            local yi = F.even(i) and y or h-y
            if xi > 0 and xi < w then
                stars {
                    Circle { cxy=Point(xi, yi), r=r_star, fill=c },
                    Line { xy1=Point(xi, yi-l), xy2=Point(xi,yi+l), stroke=c },
                    Line { xy1=Point(xi-l, yi), xy2=Point(xi+l,yi), stroke=c },
                }
            end
        end
    end
    return stars
end

local d = h * 16/1024

if opt.sky then
    img { sky() }
end

local name, size = "LuaX", nil
if opt.name then name, size = opt.name, 4 * fh // #opt.name end
if #name == 4 then size = nil end

img {
    G {
        transform = ("translate(%d, %d) rotate(%d)"):format(w//2, h//2, inclination),
        moon(),
        ring(-1),
        planet(),
        ring(1),
        Text (name) { font_size=size, dx =  0, dy = fh/4,   fill="black", stroke="black", stroke_width=d/2 },
        Text (name) { font_size=size, dx = -d, dy = fh/4-d, fill="SeaShell" },
    },
}

if opt.text then
    img {
        Text(opt.text) {
            x = w - fh/8, y = h - fh/8,
            text_anchor = "end",
            font_size = fh/4,
            fill = "green",
        },
    }
end
