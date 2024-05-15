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

--@LIB

local F = require "F"
local sys = require "sys"

-- Pure Lua / Pandoc Lua implementation of fs.c

local fs = {}

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

local stat = sys.os=="macos" and "gstat" or "stat"

function fs.stat(name)
    local st = sh.read("LC_ALL=C", stat, "-L", "-c '%s;%Y;%X;%W;%F;%f'", name, "2>/dev/null")
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
    local st = sh.read("LC_ALL=C", stat, "-L", "-c '%d;%i'", name, "2>/dev/null")
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
        local dir, n = path:gsub("[/\\][^/\\]*$", "")
        return n > 0 and dir or "."
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
    if sys.os == "windows" then
        function fs.mkdirs(path)
            return sh.run("mkdir", path)
        end
    else
        function fs.mkdirs(path)
            return sh.run("mkdir", "-p", path)
        end
    end
end

if sys.os == "windows" then
    function fs.ls(dir)
        dir = dir or "."
        local base = dir:basename()
        local path = dir:dirname()
        local recursive = base:match"%*%*"
        local pattern = base:match"%*" and base:gsub("%*+", "*")

        local useless_path_prefix = "^%."..fs.sep
        local function clean_path(fullpath)
            return fullpath:gsub(useless_path_prefix, "")
        end

        if recursive then
            return sh("dir /b /s", path/pattern)
                : lines()
                : map(clean_path)
                : sort()
        end
        if pattern then
            local res= sh("dir /b", path/pattern)
                : lines()
                : map(clean_path)
                : sort()
            return res
        end
        return sh("dir /b", dir)
            : lines()
            : map(clean_path)
            : sort()
    end
else
    function fs.ls(dir)
        dir = dir or "."
        local base = dir:basename()
        local path = dir:dirname()
        local recursive = base:match"%*%*"
        local pattern = base:match"%*" and base:gsub("%*+", "*")

        local useless_path_prefix = "^%."..fs.sep
        local function clean_path(fullpath)
            return fullpath:gsub(useless_path_prefix, "")
        end

        if recursive then
            return sh("find", path, ("-name %q"):format(pattern))
                : lines()
                : filter(F.partial(F.op.ne, path))
                : map(clean_path)
                : sort()
        end
        if pattern then
            local res= sh("ls -d", path/pattern)
                : lines()
                : map(clean_path)
                : sort()
            return res
        end
        return sh("ls", dir)
            : lines()
            : map(F.partial(fs.join, dir))
            : map(clean_path)
            : sort()
    end
end

return fs
