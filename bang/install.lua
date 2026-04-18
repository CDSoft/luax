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
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sys = require "sys"

local flatten = require "flatten"
local ident = require "ident"

local prefix = "~/.local"
local targets = F{}

local install = {}
local mt = {__index={}}

function install.prefix(dir)
    prefix = dir
end

function mt.__call(_, name)
    return function(sources)
        targets[#targets+1] = F{name=name, sources=sources}
    end
end

function mt.__index:default_target_needed()
    return not targets:null()
end

function mt.__index:gen(install_rule, install_token)
    if targets:null() then
        return
    end

    section "Installation"

    help "install" ("install $name in PREFIX or "..prefix)

    var "prefix" (prefix)

    local function destdir(target_name)
        return case(sys.os) {
            linux   = "$${DESTDIR}$${PREFIX:-$prefix}"/target_name,
            macos   = "$${DESTDIR}$${PREFIX:-$prefix}"/target_name,
            windows = "%PREFIX%"/target_name,
        }
    end

    rule(install_rule) {
        description = "INSTALL $in to $destdir",
        command = case(sys.os) {
            linux = "mkdir -p $destdir && cp -v --force --preserve=mode,timestamp $in $destdir",
            macos = "mkdir -p $destdir && cp -v -f -p $in $destdir",
            windows = "copy $in $destdir",
        },
        pool = "console",
    }

    local rule_names = targets
    : sort(function(a, b) return a.name < b.name end)
    : group(function(a, b) return a.name == b.name end)
    : map(function(target_group)
        local target_name = target_group[1].name
        local rule_name = "install-"..ident(target_name)
        acc(install_token) {
            "# Files installed in "..target_name.."\n",
            target_group
                : map(function(target)
                    local files = flatten{target.sources} : map(tostring) : unwords() : words()
                    return files:map(function(file) return "#   "..(vars%file).."\n" end)
                end),
            "\n",
        }
        return build(rule_name) { "install", target_group:map(function(target) return target.sources end),
            ["$no_default"] = true,
            destdir = destdir(target_name)
        }
    end)

    phony "install" {
        ["$no_default"] = true,
        rule_names,
    }

end

return setmetatable(install, mt)
