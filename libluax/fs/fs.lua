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

local _, fs = pcall(require, "_fs")
fs = _ and fs

local F = require "F"

-- Pure Lua / Pandoc Lua implementation
if not fs then
    fs = {}

    local sh = require "sh"

    if pandoc and pandoc.path then
        fs.sep = pandoc.path.separator
        fs.path_sep = pandoc.path.search_path_separator
    else
        fs.sep = package.config:match("^([^\n]-)\n")
        fs.path_sep = fs.sep == '\\' and ";" or ":"
    end

    if pandoc and pandoc.system then
        fs.getcwd = pandoc.system.get_working_directory
    else
        function fs.getcwd()
            return sh.read "pwd" : trim() ---@diagnostic disable-line:undefined-field
        end
    end

    if pandoc and pandoc.system then
        fs.dir = F.compose{F, pandoc.system.list_directory}
    else
        function fs.dir(path)
            return sh.read("ls", path) : lines() : sort() ---@diagnostic disable-line:undefined-field
        end
    end

    function fs.remove(name)
        return os.remove(name)
    end

    function fs.rename(old_name, new_name)
        return os.rename(old_name, new_name)
    end

    function fs.copy(source_name, target_name)
        local from, err_from = io.open(source_name, "rb")
        if not from then return from, err_from end
        local to, err_to = io.open(target_name, "wb")
        if not to then from:close(); return to, err_to end
        while true do
            local block = from:read(64*1024)
            if not block then break end
            local ok, err = to:write(block)
            if not ok then
                from:close()
                to:close()
                return ok, err
            end
        end
        from:close()
        to:close()
    end

    if pandoc and pandoc.system then
        fs.mkdir = pandoc.system.make_directory
    else
        function fs.mkdir(path)
            return sh.run("mkdir", path)
        end
    end

    local S_IRUSR = 1 << 8
    local S_IWUSR = 1 << 7
    local S_IXUSR = 1 << 6
    local S_IRGRP = 1 << 5
    local S_IWGRP = 1 << 4
    local S_IXGRP = 1 << 3
    local S_IROTH = 1 << 2
    local S_IWOTH = 1 << 1
    local S_IXOTH = 1 << 0

    fs.uR = S_IRUSR
    fs.uW = S_IWUSR
    fs.uX = S_IXUSR
    fs.aR = S_IRUSR|S_IRGRP|S_IROTH
    fs.aW = S_IWUSR|S_IWGRP|S_IWOTH
    fs.aX = S_IXUSR|S_IXGRP|S_IXOTH
    fs.gR = S_IRGRP
    fs.gW = S_IWGRP
    fs.gX = S_IXGRP
    fs.oR = S_IROTH
    fs.oW = S_IWOTH
    fs.oX = S_IXOTH

    function fs.stat(name)
        local st = sh.read("LC_ALL=C", "stat", "-L", "-c '%s;%Y;%X;%W;%F;%f'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        local size, mtime, atime, ctime, type, mode = st:trim():split ";":unpack()
        mode = tonumber(mode, 16)
        if type == "regular file" then type = "file" end
        return F{
            name = name,
            size = tonumber(size),
            mtime = tonumber(mtime),
            atime = tonumber(atime),
            ctime = tonumber(ctime),
            type = type,
            mode = mode,
            uR = (mode & S_IRUSR) ~= 0,
            uW = (mode & S_IWUSR) ~= 0,
            uX = (mode & S_IXUSR) ~= 0,
            gR = (mode & S_IRGRP) ~= 0,
            gW = (mode & S_IWGRP) ~= 0,
            gX = (mode & S_IXGRP) ~= 0,
            oR = (mode & S_IROTH) ~= 0,
            oW = (mode & S_IWOTH) ~= 0,
            oX = (mode & S_IXOTH) ~= 0,
            aR = (mode & (S_IRUSR|S_IRGRP|S_IROTH)) ~= 0,
            aW = (mode & (S_IWUSR|S_IWGRP|S_IWOTH)) ~= 0,
            aX = (mode & (S_IXUSR|S_IXGRP|S_IXOTH)) ~= 0,
        }
    end

    function fs.inode(name)
        local st = sh.read("LC_ALL=C", "stat", "-L", "-c '%d;%i'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        local dev, ino = st:trim():split ";":unpack()
        return F{
            ino = tonumber(ino),
            dev = tonumber(dev),
        }
    end

    function fs.chmod(name, ...)
        local mode = {...}
        if type(mode[1]) == "string" then
            return sh.run("chmod", "--reference="..mode[1], name, "2>/dev/null")
        else
            return sh.run("chmod", ("%o"):format(F(mode):fold(F.op.bor, 0)), name)
        end
    end

    function fs.touch(name, opt)
        if opt == nil then
            return sh.run("touch", name, "2>/dev/null")
        elseif type(opt) == "number" then
            return sh.run("touch", "-d", '"'..os.date("%c", opt)..'"', name, "2>/dev/null")
        elseif type(opt) == "string" then
            return sh.run("touch", "--reference="..opt, name, "2>/dev/null")
        else
            error "bad argument #2 to touch (none, nil, number or string expected)"
        end
    end

    if pandoc and pandoc.path then
        fs.basename = pandoc.path.filename
    else
        function fs.basename(path)
            return (path:gsub(".*[/\\]", ""))
        end
    end

    if pandoc and pandoc.path then
        fs.dirname = pandoc.path.directory
    else
        function fs.dirname(path)
            return (path:gsub("[/\\][^/\\]*$", ""))
        end
    end

    if pandoc and pandoc.path then
        function fs.splitext(path)
            if fs.basename(path):match "^%." then
                return path, ""
            end
            return pandoc.path.split_extension(path)
        end
    else
        function fs.splitext(path)
            local name, ext = path:match("^(.*)(%.[^/\\]-)$")
            if name and ext and #name > 0 and not name:has_suffix(fs.sep) then
                return name, ext
            end
            return path, ""
        end
    end

    function fs.ext(path)
        local _, ext = fs.splitext(path)
        return ext
    end

    if pandoc and pandoc.path then
        fs.realpath = pandoc.path.normalize
    else
        function fs.realpath(path)
            return sh.read("realpath", path) : trim() ---@diagnostic disable-line:undefined-field
        end
    end

    function fs.readlink(path)
        return sh.read("readlink", path) : trim() ---@diagnostic disable-line:undefined-field
    end

    function fs.absname(path)
        if path:match "^[/\\]" or path:match "^.:" then return path end
        return fs.getcwd()..fs.sep..path
    end

    if pandoc and pandoc.system then
        function fs.mkdirs(path)
            return pandoc.system.make_directory(path, true)
        end
    else
        function fs.mkdirs(path)
            return sh.run("mkdir", "-p", path)
        end
    end

end

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
    local function exists_in(path) return fs.is_file(fs.join(path, name)) end
    local path = os.getenv("PATH")
        :split(fs.path_sep)
        :find(exists_in)
    if path then return fs.join(path, name) end
    return nil, name..": not found in $PATH"
end

--[[@@@
```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent directories.
@@@]]

if not fs.mkdirs then
    function fs.mkdirs(path)
        if path == "" or fs.stat(path) then return end
        fs.mkdirs(fs.dirname(path))
        fs.mkdir(path)
    end
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
fs.ls(path)
```
returns a list of file names.
`path` can be a directory name or a simple file pattern.
Patterns can contain jokers (`*` to match any character and `**` to search files recursively).

Examples:

- `fs.ls "src"`: list all files/directories in `src`
- `fs.ls "src/*.c"`: list all C files in `src`
- `fs.ls "src/**.c"`: list all C files in `src` and its subdirectories
@@@]]

function fs.ls(dir)
    local base = dir:basename()
    local path = dir:dirname()
    local recursive = base:match"%*%*"
    local pattern = base:match"%*" and base : gsub("([.+-])", "%%%0")
                                            : gsub("%*%*", "*")
                                            : gsub("%*", ".*")

    if recursive then
        return fs.walk(path)
            : filter(function(name) return name:basename():match("^"..pattern.."$") end)
            : sort()
    end
    if pattern then
        return fs.dir(path)
            : filter(function(name) return name:match("^"..pattern.."$") end)
            : map(F.partial(fs.join, path))
            : sort()
    end
    return fs.dir(dir)
        : map(F.partial(fs.join, dir))
        : sort()
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

if pandoc and pandoc.system then
    function fs.with_tmpfile(f)
        return pandoc.system.with_temporary_directory("luax-XXXXXX", function(tmpdir)
            return f(fs.join(tmpdir, "tmpfile"))
        end)
    end
else
    function fs.with_tmpfile(f)
        local tmp = os.tmpname()
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
        local tmp = os.tmpname()
        fs.rm(tmp)
        fs.mkdir(tmp)
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
fs.with_env(env, f)
```
changes the environnement to `env` and calls `f()`.
@@@]]

if pandoc and pandoc.system then
    fs.with_env = pandoc.system.with_environment
end

--[[@@@
```lua
fs.read(filename)
```
returns the content of the text file `filename`.
@@@]]

function fs.read(name)
    local f, oerr = io.open(name, "r")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write(filename, ...)
```
write `...` to the text file `filename`.
@@@]]

