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

local F = require "F"
local crypt = require "crypt"
local qmath = require "qmath"

require "lib/demo-lib" -- to test the dependency file generation

-- The global variable `img` is an SVG object used by lsvg to produce the images
img {
    -- img can be called to add more attributes
    width = 1024,
    height = 768,
}

-- The image is divided into four quarters

local w = img.attrs.width // 2
local h = img.attrs.height // 2

img {
    viewBox = {
        width = 2*w,
        height = 2*h,
    },
    --preserveAspectRatio = "xMidYMid meet",
}

local pi = math.pi
local sin = math.sin
local rad = math.rad
local min = math.min
local abs = F.abs

---------------------------------------------------------------------
-- Top left: French flag with some text
---------------------------------------------------------------------

img {font_size=w/8, text_anchor="middle", fill="green"}

-- G defines a group that will later be added to the main image object (img)
local flag = G {
    Rect {x=0*w/3, y=0, width=w/3, height=h, fill="blue"},
    Rect {x=1*w/3, y=0, width=w/3, height=h, fill="white"},
    Rect {x=2*w/3, y=0, width=w/3, height=h, fill="red"},
}

-- another group
local title = G {
    Rect {
        x=w/6, y=h/6, width=4*w/6, height=4*h/6,
        rx=w/16,
        fill="grey", fill_opacity=0.4,
        stroke="cyan", stroke_width=w/32, stroke_opacity=0.4
    },
    -- Text given on the command line
    Text(arg[1] or "") {x = w/2, y = h/2-w/8/2},
    Text(arg[2] or "") {x = w/2, y = h/2+w/8/2},
}

---------------------------------------------------------------------
-- Top right: sin graph with a different frame
---------------------------------------------------------------------

local top_right = Frame {
    xmin = -2*pi-pi/4,  Xmin = w,
    xmax =  2*pi+pi/4,  Xmax = 2*w,
    ymin = -1.5-0.2,    Ymin = 0,
    ymax =  1.5+0.2,    Ymax = h,
}

local function graph(xmin, xmax, f)
    local n = 128
    local dx = (xmax-xmin)/n
    return F.range(0, n):map(function(i)
        local x = xmin + i*dx
        local y = f(x)
        return Point(x, y)
    end)
end

local function piratio(x)
    local k = qmath.torat(x/pi)
    local n, d = abs(k:numer():tonumber()), k:denom(k):tonumber()
    return F.str {
        x < 0 and "-" or "",
        n == 0 and "" or n == 1 and "π" or ("%dπ"):format(n),
        d == 1 and "" or ("/%d"):format(d)
    }
end

local sin_graph = G {
    -- axis
    Axis { Point(-2*pi,0), Point(2*pi,0), stroke="red", grad = {-2*pi, 2*pi, pi/2, text={fill="black", font_size=20, dy=24, fmt=piratio}}, },
    Axis { Point(0,-1.5), Point(0,1.5), stroke="red", grad = {-1.5, 1.5, 0.5, text={fill="black", font_size=20, dx=-24, fmt="%.1f"}}, },
    -- graph
    Polyline { stroke="green", fill="none" } {
        points=graph(-2*pi, 2*pi, sin)
    },
    Polyline { stroke="blue", fill="none" } {
        points=graph(-2*pi, 2*pi, function(x)
            if x == 0 then return 1 end
            return sin(x)/x
        end)
    },
    -- legend
    Text "sin(x)"   { x = -2*pi+0.4, y = -1 }   { text_anchor="start", font_size=24, fill="green" },
    Text "sin(x)/x" { x = -2*pi+0.4, y = -1.3 } { text_anchor="start", font_size=24, fill="blue" },
}

---------------------------------------------------------------------
-- Bottom left: higher level nodes (arrows, axes, ...)
---------------------------------------------------------------------

local bottom_left = Frame {
    xmin =  0,      Xmin = 0,
    xmax = 10,      Xmax = w,
    ymin = 4,       Ymin = h,
    ymax =  0,      Ymax = 2*h,
}

local lsvg_nodes = G {
    -- Arrows
    font_size = 20,
    arrowhead = 1.0,
    Arrow { Point(1, 1), Point(4, 1), stroke="red", stroke_width=2, arrowhead=0.5,
        Text "anchor=0.2" { anchor=0.2, dy=-12, fill="black" },
        Text "anchor=0.8" { anchor=0.8, dy=24, fill="black" },
    },
    Arrow { Point(5, 1), Point(9, 1), stroke="red", stroke_width=2, double=true, arrowhead=0.7,
        Text "default anchor" { dy=-12, fill="black" },
    },
    -- Axes
    Axis { Point(1, 2), Point(4, 2), stroke="red", stroke_width=2, arrowhead=0.5,
        grad = { 0, 10, 1,
            height = 6,
        },
        Text "O" { anchor=0, dx=-12, fill="black" },
        Text "x" { anchor=1, dx=12, fill="black" },
    },
    Axis { Point(5, 2), Point(9, 2), stroke="red", stroke_width=2, arrowhead=0.25,
        grad = { 42, 50, 2, 0.5,
            height = 12,
            text = {dy=32, fill="black"},
        },
        Text "y" { anchor=1, dx=12, fill="black" },
    },
    -- superscript and subscript in text elements
    Text (eqn"x^{m+n} = x^m x^n")       { xy=Point(1, 3), text_anchor="start", fill="blue" },
    Text (eqn"F_n = F_{n-1} + F_{n-2}") { xy=Point(5, 3), text_anchor="start", fill="red" },
}

