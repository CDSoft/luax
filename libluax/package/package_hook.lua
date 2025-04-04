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

--@LOAD=_

local F = require "F"
local sys = require "sys"

-- inspired by https://stackoverflow.com/questions/60283272/how-to-get-the-exact-path-to-the-script-that-was-loaded-in-lua

-- This module wraps package searchers in a function that tracks package paths.
-- The paths are stored in package.modpath, which can be used to generate dependency files
-- for [ypp](https://codeberg.org/cdsoft/ypp) or [panda](https://codeberg.org/cdsoft/panda).

--[=[-----------------------------------------------------------------------@@@
# package

The standard Lua package `package` is added some information about packages loaded by LuaX.
@@@]=]

--[[@@@
```lua
package.modpath      -- { module_name = module_path }
```
> table containing the names of the loaded packages and their actual paths.
>
> `package.modpath` contains the names of the packages loaded by `require`, `dofile`, `loadfile` and `import`.
@@@]]

package.modpath = F{}

local function wrap_searcher(searcher)
    return function(modname)
        local loader, path = searcher(modname)
        if type(loader) == "function" then
            package.modpath[modname] = path
        end
        return loader, path
    end
end

local first_external_searcher = sys.libc=="lua" and 3 or 2
for i = first_external_searcher, #package.searchers do
    package.searchers[i] = wrap_searcher(package.searchers[i])
end

local function wrap(func)
    return function(filename, ...)
        if filename ~= nil then
            package.modpath[filename] = filename
        end
        return func(filename, ...)
    end
end

dofile = wrap(dofile)
loadfile = wrap(loadfile)
