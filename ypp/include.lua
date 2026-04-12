--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
https://codeberg.org/cdsoft/luax
--]]

local F = require "F"

local flex = require "flex"
local convert = require "convert"

--[[@@@
* `include(filename, [opts])`: include the file `filename`.

    - `opts.pattern` is the Lua pattern used to identify the part of the file to include. If the pattern is not given, the whole file is included.
    - `opts.exclude` is the Lua pattern used to identify parts of the file to exclude. If the pattern is not given, the whole file is included.
    - `opts.from` is the format of the input file (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.to` is the destination format (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.shift` is the offset applied to the header levels. The default offset is `0`.

* `include.raw(filename, [opts])`: like `include` but the content of the file is not preprocessed with `ypp`.

@q[=====[
The `include` macro can also be called as a curried function (arguments can be swapped). E.g.:

    @include "file.csv" {from="csv"}
    @include {from="csv"} "file.csv"

]=====]
@@@]]

local function include(filename, opts, prepro)
    opts = opts or {}
    local content = ypp.with_inputfile(filename, function(full_filepath)
        local s = ypp.read_file(full_filepath)
        if opts.pattern then s = s:match(opts.pattern) end
        if opts.exclude then s = s:gsub(opts.exclude, "") end
        return ypp.lconf(prepro, s)
    end)
    content = convert.if_required(content, opts)
    return content
end

local flex_include     = flex.str(function(filename, opts) return include(filename, opts, ypp) end)
local flex_include_raw = flex.str(function(filename, opts) return include(filename, opts, F.id) end)

return setmetatable({
    raw = flex_include_raw,
}, {
    __call = function(_, ...) return flex_include(...) end,
})
