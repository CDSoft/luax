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
https://github.com/cdsoft/luax
--]]

-- Load lz4.lua to add new methods to strings
--@LOAD=_

--[[------------------------------------------------------------------------@@@
## String methods

The `lz4` functions are also available as `string` methods:
@@@]]

local lz4 = require "_lz4"

--[[@@@
```lua
s:lz4()         == lz4.lz4(s)
s:unlz4()       == lz4.unlz4(s)
```
@@@]]

string.lz4      = lz4.lz4
string.unlz4    = lz4.unlz4

return lz4