function fs.write(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "w")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
end

--[[@@@
```lua
fs.read_bin(filename)
```
returns the content of the binary file `filename`.
@@@]]

function fs.read_bin(name)
    local f, oerr = io.open(name, "rb")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write_bin(filename, ...)
```
write `...` to the binary file `filename`.
@@@]]

function fs.write_bin(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "wb")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
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

function string.dir(path)                   return fs.dir(path) end
function string.stat(path)                  return fs.stat(path) end
function string.inode(path)                 return fs.inode(path) end
function string.basename(path)              return fs.basename(path) end
function string.dirname(path)               return fs.dirname(path) end
function string.splitext(path)              return fs.splitext(path) end
function string.ext(path)                   return fs.ext(path) end
function string.splitpath(path)             return fs.splitpath(path) end
function string.realpath(path)              return fs.realpath(path) end
function string.readlink(path)              return fs.readlink(path) end
function string.absname(path)               return fs.absname(path) end

getmetatable("").__div = function(path1, path2)
    return fs.join(path1, path2)
end

function string.is_file(path)               return fs.is_file(path) end
function string.is_dir(path)                return fs.is_dir(path) end
function string.findpath(path)              return fs.findpath(path) end
function string.walk(path, ...)             return fs.walk(path, ...) end

return fs
