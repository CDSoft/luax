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

`package.modpath` also contains the names of the files loaded by `import`.

The imported files are stored in a cache.
Subsequent calls to `import` can read files from the cache instead of actually reloading them.
The cache can be disabled with an optional parameter:

```lua
local conf = import("myconf.lua", {cache=false})
```
Reloads the file instead of using the cache.

@@@]]

local F = require "F"

local cache = {}

return setmetatable({
    files = F{},
}, {
    __call = function(self, fname, opt)
        local use_cache = not opt or opt.cache==nil or opt.cache
        if use_cache then
            local mod = cache[fname]
            if mod then return mod end
        end
        local mod = setmetatable({}, {__index = _ENV})
        assert(loadfile(fname, "t", mod))()
        if F.not_elem(fname, self.files) then
            self.files[#self.files+1] = fname
            package.modpath[fname] = fname
        end
        if use_cache then cache[fname] = mod end
        return mod
    end,
})
