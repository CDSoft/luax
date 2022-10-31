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
# LuaX interactive usage

The `luax` module provides a few functions for the interactive mode.
These functions are also made available to LuaX scripts.

In interactive mode, these functions are available as global functions.
`luax.pretty`{.lua} is used by the LuaX REPL to print results.

```lua
local luax = require "luax"
```
@@@]]

local luax = {}

local F = require "fun"

--[[@@@
```lua
luax.F
```
is the `fun` module.
@@@]]

luax.F = F

--[[@@@
```lua
luax.pretty(x)
```
returns a string representing `x` with nice formatting for tables and numbers.

```lua
luax.base(b)
```
changes the format of integers. `b` can be `10` (decimal
numbers), `16` (hexadecimal numbers), `8` (octal numbers), a custom format
string or `nil` (to reset the integer format).

```lua
luax.precision(len, frac)
```
changes the format of floats. `len` is the
total number of characters and `frac` the number of decimals after the floating
point (`frac` can be `nil`). `len` can also be a string (custom format string)
or `nil` (to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or `nil` (to
reset the integer format).
@@@]]

local float_format = "%s"
local int_format = "%s"

function luax.precision(len, frac)
    float_format =
        type(len) == "string"                               and len
        or type(len) == "number" and type(frac) == "number" and ("%%%s.%sf"):format(len, frac)
        or type(len) == "number" and frac == nil            and ("%%%sf"):format(len, frac)
        or "%s"
end

function luax.base(b)
    int_format =
        type(b) == "string" and b
        or b == 10          and "%s"
        or b == 16          and "0x%x"
        or b == 8           and "0o%o"
        or "%s"
end

function luax.pretty(x, int_fmt, float_fmt)
    return F.show(x, int_fmt or int_format, float_fmt or float_format)
end

--[[@@@
```lua
luax.inspect(x)
```
calls `inspect(x)` to build a human readable
representation of `x` (see the `inspect` package).
@@@]]

local inspect = require "inspect"

local remove_all_metatables = function(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
end

local default_options = {
    process = remove_all_metatables,
}

function luax.inspect(x, options)
    return inspect(x, F.merge{default_options, options})
end

--[[@@@
```lua
luax.printi(x)
```
prints `inspect(x)` (without the metatables).
@@@]]

function luax.printi(x)
    print(luax.inspect(x))
end

return luax
