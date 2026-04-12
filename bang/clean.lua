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
local help = require "help"
local ident = require "ident"

local clean = {}
local mt = {__index={}}

local directories_to_clean = F{}
local directories_to_clean_more = F{}

local builddir = "$builddir"

function mt.__call(_, dir)
    directories_to_clean[#directories_to_clean+1] = dir
end

function clean.mrproper(dir)
    directories_to_clean_more[#directories_to_clean_more+1] = dir
end

function mt.__index:default_target_needed()
    return #directories_to_clean > 0 or #directories_to_clean_more > 0
end

function mt.__index:gen()

    local rm_cmd = F.case(sys.os) {
        linux   = "rm -rf",
        macos   = "rm -rf",
        windows = "del /F /S /Q",
    }

    local function rm(dir)
        return { rm_cmd, dir/(dir==builddir and "*" or {}) }
    end

    if #directories_to_clean > 0 then

        section("Clean")

        help "clean" "clean generated files"

        local targets = directories_to_clean : map(function(dir)
            return build("clean-"..ident(dir)) {
                ["$no_default"] = true,
                description = {"CLEAN", dir},
                command = rm(dir),
            }
        end)

        phony "clean" {
            ["$no_default"] = true,
            targets,
        }

    end

    if #directories_to_clean_more > 0 then

        section("Clean (mrproper)")

        help "mrproper" "clean generated files and more"

        local targets = directories_to_clean_more : map(function(dir)
            return build("mrproper-"..ident(dir)) {
                ["$no_default"] = true,
                description = {"CLEAN", dir},
                command = rm(dir),
            }
        end)

        phony "mrproper" {
            ["$no_default"] = true,
            #directories_to_clean > 0 and "clean" or {},
            targets,
        }

    end

end

return setmetatable(clean, mt)
