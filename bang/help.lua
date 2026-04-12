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

local product_name = ""
local description = F{}
local epilog = F{}
local targets = F{}

local help = {}
local mt = {__index={}}

local function i(s)
    return s : gsub("%$name", product_name)
end

function help.name(txt)
    product_name = txt
end

function help.description(txt)
    description[#description+1] = i(txt:rtrim())
end

function help.epilog(txt)
    epilog[#epilog+1] = i(txt:rtrim())
end

help.epilogue = help.epilog

function help.target(name)
    return function(txt)
        targets[#targets+1] = F{name=name, txt=i(txt)}
    end
end

function mt.__call(_, ...)
    return help.target(...)
end

local function help_defined()
    return not description:null() or not epilog:null() or not targets:null()
end

function mt.__index:default_target_needed()
    return help_defined()
end

function mt.__index:gen(help_token)
    if not help_defined() then return end

    if not targets:null() then
        table.insert(targets, 1, {name="help", txt="show this help message"})
    end

    local w = targets:map(function(t) return #t.name end):maximum()
    local function justify(s)
        return s..(" "):rep(w-#s)
    end

    section "Help"

    local help_message = F{
        description:null() and {} or description:unlines(),
        "",
        targets:null() and {} or {
            "Targets:",
            targets : map(function(target)
                return F"  %s   %s":format(justify(target.name), target.txt)
            end)
        },
        "",
        epilog:null() and {} or epilog:unlines(),
    } : flatten()
      : unlines()
      : trim()
      : gsub("\n\n+", "\n\n")   -- remove duplicate blank lines
      : lines()

    acc(help_token) {
        help_message : map(F.compose{string.rtrim, F.prefix"# "}) : unlines(),
        "\n",
    }

    build "help" {
        ["$no_default"] = true,
        description = "help",
        command = help_message
          : map(function(line) return ("echo %q"):format(line) end)
          : str "; $\n            "
    }

end

return setmetatable(help, mt)
