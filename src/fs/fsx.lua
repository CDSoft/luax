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
## Additional functions (Lua)
@@@]]

local fs = require "fs"

local sys = require "sys"

local flatten = require"fun".flatten
local map = require"fun".map

--[[@@@
```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).
@@@]]

function fs.join(...)
    return table.concat({...}, fs.sep)
end

--[[@@@
```lua
fs.is_file(name)
```
returns `true` if `name` is a file.
@@@]]

function fs.is_file(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "file"
end

--[[@@@
```lua
fs.is_dir(name)
```
returns `true` if `name` is a directory.
@@@]]

function fs.is_dir(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "directory"
end

--[[@@@
```lua
fs.findpath(name)
```
returns the full path of `name` if `name` is found in `$PATH` or `nil`.
@@@]]

function fs.findpath(name)
    for _, path in ipairs(os.getenv("PATH"):split(sys.os == "windows" and ";" or ":")) do
        local full_path = fs.join(path, name)
        if fs.is_file(full_path) then return full_path end
    end
    return nil, "not found in $PATH"
end

--[[@@@
```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent directories.
@@@]]

function fs.mkdirs(path)
    if path == "" or fs.stat(path) then return end
    fs.mkdirs(fs.dirname(path))
    fs.mkdir(path)
end

--[[@@@
```lua
fs.mv(old_name, new_name)
```
alias for `fs.rename(old_name, new_name)`.
@@@]]

fs.mv = fs.rename

--[[@@@
```lua
fs.rm(name)
```
alias for `fs.remove(name)`.
@@@]]

fs.rm = fs.remove

--[[@@@
```lua
fs.rmdir(path, [params])
```
deletes the directory `path` and its content recursively.
@@@]]

function fs.rmdir(path)
    map(fs.rm, fs.walk(path, true))
    return fs.rm(path)
end

--[[@@@
```lua
fs.walk([path], [reverse])
```
returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory). If `reverse` is true, the list is built in a reverse order
(suitable for recursive directory removal)
@@@]]

function fs.walk(path, reverse)
    if type(path) == "boolean" and reverse == nil then
        path, reverse = nil, path
    end
    local dirs = {path or "."}
    local acc_files = {}
    local acc_dirs = {}
    while #dirs > 0 do
        local dir = table.remove(dirs)
        local names = fs.dir(dir)
        if names then
            table.sort(names)
            for i = 1, #names do
                local name = dir..fs.sep..names[i]
                local stat = fs.stat(name)
                if stat then
                    if stat.type == "directory" then
                        dirs[#dirs+1] = name
                        if reverse then acc_dirs = {name, acc_dirs}
                        else acc_dirs[#acc_dirs+1] = name
                        end
                    else
                        acc_files[#acc_files+1] = name
                    end
                end
            end
        end
    end
    return flatten(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

function fs.with_tmpfile(f)
    local tmp = os.tmpname()
    f(tmp)
    fs.rm(tmp)
end

--[[@@@
```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.
@@@]]

function fs.with_tmpdir(f)
    local tmp = os.tmpname()
    fs.rm(tmp)
    fs.mkdir(tmp)
    f(tmp)
    fs.rmdir(tmp)
end
