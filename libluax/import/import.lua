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

--@LIB

--[[------------------------------------------------------------------------@@@
# import: import Lua scripts into tables

```lua
local import = require "import"
```

The import module can be used to manage simple configuration files,
configuration parameters being global variables defined in the configuration file.

```lua
local conf = import "myconf.lua"
```
Evaluates `"myconf.lua"` in a new table and returns this table.
All files are tracked in `import.files`.

@@@]]

local F = require "F"

local import = {}
local mt = {}

import.files = F{}

function mt.__call(self, fname)
    local mod = setmetatable({}, {__index = _ENV})
    assert(loadfile(fname, "t", mod))()
    if F.not_elem(fname, self.files) then
        self.files[#self.files+1] = fname
        table.sort(self.files)
    end
    return mod
end

return setmetatable(import, mt)
