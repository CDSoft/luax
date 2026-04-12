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
local sys = require "sys"
local targets = require "luax-targets"

local default_options = {
    name = "luax",
    luax = "luax",
    target = "luax",
    flags = {},
    implicit_in = Nil,
    exe_ext = "",
}

local function set_ext(name, ext)
    if (vars%name):has_suffix(ext) then return name end
    return name..ext
end

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local rules = setmetatable({}, {
    __index = function(self, compiler)
        local new_rule = rule(compiler.name) {
            description = compiler.description or {compiler.name, "$out"},
            command = { compiler.luax, "compile", "-t", compiler.target, "$in -o $out", compiler.flags },
            implicit_in = compiler.implicit_in,
        }
        self[compiler] = new_rule
        return new_rule
    end
})

local function run(self, output)
    return function(inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.exe_ext)
        return build(output) (F.merge{
            { rules[self], input_list },
            input_vars,
        })
    end
end

local compiler_mt

local compilers = F{}

local function new(compiler, name)
    if compilers[name] then
        error(name..": compiler redefinition")
    end
    local self = F.merge { compiler, {name=name} }
    compilers[name] = self
    return setmetatable(self, compiler_mt)
end

local function check_opt(name)
    assert(default_options[name], name..": Unknown compiler option")
end

compiler_mt = {
    __call = run,

    __index = {
        new = new,

        set = function(self, name)
            check_opt(name)
            return function(value) self[name] = value; return self end
        end,
        add = function(self, name)
            check_opt(name)
            return function(value) self[name] = {self[name], value}; return self end
        end,
        insert = function(self, name)
            check_opt(name)
            return function(value) self[name] = {value, self[name]}; return self end
        end,
    },
}

local luax = new(default_options, "luax") : set "target" "luax"
local lua = luax:new "luax-lua" : set "target" "lua"
local pandoc = luax:new "luax-pandoc" : set "target" "pandoc"
local native = luax:new "luax-native" : set "target" "native" : set "exe_ext" (sys.exe)

local M = {
    luax = luax,
    lua = lua,
    pandoc = pandoc,
    native = native,
}
targets : foreach(function(target)
    M[target.name] = native:new("luax-"..target.name) : set "target" (target.name) : set "exe_ext" (target.exe)
end)

return setmetatable(M, {
    __call = function(_, ...) return luax(...) end,
    __index = {
        new = function(_, ...) return luax:new(...) end,
        set = function(_, ...) return luax:set(...) end,
        add = function(_, ...) return luax:add(...) end,
        insert = function(_, ...) return luax:insert(...) end,
        set_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:set(name)(value) end)
            end
        end,
        add_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:add(name)(value) end)
            end
        end,
        insert_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:insert(name)(value) end)
            end
        end,
    }
})
