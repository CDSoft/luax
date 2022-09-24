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

local fs = require "fs"
local sys = require "sys"
local fun = require "fun"

local function sort(t)
    table.sort(t)
    return t
end

local function createfile(name)
    assert(io.open(name, "w")):close()
end

return function()
    local cwd
    if sys.os == "linux" or sys.os == "macos" then
        cwd = io.popen("pwd"):read("a"):trim()
    end
    if sys.os == "windows" then
        cwd = io.popen("cd"):read("a"):trim()
    end

    eq(fs.getcwd(), cwd)

    eq(fs.mv, fs.rename)
    eq(fs.rm, fs.remove)

    local tmp = fs.join(cwd, ".build", "test", "fs")
    eq(tmp, cwd..fs.sep..".build"..fs.sep.."test"..fs.sep.."fs")
    fun.foreach(fs.walk(tmp, true), fs.remove)
    fs.remove(tmp)

    fs.mkdirs(tmp)
    assert(fs.chdir(tmp))
    eq(fs.getcwd(), fs.absname(tmp))
    eq(fs.getcwd(), fs.realpath(tmp))

    fs.mkdir "foo"
    fs.mkdir "bar"
    fs.mkdir "bar/baz"
    fun.foreach(createfile, {"foo.txt", "bar.txt", "foo/foo.txt", "bar/bar.txt", "bar/baz/baz.txt"})

    fs.mkdirs(fs.join(tmp, "level1", "level2", "level3"))
    eq(fs.is_dir(fs.join(tmp, "level1", "level2", "level3")), true)

    eq(sort(fs.dir()),{"bar","bar.txt","foo","foo.txt", "level1"})
    eq(sort(fs.dir(".")),{"bar","bar.txt","foo","foo.txt", "level1"})
    fs.chdir(cwd)
    eq(sort(fs.dir(tmp)),{"bar","bar.txt","foo","foo.txt", "level1"})
    fs.chdir(tmp)

    local function test_files(f, testfiles, reverse)
        eq(f(reverse), fun.map(function(name) return fun.prefix"."(name:gsub("/", fs.sep)) end, testfiles))
        eq(f(".", reverse), fun.map(function(name) return fun.prefix"."(name:gsub("/", fs.sep)) end, testfiles))
        fs.chdir(cwd)
        eq(f(tmp, reverse), fun.map(function(name) return fun.prefix(tmp)(name:gsub("/", fs.sep)) end, testfiles))
        fs.chdir(tmp)
    end

    test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/foo.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})
    assert(fs.rename(fs.join(tmp, "foo.txt"), fs.join(tmp, "foo2.txt")))
    test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})
    test_files(fs.walk, {"/bar.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt","/bar/baz","/level1/level2/level3","/level1/level2","/level1","/foo","/bar"}, true)

    local content1 = "Lua is great!!!"
    local f1 = assert(io.open(fs.join(tmp, "f1.txt"), "w"))
    f1:write(content1)
    f1:close()
    fs.copy(fs.join(tmp, "f1.txt"), fs.join(tmp, "f2.txt"))
    local f2 = assert(io.open(fs.join(tmp, "f2.txt"), "r"))
    local content2 = f2:read("*a")
    f2:close()
    eq(content2, content1)
    test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/f1.txt","/f2.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})

    eq(fs.is_file(fs.join(tmp, "f1.txt")), true)
    eq(fs.is_file(fs.join(tmp, "unknown")), false)
    eq(fs.is_file(fs.join(tmp, "foo")), false)

    eq(fs.is_dir(fs.join(tmp, "f1.txt")), false)
    eq(fs.is_dir(fs.join(tmp, "unknown")), false)
    eq(fs.is_dir(fs.join(tmp, "foo")), true)

    local stat_f1 = fs.stat(fs.join(tmp, "f1.txt"))
    eq(stat_f1.name, fs.join(tmp, "f1.txt"))
    eq(stat_f1.type, "file")
    eq(stat_f1.size, #content1)

    local stat_foo = fs.stat(fs.join(tmp, "foo"))
    eq(stat_foo.name, fs.join(tmp, "foo"))
    eq(stat_foo.type, "directory")

    if sys.os == "linux" then
        local f1 = fs.join(tmp, "f1.txt")
        local f2 = fs.join(tmp, "f2.txt")
        fs.chmod(fs.join(tmp, "f1.txt"), 0)
        fs.chmod(fs.join(tmp, "f2.txt"), 0)
        local s1 = fs.stat(f1)
        local s2 = fs.stat(f2)
        eq(s1.uR, false) eq(s1.uW, false) eq(s1.uX, false)
        eq(s1.gR, false) eq(s1.gW, false) eq(s1.gX, false)
        eq(s1.oR, false) eq(s1.oW, false) eq(s1.oX, false)
        eq(s2.uR, false) eq(s2.uW, false) eq(s2.uX, false)
        eq(s2.gR, false) eq(s2.gW, false) eq(s2.gX, false)
        eq(s2.oR, false) eq(s2.oW, false) eq(s2.oX, false)
        fun.foreach(("uR uW uX gR gW gX oR oW oX"):words(), function(perm)
            fs.chmod(f1, fs[perm])
            local s1 = fs.stat(f1)
            eq(s1.uR, perm=="uR") eq(s1.uW, perm=="uW") eq(s1.uX, perm=="uX")
            eq(s1.gR, perm=="gR") eq(s1.gW, perm=="gW") eq(s1.gX, perm=="gX")
            eq(s1.oR, perm=="oR") eq(s1.oW, perm=="oW") eq(s1.oX, perm=="oX")
            fs.chmod(f2, f1)
            local s2 = fs.stat(f2)
            eq(s2.uR, perm=="uR") eq(s2.uW, perm=="uW") eq(s2.uX, perm=="uX")
            eq(s2.gR, perm=="gR") eq(s2.gW, perm=="gW") eq(s2.gX, perm=="gX")
            eq(s2.oR, perm=="oR") eq(s2.oW, perm=="oW") eq(s2.oX, perm=="oX")
        end)
    end

    local ft = fs.join(tmp, "ft")
    local t0 = os.time()
    assert(fs.touch(ft))
    assert(math.abs(fs.stat(ft).mtime - t0) <= 1)
    assert(math.abs(fs.stat(ft).atime - t0) <= 1)
    assert(math.abs(fs.stat(ft).ctime - t0) <= 1)

    assert(fs.touch(ft, 424242))
    eq(fs.stat(ft).mtime, 424242)
    eq(fs.stat(ft).atime, 424242)
    if sys.os == "linux" then
        assert(math.abs(fs.stat(ft).ctime - t0) <= 1)
    else
        eq(fs.stat(ft).ctime, 424242)
    end

    local ft2 = fs.join(tmp, "ft2")
    assert(fs.touch(ft2, ft))
    eq(fs.stat(ft2).mtime, fs.stat(ft).mtime)
    eq(fs.stat(ft2).atime, fs.stat(ft).atime)
    eq(fs.stat(ft2).ctime, fs.stat(ft).ctime)

    local ok, err = fs.touch("/foo")
    eq(ok, nil)
    eq(err:gsub(":.*", ": ..."), "/foo: ...")

    local a, b, c = "aaa", "bb", "ccc"
    eq(fs.dirname(fs.join(a,b,c)), fs.join(a,b))
    eq(fs.basename(fs.join(a,b,c)), fs.join(c))
    eq(fs.absname("."), fs.join(tmp, "."))
    eq(fs.absname(tmp), tmp)
    eq(fs.absname("foo"), fs.join(tmp, "foo"))
    eq(fs.absname("/foo"), "/foo")
    eq(fs.absname("\\foo"), "\\foo")
    eq(fs.absname("Z:foo"), "Z:foo")
    eq(fs.realpath("."), tmp)
    eq(fs.realpath(tmp), tmp)
    eq(fs.realpath("foo"), fs.join(tmp, "foo"))
    eq(fs.realpath("/foo"), nil) -- unknown file
    eq(fs.realpath("\\foo"), nil) -- unknown file
    eq(fs.realpath("Z:foo"), nil) -- unknown file

    eq(fs.sep, sys.os == "windows" and "\\" or "/")

    eq(fs.rmdir(tmp), true)

end
