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

local tmp = require "tmp"

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local function pipe(rules)
    assert(#rules > 0, "pipe requires at least one rule")
    local builddir = rules.builddir or "$builddir/tmp"
    return F.curry(function(output, inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        local implicit_in = input_vars.implicit_in
        local implicit_out = input_vars.implicit_out
        input_vars.implicit_in = nil
        input_vars.implicit_out = nil
        local rule_names = F.map(function(r)
            return type(r)=="table" and r:rule() or r
        end, rules)
        local current_names = F.range(1, #rules):scan(function(name, _)
            local prefix, ext = name:splitext()
            return ext == ".in" and prefix or name
        end, input_list:head())
        local tmpfiles = F.range(1, #rules-1):map(function(i)
            local ext = rule_names[i]:ext()
            if ext == "" then ext = current_names[i+1]:ext() end
            return tmp(builddir, output, output:basename():splitext().."-"..tostring(i))..ext
        end)
        for i = 1, #rules do
            build(tmpfiles[i] or output) (F.merge{
                { rule_names[i], {tmpfiles[i-1] or input_list} },
                input_vars,
                {
                    implicit_in  = i==1      and implicit_in  or nil,
                    implicit_out = i==#rules and implicit_out or nil,
                },
            })
        end
        return output
    end)
end

return pipe
