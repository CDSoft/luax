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

--[[------------------------------------------------------------------------@@@
# Terminal

`term` provides some functions to deal with the terminal in a quite portable way.
It is heavily inspired by:

- [lua-term](https://github.com/hoelzro/lua-term/): Terminal operations for Lua
- [nocurses](https://github.com/osch/lua-nocurses/): A terminal screen manipulation library

```lua
local term = require "term"
```
@@@]]

local term = require "_term"

local ESC = '\027'
local CSI = ESC..'['

--[[------------------------------------------------------------------------@@@
## Colors

The table `term.colors` contain objects that can be used to build
colorized string with ANSI sequences.

An object `term.color.X` can be used:

- as a string
- as a function
- in combination with other color attributes

``` lua
-- change colors in a string
" ... " .. term.color.X .. " ... "

-- change colors for a string and reset colors at the end of the string
term.color.X("...")

-- build a complex color with attributes
local c = term.color.red + term.color.italic + term.color.oncyan
```
@@@]]

local color_mt, color_reset
color_mt = {
    __tostring = function(self) return self.value end,
    __concat = function(self, other) return tostring(self)..tostring(other) end,
    __call = function(self, s) return self..s..color_reset end,
    __add = function(self, other) return setmetatable({value=self..other}, color_mt) end,
}
local function color(value) return setmetatable({value=CSI..tostring(value).."m"}, color_mt) end
--                                @@@`term.color` field     Description                         @@@
--                                @@@---------------------- ------------------------------------@@@
term.color = {
    -- attributes
    reset       = color(0),     --@@@reset                  reset the colors                    @@@
    clear       = color(0),     --@@@clear                  same as reset                       @@@
    default     = color(0),     --@@@default                same as reset                       @@@
    bright      = color(1),     --@@@bright                 bold or more intense                @@@
    bold        = color(1),     --@@@bold                   same as bold                        @@@
    dim         = color(2),     --@@@dim                    thiner or less intense              @@@
    italic      = color(3),     --@@@italic                 italic (sometimes inverse or blink) @@@
    underline   = color(4),     --@@@underline              underlined                          @@@
    blink       = color(5),     --@@@blink                  slow blinking (less than 150 bpm)   @@@
    fast        = color(6),     --@@@fast                   fast blinking (more than 150 bpm)   @@@
    reverse     = color(7),     --@@@reverse                swap foreground and background      @@@
    hidden      = color(8),     --@@@hidden                 hidden text                         @@@
    strike      = color(9),     --@@@strike                 strike or crossed-out               @@@
    -- foreground
    black       = color(30),    --@@@black                  black foreground                    @@@
    red         = color(31),    --@@@red                    red foreground                      @@@
    green       = color(32),    --@@@green                  green foreground                    @@@
    yellow      = color(33),    --@@@yellow                 yellow foreground                   @@@
    blue        = color(34),    --@@@blue                   blue foreground                     @@@
    magenta     = color(35),    --@@@magenta                magenta foreground                  @@@
    cyan        = color(36),    --@@@cyan                   cyan foreground                     @@@
    white       = color(37),    --@@@white                  white foreground                    @@@
    -- background
    onblack     = color(40),    --@@@onblack                black background                    @@@
    onred       = color(41),    --@@@onred                  red background                      @@@
    ongreen     = color(42),    --@@@ongreen                green background                    @@@
    onyellow    = color(43),    --@@@onyellow               yellow background                   @@@
    onblue      = color(44),    --@@@onblue                 blue background                     @@@
    onmagenta   = color(45),    --@@@onmagenta              magenta background                  @@@
    oncyan      = color(46),    --@@@oncyan                 cyan background                     @@@
    onwhite     = color(47),    --@@@onwhite                white background                    @@@
}

color_reset = term.color.reset

--[[------------------------------------------------------------------------@@@
## Cursor

The table `term.cursor` contains functions to change the shape of the cursor:

``` lua
-- turns the cursor into a blinking vertical thin bar
term.cursor.bar_blink()
```

@@@]]

local function cursor(shape)
    shape = CSI..shape..' q'
    return function()
        io.stdout:write(shape)
    end
end

--                                  @@@`term.cursor` field      Description                         @@@
--                                  @@@------------------------ ------------------------------------@@@
term.cursor = {
    reset           = cursor(0),  --@@@reset                    reset to the initial shape          @@@
    block_blink     = cursor(1),  --@@@block_blink              blinking block cursor               @@@
    block           = cursor(2),  --@@@block                    fixed block cursor                  @@@
    underline_blink = cursor(3),  --@@@underline_blink          blinking underline cursor           @@@
    underline       = cursor(4),  --@@@underline                fixed underline cursor              @@@
    bar_blink       = cursor(5),  --@@@bar_blink                blinking bar cursor                 @@@
    bar             = cursor(6),  --@@@bar                      fixed bar cursor                    @@@
}

--[[------------------------------------------------------------------------@@@
## Terminal

@@@]]

local function f(fmt)
    local function w(h, ...)
        if io.type(h) ~= 'file' then
            return w(io.stdout, h, ...)
        end
        return h:write(fmt:format(...))
    end
    return w
end

--[[@@@
``` lua
term.reset()
```
resets the colors and the cursor shape.
@@@]]
term.reset    = f(color_reset..     -- reset colors
                  CSI.."0 q"..      -- reset cursor shape
                  CSI..'?25h'       -- restore cursor
                 )

--[[@@@
``` lua
term.clear()
term.clearline()
term.cleareol()
term.clearend()
```
clears the terminal, the current line, the end of the current line or from the cursor to the end of the terminal.
@@@]]
term.clear       = f(CSI..'1;1H'..CSI..'2J')
term.clearline   = f(CSI..'2K'..CSI..'E')
term.cleareol    = f(CSI..'K')
term.clearend    = f(CSI..'J')

--[[@@@
``` lua
term.pos(row, col)
```
moves the cursor to the line `row` and the column `col`.
@@@]]
term.pos         = f(CSI..'%d;%dH')

--[[@@@
``` lua
term.save_pos()
term.restore_pos()
```
saves and restores the position of the cursor.
@@@]]
term.save_pos    = f(CSI..'s')
term.restore_pos = f(CSI..'u')

--[[@@@
``` lua
term.up([n])
term.down([n])
term.right([n])
term.left([n])
```
moves the cursor by `n` characters up, down, right or left.
@@@]]
term.up          = f(CSI..'%d;A')
term.down        = f(CSI..'%d;B')
term.right       = f(CSI..'%d;C')
term.left        = f(CSI..'%d;D')

--[[------------------------------------------------------------------------@@@
## Prompt

The prompt function is a basic prompt implementation
to display a prompt and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap)
is highly recommended for a better user experience on Linux.
@@@]]

--[[@@@
```lua
s = term.prompt(p)
```
prints `p` and waits for a user input
@@@]]

function term.prompt(p)
    if p and term.isatty() then
        io.write(p)
        io.flush()
    end
    return io.read "l"
end

return term
