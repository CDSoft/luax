-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/bang

local F = require "F"
local fs = require "fs"
local log = require "log"
local sys = require "sys"

local function tar_rule()
    rule "tar" {
        description = "tar $out",
        command = {
            "tar -caf $out -C $base $name $transform",
            case(sys.os) {
                linux   = "--sort=name",
                macos   = {},
                windows = {},
            },
        },
    }
    tar_rule = F.const() -- generate the tar rule once
end

local function get_first_level(base, files)
    return files : map(function(file)
        if not file:has_prefix(base) then return end
        return file
            : sub(#base+1)                                  -- remove the base dir
            : splitpath()                                   -- split path components
            : drop_while(function(p) return p==fs.sep end)  -- ignore empty path components
            : head()                                        -- keep the first one
    end) : nub()
end

local function tar(output)
    tar_rule()
    return function(inputs)
        local base = inputs.base
        local name = inputs.name
        local transform = nil
        if inputs.transform then
            transform = F.flatten{inputs.transform} : map(function(expr)
                return { "--transform", string.format("%q", expr) }
            end)
        end
        if base and name then
            local files = build.files(base/name)
            return build(output) { "tar",
                base = base,
                name = name,
                transform = transform,
                implicit_in = files,
            }
        end
        if base then
            local files = build.files(base)
            return build(output) { "tar",
                base = base,
                name = get_first_level(base, files),
                transform = transform,
                implicit_in = files,
            }
        end
        log.error(output..": base directory not specified")
    end
end

return {
    tar = tar,
}
