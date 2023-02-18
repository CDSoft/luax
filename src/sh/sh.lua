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

--@LOAD

--[[------------------------------------------------------------------------@@@
## Shell
@@@]]

--[[@@@
```lua
local sh = require "sh"
```
@@@]]
local sh = {}

local F = require "F"

--[[@@@
```lua
sh.run(...)
```
Runs the command `...` with `os.execute`.
@@@]]

function sh.run(...)
    local cmd = F.flatten{...}:unwords()
    return os.execute(cmd)
end

--[[@@@
```lua
sh.read(...)
```
Runs the command `...` with `io.popen`.
When `sh.read` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `io.popen`.
@@@]]

function sh.read(...)
    local cmd = F.flatten{...}:unwords()
    local p, popen_err = io.popen(cmd, "r")
    if not p then return p, popen_err end
    local out = p:read("a")
    local ok, exit, ret = p:close()
    if ok then
        return out
    else
        return ok, exit, ret
    end
end

--[[@@@
```lua
sh.write(...)(data)
```
Runs the command `...` with `io.popen` and feeds `stdin` with `data`.
`sh.write` returns the same values returned by `os.execute`.
@@@]]

function sh.write(...)
    local cmd = F.flatten{...}:unwords()
    return function(data)
        local p, popen_err = io.popen(cmd, "w")
        if not p then return p, popen_err end
        p:write(data)
        return p:close()
    end
end

if pandoc then

--[[@@@
```lua
sh.pipe(...)(data)
```
Runs the command `...` with `pandoc.pipe` and feeds `stdin` with `data`.
When `sh.pipe` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `pandoc.pipe`.
@@@]]

    function sh.pipe(...)
        local cmd = F.flatten{...}
        return function(data)
            local ok, out = pcall(pandoc.pipe, cmd:head(), cmd:tail(), data)
            if not ok then return nil, out end
            return out
        end
    end

end

return sh
