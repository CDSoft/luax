-- prompt module
-- @LOAD

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
# prompt: Prompt module

The prompt module is a basic prompt implementation
to display a prompt and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap)
is highly recommended for a better user experience on Linux.

```lua
local prompt = require "prompt"
```
@@@]]

local prompt = {}

--[[@@@
```lua
s = prompt.read(p)
```
prints `p` and waits for a user input
@@@]]

function prompt.read(p)
    io.stdout:write(p)
    io.stdout:flush()
    return io.stdin:read "l"
end

--[[@@@
```lua
prompt.clear()
```
clears the screen
@@@]]

function prompt.clear()
    io.stdout:write "\x1b[1;1H\x1b[2J"
end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return prompt
