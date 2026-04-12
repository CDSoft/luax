--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/ypp
--]]

local F = require "F"

--[[@@@
* `defer(func, ...)`: emit a unique tag that will later be replaced by the result of `func(...)` if `func` is callable.
* `defer(table, ...)`: emit a unique tag that will later be replaced by the concatenation of `table` (one item per line).

E.g.:

@q[=====[
```
@@ N = 0
total = @defer(function() return N end) (should be "2")
...
@@(N = N+1)
@@(N = N+1)
```
]=====]
@@@]]

local start_tag, end_tag = "\x02⟪defer:", "⟫\x03"
local tag_id = 0

local deferred_functions = F{}

local function callable(x)
    local t, mt = type(x), getmetatable(x)
    return t=="function" or (type(mt)=="table" and mt.__call)
end

local function defer(x, ...)
    tag_id = tag_id + 1
    local tag = start_tag..tag_id..end_tag
    deferred_functions[tag] = callable(x) and F.partial(x, ...)
                              or function() return F.flatten(x):map(tostring):unlines() end
    return tag
end

local function replace(s)
    return s : gsub(start_tag.."%d+"..end_tag, deferred_functions : mapt(F.call))
end

return setmetatable({
    defer = defer,
    replace = replace,
}, {
    __call = function(self, s, ...) return self.defer(s, ...) end,
})
