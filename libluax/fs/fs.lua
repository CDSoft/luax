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

-- Load fs.lua to add new methods to strings
--@LOAD=_

local fs = require "_fs"

local F = require "F"

--[[@@@
```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).
If a component is absolute, the previous components are removed.
@@@]]

if pandoc and pandoc.path then
    function fs.join(...)
        return pandoc.path.join(F.flatten{...})
    end
else
    function fs.join(...)
        local function add_path(ps, p)
            if p:match("^"..fs.sep) then return F{p} end
            ps[#ps+1] = p
            return ps
        end
        return F{...}
            :flatten()
            :fold(add_path, F{})
            :str(fs.sep)
    end
end

--[[@@@
```lua
fs.splitpath(path)
```
return a list of path components.
@@@]]

function fs.splitpath(path)
    if path == "" then return F{} end
    local components = path:split "[/\\]+"
    if components[1] == "" then components[1] = fs.sep end
    return components
end

--[[@@@
```lua
fs.findpath(name)
```
returns the full path of `name` if `name` is found in `$PATH` or `nil`.
@@@]]

function fs.findpath(name)
    local function exists_in(path) return fs.is_file(fs.join(path, name)) end
    local path = os.getenv("PATH")
        :split(fs.path_sep)
        :find(exists_in)
    if path then return fs.join(path, name) end
    return nil, name..": not found in $PATH"
end

--[[@@@
```lua
fs.rmdir(path, [params])
```
deletes the directory `path` and its content recursively.
@@@]]

if pandoc and pandoc.system then
    function fs.rmdir(path)
        pandoc.system.remove_directory(path, true)
        return true
    end
else
    function fs.rmdir(path)
        fs.walk(path, {reverse=true}):foreach(fs.rm)
        return fs.rm(path)
    end
end

--[[@@@
```lua
fs.walk([path], [{reverse=true|false, links=true|false, cross=true|false}])
```
returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory).

Options:

- `stat`: returns the list of stat results instead of just filenames
- `reverse`: the list is built in a reverse order
  (suitable for recursive directory removal)
- `cross`: walk across several devices
- `func`: function applied to the current file or directory.
  `func` takes two parameters (path of the file or directory and the stat object returned by `fs.stat`)
  and returns a boolean (to continue or not walking recursively through the subdirectories)
  and the value to add to the list.
@@@]]

function fs.walk(path, options)
    options = options or {}
    local return_stat = options.stat
    local reverse = options.reverse
    local cross_device = options.cross
    local func = options.func
              or return_stat and function(_, stat) return true, stat end
              or function(name, _) return true, name end
    local dirs = {path or "."}
    local acc_files = {}
    local acc_dirs = {}
    local seen = {}
    local dev0 = nil
    local function already_seen(name)
        local inode = fs.inode(name)
        if not inode then return true end
        dev0 = dev0 or inode.dev
        if dev0 ~= inode.dev and not cross_device then
            return true
        end
        if not seen[inode.dev] then
            seen[inode.dev] = {[inode]=true}
            return false
        end
        if not seen[inode.dev][inode.ino] then
            seen[inode.dev][inode.ino] = true
            return false
        end
        return true
    end
    while #dirs > 0 do
        local dir = table.remove(dirs)
        if not already_seen(dir) then
            local names = fs.dir(dir)
            if names then
                table.sort(names)
                for i = 1, #names do
                    local name = dir..fs.sep..names[i]
                    local stat = fs.stat(name)
                    if stat then
                        if stat.type == "directory" then
                            local continue, obj = func(name, stat)
                            if continue then
                                dirs[#dirs+1] = name
                            end
                            if obj then
                                if reverse then table.insert(acc_dirs, 1, obj)
                                else acc_dirs[#acc_dirs+1] = obj
                                end
                            end
                        else
                            local _, obj = func(name, stat)
                            if obj then
                                acc_files[#acc_files+1] = obj
                            end
                        end
                    end
                end
            end
        end
    end
    return F.concat(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

if pandoc and pandoc.system then
    function fs.with_tmpfile(f)
        return pandoc.system.with_temporary_directory("luax", function(tmpdir)
            return f(tmpdir/"tmpfile")
        end)
    end
else
    function fs.with_tmpfile(f)
        local tmp = fs.tmpfile()
        local ret = {f(tmp)}
        fs.rm(tmp)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.
@@@]]

if pandoc and pandoc.system then
    function fs.with_tmpdir(f)
        return pandoc.system.with_temporary_directory("luax", f)
    end
else
    function fs.with_tmpdir(f)
        local tmp = fs.tmpdir()
        local ret = {f(tmp)}
        fs.rmdir(tmp)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.with_dir(path, f)
```
changes the current working directory to `path` and calls `f()`.
@@@]]

if pandoc and pandoc.system then
    fs.with_dir = pandoc.system.with_working_directory
elseif fs.chdir then
    function fs.with_dir(path, f)
        local old = fs.getcwd()
        fs.chdir(path)
        local ret = {f()}
        fs.chdir(old)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.read(filename)
```
returns the content of the text file `filename`.
@@@]]

function fs.read(name)
    local f<close>, oerr = io.open(name, "r")
    if not f then return f, oerr end
    return f:read("a")
end

--[[@@@
```lua
fs.write(filename, ...)
```
write `...` to the text file `filename`.
@@@]]

function fs.write(name, ...)
    local content = F{...}:flatten():str()
    local f<close>, oerr = io.open(name, "w")
    if not f then return f, oerr end
    return f:write(content)
end

--[[@@@
```lua
fs.read_bin(filename)
```
returns the content of the binary file `filename`.
@@@]]

function fs.read_bin(name)
    local f<close>, oerr = io.open(name, "rb")
    if not f then return f, oerr end
    return f:read("a")
end

--[[@@@
```lua
fs.write_bin(filename, ...)
```
write `...` to the binary file `filename`.
@@@]]

function fs.write_bin(name, ...)
    local content = F{...}:flatten():str()
    local f<close>, oerr = io.open(name, "wb")
    if not f then return f, oerr end
    return f:write(content)
end

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `fs` package are added to the string module:

@@@]]

--[[@@@
```lua
path:dir()              == fs.dir(path)
path:stat()             == fs.stat(path)
path:inode()            == fs.inode(path)
path:basename()         == fs.basename(path)
path:dirname()          == fs.dirname(path)
path:splitext()         == fs.splitext(path)
path:ext()              == fs.ext(path)
path:chext()            == fs.chext(path)
path:realpath()         == fs.realpath(path)
path:readlink()         == fs.readlink(path)
path:absname()          == fs.absname(path)
path1 / path2           == fs.join(path1, path2)
path:is_file()          == fs.is_file(path)
path:is_dir()           == fs.is_dir(path)
path:findpath()         == fs.findpath(path)
path:walk(...)          == fs.walk(path, ...)
```
@@@]]

string.dir              = fs.dir
string.stat             = fs.stat
string.inode            = fs.inode
string.basename         = fs.basename
string.dirname          = fs.dirname
string.splitext         = fs.splitext
string.ext              = fs.ext
string.chext            = fs.chext
string.splitpath        = fs.splitpath
string.realpath         = fs.realpath
string.readlink         = fs.readlink
string.absname          = fs.absname
string.is_file          = fs.is_file
string.is_dir           = fs.is_dir
string.findpath         = fs.findpath
string.walk             = fs.walk

getmetatable("").__div  = fs.join

return fs
