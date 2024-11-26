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
elseif sys.os == "windows" then
    function fs.getcwd()
        return sh.read "cd" : trim() ---@diagnostic disable-line:undefined-field
    end
else
    function fs.getcwd()
        return sh.read "pwd" : trim() ---@diagnostic disable-line:undefined-field
    end
end

if pandoc and pandoc.system then
    fs.dir = F.compose{F, pandoc.system.list_directory}
elseif sys.os == "windows" then
    function fs.dir(path)
        return sh.read("dir /b", path) : lines() : sort() ---@diagnostic disable-line:undefined-field
    end
else
    function fs.dir(path)
        return sh.read("ls", path) : lines() : sort() ---@diagnostic disable-line:undefined-field
    end
end

fs.remove = os.remove

fs.rename = os.rename

function fs.copy(source_name, target_name)
    local from, err_from = io.open(source_name, "rb")
    if not from then return from, err_from end
    local to, err_to = io.open(target_name, "wb")
    if not to then from:close(); return to, err_to end
    while true do
        local block = from:read(8*1024)
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

function fs.symlink(target, linkpath)
    return sh.run("ln -s", target, linkpath)
end

if pandoc and pandoc.system then
    fs.mkdir = pandoc.system.make_directory
else
    function fs.mkdir(path)
        return sh.run("mkdir", path)
    end
end

local S_IFMT  <const> = 0xF << 12
local S_IFDIR <const> = 1 << 14
local S_IFREG <const> = 1 << 15
local S_IFLNK <const> = (1 << 13) | (1 << 15)

local S_IRUSR <const> = 1 << 8
local S_IWUSR <const> = 1 << 7
local S_IXUSR <const> = 1 << 6
local S_IRGRP <const> = 1 << 5
local S_IWGRP <const> = 1 << 4
local S_IXGRP <const> = 1 << 3
local S_IROTH <const> = 1 << 2
local S_IWOTH <const> = 1 << 1
local S_IXOTH <const> = 1 << 0

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

local function stat(name, follow)
    local size, mtime, atime, ctime, mode
    if sys.os == "macos" then
        local st = sh.read("LC_ALL=C", "stat", follow, "-r", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        local _
        _, _, mode, _, _, _, _, size, atime, mtime, _, ctime, _, _, _ = st:words():unpack()
        mode = tonumber(mode, 8)
    else
        local st = sh.read("LC_ALL=C", "stat", follow, "-c '%s;%Y;%X;%W;%f'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        size, mtime, atime, ctime, mode = st:trim():split ";":unpack()
        mode = tonumber(mode, 16)
    end
    return F{
        name = name,
        size = tonumber(size),
        mtime = tonumber(mtime),
        atime = tonumber(atime),
        ctime = tonumber(ctime),
        mode = mode,
        type = (mode & S_IFMT) == S_IFLNK and "link"
            or (mode & S_IFMT) == S_IFDIR and "directory"
            or (mode & S_IFMT) == S_IFREG and "file"
            or "unknown",
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

function fs.stat(name)
    return stat(name, "-L")
end

function fs.lstat(name)
    return stat(name, {})
end

function fs.inode(name)
    local dev, ino
    if sys.os == "macos" then
        local st = sh.read("LC_ALL=C", "stat", "-L", "-r", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        dev, ino = st:words():unpack()
    else
        local st = sh.read("LC_ALL=C", "stat", "-L", "-c '%d;%i'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        dev, ino = st:trim():split ";":unpack()
    end
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

function fs.chext(path, new_ext)
    return fs.splitext(path) .. new_ext
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
elseif sys.os == "windows" then
    function fs.mkdirs(path)
        return sh.run("mkdir", path)
    end
else
    function fs.mkdirs(path)
        return sh.run("mkdir", "-p", path)
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

        local files
        if recursive then
            files = sh("dir /b /s", path/pattern)
        elseif pattern then
            files = sh("dir /b", path/pattern)
        else
            files = sh("dir /b", dir)
        end
        return files
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

        local files
        if recursive then
            files = sh("find", path, ("-name %q"):format(pattern))
                : lines()
                : filter(F.partial(F.op.ne, path))
        elseif pattern then
            files = sh("ls -d", path/pattern)
                : lines()
        else
            files = sh("ls", dir)
                : lines()
                : map(F.partial(fs.join, dir))
        end
        return files
            : map(clean_path)
            : sort()
    end
end

function fs.is_file(name)
    local st = fs.stat(name)
    return st ~= nil and st.type == "file"
end

function fs.is_dir(name)
    local st = fs.stat(name)
    return st ~= nil and st.type == "directory"
end

function fs.is_link(name)
    local st = fs.lstat(name)
    return st ~= nil and st.type == "link"
end

fs.rm = fs.remove
fs.mv = fs.rename

fs.tmpfile = os.tmpname

function fs.tmpdir()
    local tmp = os.tmpname()
    fs.rm(tmp)
    fs.mkdir(tmp)
    return tmp
end

return fs
