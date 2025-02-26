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
https://github.com/cdsoft/luax
--]]

---------------------------------------------------------------------
-- tar
---------------------------------------------------------------------

local test = require "test"
local eq = test.eq

local fs = require "fs"
local tar = require "tar"
local sh = require "sh"
local sys = require "sys"

return function()

    eq(tar.strip(1) "a/b/c/d", "b/c/d")
    eq(tar.strip(2) "a/b/c/d", "c/d")
    eq(tar.strip(3) "a/b/c/d", "d")

    eq(tar.strip(1) "/a/b/c/d", "b/c/d")
    eq(tar.strip(2) "/a/b/c/d", "c/d")
    eq(tar.strip(3) "/a/b/c/d", "d")

    eq(tar.strip("a") "a/b/c/d", "b/c/d")
    eq(tar.strip("a/b") "a/b/c/d", "c/d")

    eq(tar.strip("a") "/a/b/c/d", "b/c/d")
    eq(tar.strip("a/b") "/a/b/c/d", "c/d")

    eq(tar.strip("/a") "a/b/c/d", "b/c/d")
    eq(tar.strip("/a/b") "a/b/c/d", "c/d")

    eq(tar.strip("/a") "/a/b/c/d", "b/c/d")
    eq(tar.strip("/a/b") "/a/b/c/d", "c/d")

    eq(tar.add("x") "a/b/c", "x/a/b/c")
    eq(tar.add("x") "c", "x/c")

    eq(tar.add("x/y") "/a/b/c", "x/y/a/b/c")
    eq(tar.add("x/y") "/c", "x/y/c")

    eq(tar.add("/x") "a/b/c", "x/a/b/c")
    eq(tar.add("/x") "c", "x/c")

    eq(tar.add("/x/y") "/a/b/c", "x/y/a/b/c")
    eq(tar.add("/x/y") "/c", "x/y/c")

    local transform = tar.chain { tar.strip(2), tar.add("x/y") }

    eq(transform "a/b/c/d", "x/y/c/d")
    eq(transform "/a/b/c/d", "x/y/c/d")

    do

        local files = {
            { name="foo/bar/baz.txt", content="baz content", mtime=1739568630 },
            { name="hello.txt", content="Hello, World!", mtime=1739568630+60 },
            { name="baz/baz.link", link="foo/bar/baz.txt", mtime=1739568630+60*2 },
        }
        local archive = tar.tar(files)
        if sys.os == "linux" then
            local archive_content = fs.with_tmpdir(function(tmp)
                fs.write_bin(tmp/"foo.tar", archive)
                return sh { "tar tvf", tmp/"foo.tar" }
            end)
            eq(archive_content, [[
drwxr-xr-x 0/0               0 2025-02-14 22:30 foo
drwxr-xr-x 0/0               0 2025-02-14 22:30 foo/bar
-rw-r--r-- 0/0              11 2025-02-14 22:30 foo/bar/baz.txt
-rw-r--r-- 0/0              13 2025-02-14 22:31 hello.txt
drwxr-xr-x 0/0               0 2025-02-14 22:32 baz
lrwxrwxrwx 0/0               0 2025-02-14 22:32 baz/baz.link -> foo/bar/baz.txt
]])
        end

        do
            local extracted_files = tar.untar(archive)
            eq(extracted_files, {
                {
                    name = "foo",
                    type = "directory",
                    mode = tonumber("755", 8),
                    mtime = 1739568630,
                    size = 0,
                },
                {
                    name = "foo/bar",
                    type = "directory",
                    mode = tonumber("755", 8),
                    mtime = 1739568630,
                    size = 0,
                },
                {
                    name = "foo/bar/baz.txt",
                    type = "file",
                    mode = tonumber("644", 8),
                    mtime = 1739568630,
                    size = 11,
                    content = "baz content",
                },
                {
                    name = "hello.txt",
                    type = "file",
                    mode = tonumber("644", 8),
                    mtime = 1739568690,
                    size = 13,
                    content = "Hello, World!",
                },
                {
                    name = "baz",
                    type = "directory",
                    mode = tonumber("755", 8),
                    mtime = 1739568750,
                    size = 0,
                },
                {
                    name = "baz/baz.link",
                    type="link",
                    mode = tonumber("777", 8),
                    mtime = 1739568750,
                    size = 0,
                    link = "foo/bar/baz.txt",
                },
            })
        end

        do
            local extracted_files = tar.untar(archive, tar.strip(1))
            eq(extracted_files, {
                {
                    name = "bar",
                    type = "directory",
                    mode = tonumber("755", 8),
                    mtime = 1739568630,
                    size = 0,
                },
                {
                    name = "bar/baz.txt",
                    type = "file",
                    mode = tonumber("644", 8),
                    mtime = 1739568630,
                    size = 11,
                    content = "baz content",
                },
                {
                    name = "baz.link",
                    type="link",
                    mode = tonumber("777", 8),
                    mtime = 1739568750,
                    size = 0,
                    link = "foo/bar/baz.txt",
                }
            })
        end

    end

    do

        local files = {
            { name="foo/bar/baz.txt", content="baz content", mtime=1739568630 },
            { name="hello.txt", content="Hello, World!", mtime=1739568630+60 },
        }
        local archive = tar.tar(files, tar.xform(2, "baz"))
        if sys.os == "linux" then
            local archive_content = fs.with_tmpdir(function(tmp)
                fs.write_bin(tmp/"foo.tar", archive)
                return sh { "tar tvf", tmp/"foo.tar" }
            end)
            eq(archive_content, [[
drwxr-xr-x 0/0               0 2025-02-14 22:30 baz
-rw-r--r-- 0/0              11 2025-02-14 22:30 baz/baz.txt
]])
        end

        local extracted_files = tar.untar(archive)
        eq(extracted_files, {
            {
                name = "baz",
                type = "directory",
                mode = tonumber("755", 8),
                mtime = 1739568630,
                size = 0,
            },
            {
                name = "baz/baz.txt",
                type = "file",
                mode = tonumber("644", 8),
                mtime = 1739568630,
                size = 11,
                content = "baz content",
            },
        })

    end

    do
        eq(tar.untar(tar.tar{{name=("a"):rep(100), content="foo", mtime=1739568630}}), {
            {
                name = ("a"):rep(100),
                type = "file",
                mode = tonumber("644", 8),
                mtime = 1739568630,
                size = 3,
                content = "foo",
            }
        })
        local ok, err = tar.tar {
            { name=("a"):rep(101), content="foo" }
        }
        eq(ok, nil)
        eq(err, ("a"):rep(101)..": filename too long")
    end
    do
        eq(tar.untar(tar.tar{{name=("a"):rep(98)/"b", content="foo", mtime=1739568630}}), {
            {
                name = ("a"):rep(98),
                type = "directory",
                mode = tonumber("755", 8),
                mtime = 1739568630,
                size = 0,
            },
            {
                name = ("a"):rep(98)/"b",
                type = "file",
                mode = tonumber("644", 8),
                mtime = 1739568630,
                size = 3,
                content = "foo",
            }
        })
        local ok, err = tar.tar {
            { name=("a"):rep(99)/"b", content="foo" }
        }
        eq(ok, nil)
        eq(err, ("a"):rep(99)/"b"..": filename too long")
    end

end
