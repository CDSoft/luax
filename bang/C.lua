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

local flatten = require "flatten"
local tmp = require "tmp"

local default_options = {
    builddir = "$builddir/tmp",
    cc = "cc", cflags = {"-c", "-MMD -MF $depfile"}, cargs = "$in -o $out",
    depfile = "$out.d",
    cvalid = {},
    ar = "ar", aflags = "-crs", aargs = "$out $in",
    so = "cc", soflags = "-shared", soargs = "-o $out $in", solibs = {},
    ld = "cc", ldflags = {}, ldargs = "-o $out $in", ldlibs = {},
    c_exts = { ".c" },
    o_ext = ".o",
    a_ext = ".a",
    so_ext = sys.so,
    exe_ext = sys.exe,
    implicit_in = Nil,
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
        local cc = F{compiler.name, "cc"}:flatten():str"-"
        local ar = F{compiler.name, "ar"}:flatten():str"-"
        local so = F{compiler.name, "so"}:flatten():str"-"
        local ld = F{compiler.name, "ld"}:flatten():str"-"
        local new_rules = {
            cc = rule(cc) {
                description = {compiler.cc, "$out"},
                command = { compiler.cc, compiler.cflags, compiler.cargs },
                depfile = compiler.depfile,
                implicit_in = compiler.implicit_in,
            },
            ar = rule(ar) {
                description = {compiler.ar, "$out"},
                command = { compiler.ar, compiler.aflags, compiler.aargs },
                implicit_in = compiler.implicit_in,
            },
            so = rule(so) {
                description = {compiler.so, "$out"},
                command = { compiler.so, compiler.soflags, compiler.soargs, compiler.solibs },
                implicit_in = compiler.implicit_in,
            },
            ld = rule(ld) {
                description = {compiler.ld, "$out"},
                command = { compiler.ld, compiler.ldflags, compiler.ldargs, compiler.ldlibs },
                implicit_in = compiler.implicit_in,
            },
        }
        rawset(self, compiler, new_rules)
        return new_rules
    end
})

local function compile(self, output)
    local cc = rules[self].cc
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.o_ext)
        local validations = F.flatten{self.cvalid}:map(function(valid)
            local valid_output = output.."-"..(valid.name or valid)..".check"
            if valid.name then
                return valid(valid_output) { inputs }
            else
                return build(valid_output) { valid, inputs }
            end
        end)
        return build(output) (F.merge{
            { cc, input_list },
            input_vars,
            { validations = validations },
        })
    end
end

local function static_lib(self, output)
    local ar = rules[self].ar
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.a_ext)
        return build(output) { ar,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local function dynamic_lib(self, output)
    local so = rules[self].so
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.so_ext)
        return build(output) { so,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local function executable(self, output)
    local ld = rules[self].ld
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.exe_ext)
        return build(output) { ld,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local compiler_mt

local compilers = {}

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
    __call = executable,

    __index = {
        new = new,

        compile = compile,
        static_lib = static_lib,
        dynamic_lib = dynamic_lib,
        executable = executable,

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

local cc      = new(default_options, "C")
local gcc     = cc  : new "gcc"     : set "cc" "gcc"     : set "so" "gcc"     : set "ld" "gcc"
local clang   = cc  : new "clang"   : set "cc" "clang"   : set "so" "clang"   : set "ld" "clang"
local cpp     = cc  : new "Cpp"     : set "cc" "c++"     : set "so" "c++"     : set "ld" "c++"     : set "c_exts" { ".cc", ".cpp" }
local gpp     = cpp : new "gpp"     : set "cc" "g++"     : set "so" "g++"     : set "ld" "g++"
local clangpp = cpp : new "clangpp" : set "cc" "clang++" : set "so" "clang++" : set "ld" "clang++"

local zigcc   = cc  : new "zigcc"   : set "cc" "zig cc"  : set "ar" "zig ar" : set "so" "zig cc"  : set "ld" "zig cc"
local zigcpp  = cpp : new "zigcpp"  : set "cc" "zig c++" : set "ar" "zig ar" : set "so" "zig c++" : set "ld" "zig c++"
require "luax-targets" : foreach(function(target)
    local zig_target = {"-target", F{target.arch, target.os, target.libc}:str"-"}
    local function add_target(compiler)
        return compiler : add "cc" (zig_target) : add "so" (zig_target) : add "ld" (zig_target) : set "so_ext" (target.so) : set "exe_ext" (target.exe)
    end
    zigcc[target.name]  = add_target(zigcc  : new("zigcc-"..target.name))
    zigcpp[target.name] = add_target(zigcpp : new("zigcpp-"..target.name))
end)

local compile_flags_file = nil

local function compile_flags(flags)
    if not compile_flags_file then
        compile_flags_file = file(bang.output:dirname()/"compile_flags.txt")
    end
    local flag_list = type(flags) == "string" and {flags} or flatten(flags)
    compile_flags_file((vars%flag_list) : unlines())
    return flags
end

return setmetatable({
    cc  = cc,  gcc = gcc, clang   = clang,   zigcc  = zigcc,
    cpp = cpp, gpp = gpp, clangpp = clangpp, zigcpp = zigcpp,
    compile_flags = compile_flags,
}, {
    __call = function(_, ...) return cc(...) end,
    __index = {
        new = function(_, name) return cc:new(name) end,
    },
})
