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

-- Load lz4.lua to add new methods to strings
--@LOAD=_

--[[------------------------------------------------------------------------@@@
## String methods

The `lz4` functions are also available as `string` methods:
@@@]]

local _, lz4 = pcall(require, "_lz4")
lz4 = _ and lz4

if not lz4 then

    lz4 = {}

    local fs = require "fs"
    local sh = require "sh"

    function lz4.lz4(s)
        return fs.with_tmpfile(function(tmp)
            assert(sh.write("lz4 -q -z -BD -9 --frame-crc -f -", tmp)(s))
            return fs.read_bin(tmp)
        end)
    end

    function lz4.unlz4(s)
        return fs.with_tmpfile(function(tmp)
            assert(sh.write("lz4 -q -d -f -", tmp)(s))
            return fs.read_bin(tmp)
        end)
    end

end

--[[@@@
```lua
s:lz4()         == lz4.lz4(s)
s:unlz4()       == lz4.unlz4(s)
```
@@@]]

function string.lz4(s)      return lz4.lz4(s) end
function string.unlz4(s)    return lz4.unlz4(s) end

return lz4
