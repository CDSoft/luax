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

-- Load lzip.lua to add new methods to strings
--@LOAD=_

local has_lzip, lzip = pcall(require, "_lzip")

if not has_lzip then

    lzip = {}

    local fs = require "fs"
    local sh = require "sh"

    function lzip.lzip(s, level)
        return fs.with_tmpdir(function(tmp)
            local input = tmp/"data"
            local output = tmp/"data.lz"
            assert(fs.write_bin(input, s))
            assert(sh.run(
                "lzip -q",
                "-"..(level or 6),
                input,
                "-o", output))
            return assert(fs.read_bin(output))
        end)
    end

    function lzip.unlzip(s)
        return fs.with_tmpdir(function(tmp)
            local input = tmp/"data.lz"
            local output = tmp/"data"
            assert(fs.write_bin(input, s))
            assert(sh.run("lzip -q -d", input, "-o", output))
            return assert(fs.read_bin(output))
        end)
    end

end

--[[------------------------------------------------------------------------@@@
## String methods

The `lzip` functions are also available as `string` methods:
@@@]]

--[[@@@
```lua
s:lzip()        == lzip.lzip(s)
s:unlzip()      == lzip.unlzip(s)
```
@@@]]

string.lzip     = lzip.lzip
string.unlzip   = lzip.unlzip

return lzip
