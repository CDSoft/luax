#!tools/bang.sh

section [[
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
https://codeberg.org/cdsoft/luax
]]

help.name "LuaX"

version(require "luax-version" . version) -- defined in lib/version.lua

args = (function()
    local parser = require "argparse"()
    parser : flag "-d" : description "debug"
    return parser:parse(arg)
end)()

clean "$builddir"

require "strict"

compile = {}
test = {}
doc = {}
release = {}

require "build-luax"
require "build-bang"
require "build-ypp"
require "build-lsvg"

require "build-releases" -- must be called last

section "Ninja targets"

help "compile" "Compilation"
help "test"    "Run tests"
help "doc"     "Generate the documentation"
help "release" "Build the release archives"
help "all"     "Compile, test and build documentation"

phony "all" {
    phony "compile" { compile },
    phony "test"    { test },
    phony "doc"     { doc },
    phony "release" { args.d and {} or release },
}
default "compile"