---------------------------------------------------------------------
-- Bottom right: fractal tree
---------------------------------------------------------------------

local bottom_right = Frame {
    xmin = -20,     Xmin = w,
    xmax = 20,      Ymin = h,
    ymin = 0,       Xmax = 2*w,
    ymax = 40,      Ymax = 2*h,
}

local tree = G{
    stroke_linecap="round",
    Rect { x=-20, y=40, width=40, height=40, fill="skyblue" },
    Circle { cx = 15, cy = 30, r = 4.5, fill="yellow" }, -- sun
}

-- clouds
do
    local prng = crypt.prng(42, 1)
    for _ = 1, 80 do
        local x = prng:float(-15, 15)
        local y = prng:float(25, 40)
        local r = prng:float(0, min(5, 40-y))
        tree { Ellipse { cx=x, cy=y, rx=r, ry=r/3 } { fill="#EEEEEE" } }
    end
end

-- tree
do
    local k1 = 0.70
    local k2 = 0.75
    local theta1 = rad(-35)
    local theta2 = rad(19)
    local e0 = 20
    local ethr = 6
    local ke = 0.75
    local emin = 1

    local prng = crypt.prng(42, 1)
    local function grow(M0, M1, e)
        if e < emin then return 0 end

        local color = e > ethr and "brown" or "green"
        tree { Line { xy1=M0, xy2=M1, stroke=color, stroke_width=2*e } }

        local R1 = M1 + k1*(M1-M0)
        local R2 = R1:rot(M1, theta1+prng:float(-0.1, 0.1))
        local n1 = grow(M1, R2, ke*e)

        local L1 = M1 + k2*(M1-M0)
        local L2 = L1:rot(M1, theta2+prng:float(-0.1, 0.1))
        local n2 = grow(M1, L2, ke*e)

        return 1 + n1 + n2
    end

    local n = grow(Point(0, 0), Point(0, 10), e0)

    tree {
        Text "Fractal tree" { x = -10, y = 16, font_size=24, fill="brown" },
        Text(n.." segments"){ x = -10, y = 13, font_size=20, fill="brown" },
    }
end

-- and some grass
do
    local prng = crypt.prng(42, 1)
    local blades = 0
    local flowers = 0
    local theta1, theta2 = 10, 45
    for _ = 1, 500 do
        local M1 = Point(prng:float(-20, 20), prng:float(0.5, 2))
        local M0 = Point(M1:x(), 0)
        local t = sin(2*pi*M1:x()/15)
        local theta = -rad((t+1)*(theta2-theta1)/2+theta1) + prng:float(-0.2, 0.2)
        local M2 = M1:rot(M0, theta)
        tree { Line { xy1=M0, xy2=M2, stroke="green" } }
        if prng:float() < 0.18 then
            -- this is a flower
            tree { Circle { cxy=M2, r=0.2 } { stroke="white", fill="purple", stroke_width=2 } }
            flowers = flowers + 1
        else
            blades = blades + 1
        end
    end

    tree {
        Text "Random vegetation"         { x = -10, y = 10, font_size=24, fill="green" },
        Text(blades.." blades of grass") { x = -10, y = 7,  font_size=20, fill="green" },
        Text(flowers.." flowers")        { x = -10, y = 4,  font_size=20, fill="purple" },
    }
end

---------------------------------------------------------------------
-- Final image
---------------------------------------------------------------------

img {
    Raw "<!-- Generated by lsvg -->\n",
    Rect { x=0, y=0, width=2*w, height=2*h } { fill="lightgrey" },
    top_right(sin_graph),
    bottom_left(lsvg_nodes),
    bottom_right(tree),
    flag,
    title,
    Line { x1=0, x2=2*w, y1=h, y2=h } { stroke="#555", stroke_width=10 },
    Line { x1=w, x2=w, y1=0, y2=2*h } { stroke="#555", stroke_width=10 },
    Line { x1=0, x2=2*w, y1=h, y2=h } { stroke="white", stroke_width=1 },
    Line { x1=w, x2=w, y1=0, y2=2*h } { stroke="white", stroke_width=1 },
}

-- no need to generate an image here.
-- lsvg will call img:save("xxx.svg") according the its command line arguments
