local license = [[
This file is part of LuaX.

LuaX is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

LuaX is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with LuaX.  If not, see <https://www.gnu.org/licenses/>.

For further information about LuaX you can visit
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

fig {
    raw (F.unlines { "<!--", license:trim(), "-->" })
}

local w = tonumber(opt.size[1]) or 1024
local h = tonumber(opt.size[2]) or w
local fh = h/4

fig {
    width = w,
    height = h,
    viewbox { x=0, y=0, width=w, height=h },
    font_size = fh,
    text_anchor = "middle",
    font_family = "Arial, Liberation Sans, sans-serif",
    font_weight = "bold",
}

output_configuration {
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

fig {
    defs {
        linearGradient { id="PlanetGradient", x1=0, x2=0, y1=0, y2=1,
            stop { offset="0%", stop_color="lightgrey" },
            stop { offset="15%", stop_color="cyan" },
            stop { offset="30%", stop_color="orange" },
            stop { offset="70%", stop_color="green" },
            stop { offset="85%", stop_color="blue" },
            stop { offset="100%", stop_color="lightgrey" },
        },
        linearGradient { id="MoonGradient", x1=0, x2=0, y1=0, y2=1,
            stop { offset="0%", stop_color="darkgrey" },
            stop { offset="50%", stop_color="lightgrey" },
            stop { offset="100%", stop_color="darkgrey" },
        },
        linearGradient { id="TopRingGradient", x1=0, x2=0, y1=0, y2=1,
            stop { offset="0%", stop_color="black", stop_opacity="0" },
            stop { offset="49%", stop_color="grey", stop_opacity="0" },
            stop { offset="50%", stop_color="grey", stop_opacity="1" },
            stop { offset="100%", stop_color="darkgrey", stop_opacity="1" },
        },
        linearGradient { id="BottomRingGradient", x1=0, x2=0, y1=0, y2=1,
            stop { offset="0%", stop_color="black", stop_opacity="1" },
            stop { offset="50%", stop_color="grey", stop_opacity="1" },
            stop { offset="51%", stop_color="grey", stop_opacity="0" },
            stop { offset="100%", stop_color="darkgrey", stop_opacity="0" },
        },
    },
}

local function planet()
    return circle {
        r = r_planet,
        fill = "url(#PlanetGradient)",
    }
end

local function moon()
    return circle {
        V(r_orbit, 0):rot(-math.pi/4):cxy(),
        r = r_moon,
        fill = "url(#MoonGradient)",
    }
end

local function ring(dir)
    return ellipse {
        rx = r_ring,
        ry = r_ring*0.33,
        fill_opacity = 0,
        stroke = dir > 0 and "url(#TopRingGradient)" or "url(#BottomRingGradient)",
        stroke_width = ring_width,
    }
end

local function sky()
    local stars = g {
        stroke_width = h * 3/1024,
        stroke_linecap = "round",
    }
    local star_colors = { "gold", "red", "cyan", "brown" }
    for i, c in ipairs(star_colors) do
        local l = r_star * 2
        stars {
            symbol {
                id = "star"..i,
                x = -l, y = -l, width = 2*l, height = 2*l,
                viewbox { x=-l, y=-l, width=2*l, height=2*l },
                circle { cx=0, cy=0, r=r_star, fill=c },
                line { x1=-l, x2=l, stroke=c },
                line { y1=-l, y2=l, stroke=c },
            },
        }
    end
    local rnd = crypt.prng(42, 1)
    for _ = 1, number_of_stars do
        local x = F.floor(rnd:float(h))
        local y = F.floor(rnd:float(h))
        local c = rnd:int(1, #star_colors)
        -- periodic sky, the square h*h around the planet repeats
        -- xi = x + i*h + w/2 ∈ [0, w]
        -- xi > 0 <=> i > (-w/2 - x)/h
        -- xi < w <=> i < (w - w/2 - x)/h
        for i = F.floor((-w/2-x)/h), F.ceiling((w/2-x)/h) do
            local xi = x + i*h + w/2
            local yi = F.even(i) and y or h-y
            if xi > 0 and xi < w then
                stars {
                    use { href="#star"..c, x=xi, y=yi }
                }
            end
        end
    end
    return stars
end

local d = h * 16/1024

if opt.sky then
    fig { sky() }
end

local name, size = "LuaX", nil
if opt.name then name, size = opt.name, 4 * fh // #opt.name end
if #name == 4 then size = nil end

fig {
    g {
        transform = ("translate(%d, %d) rotate(%d)"):format(w//2, h//2, inclination),
        moon(),
        ring(-1),
        planet(),
        ring(1),
        text (name) { font_size=size, dx =  0, dy = fh/4,   fill="black", stroke="black", stroke_width=d/2 },
        text (name) { font_size=size, dx = -d, dy = fh/4-d, fill="SeaShell" },
    },
}

if opt.text then
    fig {
        text(opt.text) {
            x = w - fh/8, y = h - fh/8,
            text_anchor = "end",
            font_size = fh/4,
            fill = "green",
        },
    }
end
