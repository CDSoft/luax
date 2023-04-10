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
local F = require "F"

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
    local in_tmp = F.curry(fs.join)(tmp)
    eq(tmp, cwd..fs.sep..".build"..fs.sep.."test"..fs.sep.."fs")
    F.map(fs.remove, fs.walk(tmp, {reverse=true}))
    fs.remove(tmp)

    fs.mkdirs(tmp)
    if sys.abi == "gnu" or sys.abi == "musl" then
        assert(fs.chdir(tmp))
        eq(fs.getcwd(), fs.absname(tmp))
        eq(fs.getcwd(), fs.realpath(tmp))
    end

    fs.mkdir(in_tmp "foo")
    fs.mkdir(in_tmp "bar")
    fs.mkdir(in_tmp "bar/baz")
    F.map(createfile, F{"foo.txt", "bar.txt", "foo/foo.txt", "bar/bar.txt", "bar/baz/baz.txt"}:map(in_tmp))

    fs.mkdirs(fs.join(tmp, "level1", "level2", "level3"))
    eq(fs.is_dir(fs.join(tmp, "level1", "level2", "level3")), true)

    eq(fs.dir(tmp):sort(),{"bar","bar.txt","foo","foo.txt", "level1"})
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.dir():sort(),{"bar","bar.txt","foo","foo.txt", "level1"})
        eq(fs.dir("."):sort(),{"bar","bar.txt","foo","foo.txt", "level1"})
    end
    if sys.os == "linux" and (sys.abi == "gnu" or sys.abi == "musl") then
        eq(fs.glob():sort(),{"bar","bar.txt","foo","foo.txt", "level1"})
        eq(fs.glob("*.txt"):sort(),{"bar.txt","foo.txt"})
    end
    if sys.abi == "gnu" or sys.abi == "musl" then
        fs.chdir(cwd)
        eq(fs.dir(tmp):sort(),{"bar","bar.txt","foo","foo.txt", "level1"})
        fs.chdir(tmp)
    end

    local function test_files(f, testfiles, reverse)
        if sys.abi == "gnu" or sys.abi == "musl" then
            eq(f(".", {reverse=reverse}), F.map(function(name) return F.prefix"."(name:gsub("/", fs.sep)) end, testfiles))
            fs.chdir(cwd)
            eq(f(tmp, {reverse=reverse}), F.map(function(name) return F.prefix(tmp)(name:gsub("/", fs.sep)) end, testfiles))
            fs.chdir(tmp)
        end
        eq(f(tmp, {reverse=reverse}), F.map(function(name) return F.prefix(tmp)(name:gsub("/", fs.sep)) end, testfiles))
    end

    test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/foo.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})
    assert(fs.rename(fs.join(tmp, "foo.txt"), fs.join(tmp, "foo2.txt")))
    test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})
    test_files(fs.walk, {"/bar.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt","/bar/baz","/level1/level2/level3","/level1/level2","/level1","/foo","/bar"}, true)

    do
        local content1 = "Lua is great!!!"
        local f1 = assert(io.open(fs.join(tmp, "f1.txt"), "wb"))
        f1:write(content1)
        f1:close()
        fs.copy(fs.join(tmp, "f1.txt"), fs.join(tmp, "f2.txt"))
        local f2 = assert(io.open(fs.join(tmp, "f2.txt"), "rb"))
        local content2 = f2:read("a")
        f2:close()
        eq(content2, content1)
        test_files(fs.walk, {"/bar","/foo","/level1","/level1/level2","/level1/level2/level3","/bar/baz","/bar.txt","/f1.txt","/f2.txt","/foo2.txt","/foo/foo.txt","/bar/bar.txt","/bar/baz/baz.txt"})

        eq(fs.is_file(fs.join(tmp, "f1.txt")), true)
        eq(fs.is_file(fs.join(tmp, "unknown")), false)
        eq(fs.is_file(fs.join(tmp, "foo")), false)

        eq(fs.is_dir(fs.join(tmp, "f1.txt")), false)
        eq(fs.is_dir(fs.join(tmp, "unknown")), false)
        eq(fs.is_dir(fs.join(tmp, "foo")), true)

        local stat_f1 = assert(fs.stat(fs.join(tmp, "f1.txt")))
        eq(stat_f1.name, fs.join(tmp, "f1.txt"))
        eq(stat_f1.type, "file")
        eq(stat_f1.size, #content1)

        local stat_foo = assert(fs.stat(fs.join(tmp, "foo")))
        eq(stat_foo.name, fs.join(tmp, "foo"))
        eq(stat_foo.type, "directory")
    end

    if sys.os == "linux" then
        local f1 = fs.join(tmp, "f1.txt")
        local f2 = fs.join(tmp, "f2.txt")
        fs.chmod(fs.join(tmp, "f1.txt"), 0)
        fs.chmod(fs.join(tmp, "f2.txt"), 0)
        do
            local s1 = assert(fs.stat(f1))
            local s2 = assert(fs.stat(f2))
            eq(s1.uR, false) eq(s1.uW, false) eq(s1.uX, false)
            eq(s1.gR, false) eq(s1.gW, false) eq(s1.gX, false)
            eq(s1.oR, false) eq(s1.oW, false) eq(s1.oX, false)
            eq(s2.uR, false) eq(s2.uW, false) eq(s2.uX, false)
            eq(s2.gR, false) eq(s2.gW, false) eq(s2.gX, false)
            eq(s2.oR, false) eq(s2.oW, false) eq(s2.oX, false)
        end
        F"uR uW uX gR gW gX oR oW oX":words():map(function(perm)
            fs.chmod(f1, fs[perm])
            local s1 = assert(fs.stat(f1))
            eq(s1.uR, perm=="uR") eq(s1.uW, perm=="uW") eq(s1.uX, perm=="uX")
            eq(s1.gR, perm=="gR") eq(s1.gW, perm=="gW") eq(s1.gX, perm=="gX")
            eq(s1.oR, perm=="oR") eq(s1.oW, perm=="oW") eq(s1.oX, perm=="oX")
            fs.chmod(f2, f1)
            local s2 = assert(fs.stat(f2))
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
    if sys.abi == "gnu" or sys.abu == "musl" then
        eq(fs.stat(ft2).mtime, fs.stat(ft).mtime)
        eq(fs.stat(ft2).atime, fs.stat(ft).atime)
        eq(fs.stat(ft2).ctime, fs.stat(ft).ctime)
    else
        bounded(fs.stat(ft2).mtime, fs.stat(ft).mtime, fs.stat(ft).mtime+1)
        bounded(fs.stat(ft2).atime, fs.stat(ft).atime, fs.stat(ft).atime+1)
        bounded(fs.stat(ft2).ctime, fs.stat(ft).ctime, fs.stat(ft).ctime+1)
    end

    local ok, err = fs.touch("/foo")
    eq(ok, nil)
    if sys.abi == "gnu" or sys.abu == "musl" then
        eq(err:gsub(":.*", ": ..."), "/foo: ...")
    end

    local a, b, c = "aaa", "bb", "ccc"
    eq(fs.join(a, b, c), "aaa/bb/ccc")
    eq(fs.join(a, fs.sep..b, c), "/bb/ccc")
    eq(fs.dirname(fs.join(a,b,c)), fs.join(a,b))
    eq(fs.basename(fs.join(a,b,c)), fs.join(c))
    eq({fs.splitext("path/with.dots/file.with_ext")},     {"path/with.dots/file", ".with_ext"})
    eq({fs.splitext("path/with.dots/file_without_ext")},  {"path/with.dots/file_without_ext", ""})
    eq({fs.splitext("path/with.dots/.file_without_ext")}, {"path/with.dots/.file_without_ext", ""})
    eq({fs.splitext("/file.with_ext")},     {"/file", ".with_ext"})
    eq({fs.splitext("/file_without_ext")},  {"/file_without_ext", ""})
    eq({fs.splitext("/.file_without_ext")}, {"/.file_without_ext", ""})
    eq({fs.splitext("file.with_ext")},     {"file", ".with_ext"})
    eq({fs.splitext("file_without_ext")},  {"file_without_ext", ""})
    eq({fs.splitext(".file_without_ext")}, {".file_without_ext", ""})
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.absname("."), fs.join(tmp, "."))
    end
    eq(fs.absname(tmp), tmp)
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.absname("foo"), fs.join(tmp, "foo"))
    end
    eq(fs.absname("/foo"), "/foo")
    eq(fs.absname("\\foo"), "\\foo")
    eq(fs.absname("Z:foo"), "Z:foo")
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.realpath("."), tmp)
    end
    eq(fs.realpath(tmp), tmp)
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.realpath("foo"), fs.join(tmp, "foo"))
    end
    if sys.abi == "gnu" or sys.abi == "musl" then
        eq(fs.realpath("/foo"), nil) -- unknown file
        eq(fs.realpath("\\foo"), nil) -- unknown file
        eq(fs.realpath("Z:foo"), nil) -- unknown file
    elseif pandoc then
        eq(fs.realpath("/foo"), "/foo") -- unknown file
        eq(fs.realpath("\\foo"), "\\foo") -- unknown file
    else
        eq(fs.realpath("/foo"), "/foo") -- unknown file
        eq(fs.realpath("\\foo"), fs.join(cwd, "foo")) -- unknown file
    end

    if sys.os == "linux" then
        eq(fs.findpath("sh"), "/usr/bin/sh")
        local path, msg = fs.findpath("a_name_that_is_likely_not_found")
        eq(path, nil)
        eq(msg, "a_name_that_is_likely_not_found: not found in $PATH")
    end

    eq(fs.sep, sys.os == "windows" and "\\" or "/")

    fs.write    (fs.join(tmp, "new_file_txt"), "content of the new file\r\n", "...", {"a", {"b", "c"}})
    fs.write_bin(fs.join(tmp, "new_file_bin"), "content of the new file\r\n", "...", {"a", {"b", "c"}})
    eq(fs.read    (fs.join(tmp, "new_file_txt")), "content of the new file\r\n...abc")
    eq(fs.read_bin(fs.join(tmp, "new_file_bin")), "content of the new file\r\n...abc")

    eq(fs.rmdir(tmp), true)

    if sys.abi == "gnu" or sys.abi == "musl" then
        fs.chdir(cwd)
    end

end
