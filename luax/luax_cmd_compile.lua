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
http://cdelord.fr/luax
--]]

--@LIB

local fs = require "fs"
local F = require "F"
local sh = require "sh"
local cbor = require "cbor"

local bundle = require "luax_bundle_lib"
local help = require "luax_help"
local welcome = require "luax_welcome"
local targets = require "targets"

local arg0 = arg[0]

local function findpath(name)
    if fs.is_file(name) then return name end
    local full_path = fs.findpath(name)
    return full_path and fs.realpath(full_path) or name
end

local lua_interpreters = F{
    ["luax"]   = { interpreter="luax",   scripts={} },
    ["lua"]    = { interpreter="lua",    scripts={"luax.lib"} },
    ["pandoc"] = { interpreter="pandoc", scripts={"luax.lib"} },
}

local function print_targets()
    lua_interpreters:items():foreach(function(name_def)
        local name, _ = F.unpack(name_def)
        local exe = name
        local path = fs.findpath(exe)
        print(("%-20s%s%s"):format(
            name,
            path and path:gsub("^"..os.getenv"HOME", "~") or exe,
            path and "" or " [NOT FOUND]"))
    end)
    targets:foreach(function(target)
        local path = arg0:dirname():dirname():realpath()/"lib"/"luax-"..target.name..".lib"
        print(("%-20s%s%s"):format(
            target.name,
            path:gsub("^"..os.getenv"HOME", "~"),
            fs.is_file(path) and "" or " [NOT FOUND]"))
    end)
end

local function wrong_arg(a)
    help.err("unrecognized option '%s'", a)
end

-- Read options

local inputs = F{}
local output = nil
local target = nil
local quiet = false
local bytecode = nil
local strip = nil
local key = nil

local actions = setmetatable({
        actions = F{}
    }, {
    __index = {
        add = function(self, action) self.actions[#self.actions+1] = action end,
        run = function(self) self.actions:foreach(F.call) end,
    },
})

do
    local i = 1
    -- Scan options
    while i <= #arg do
        local a = arg[i]
        if a == '-o' then
            i = i+1
            if output then wrong_arg(a) end
            output = arg[i]
        elseif a == '-t' then
            i = i+1
            if target then wrong_arg(a) end
            target = arg[i]
            if target == "list" then print_targets() os.exit() end
        elseif a == '-b' then
            bytecode = true
        elseif a == '-s' then
            bytecode = true
            strip = true
        elseif a == '-k' then
            i = i+1
            if key then wrong_arg(a) end
            key = arg[i]
        elseif a == '-q' then
            quiet = true
        elseif a:match "^%-" then
            wrong_arg(a)
        else
            -- this is not an option but a file to compile
            inputs[#inputs+1] = a
        end
        i = i+1
    end

    if not output then
        help.err "No output specified"
    end

end

local function run_compiler()

    if not quiet then welcome() end

    local scripts = inputs

    if #scripts == 0 then help.err "No input script specified" end
    if output == nil then help.err "No output specified (option -o)" end

    local function log(k, fmt, ...)
        if quiet then return end
        print(("%-9s: %s"):format(k, fmt:format(...)))
    end

    -- List scripts
    local head = "scripts"
    for i = 1, #scripts do
        log(head, "%s", scripts[i])
        head = ""
    end

    local function print_size(current_output)
        local size, unit = fs.stat(current_output).size, "bytes"
        if size > 64*1024 then size, unit = size//1024, "Kb" end
        log("Total", "%7d %s", size, unit)
    end

    local function findscript(script_name)
        return (  os.getenv "LUAX_LIB"
               or (findpath(arg0):dirname():dirname() / "lib")
               ) / script_name
    end

    -- Prepare scripts for a Lua / Pandoc Lua target
    local function compile_lua(current_output, name, interpreter)
        if not quiet then print() end
        log("interpreter", "%s", name)
        log("output", "%s", current_output)

        local luax_scripts = F.map(findscript, interpreter.scripts)

        local files = bundle.bundle {
            scripts = F.flatten{luax_scripts, scripts},
            output = current_output,
            target = interpreter.interpreter,
            bytecode = bytecode,
            strip = strip,
            key = key,
        }
        local exe = files[current_output]

        local f = io.open(current_output, "wb")
        if f == nil then help.err("Can not create "..current_output)
        else
            f:write(exe)
            f:close()
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)

        print_size(current_output)
    end

    -- Compile LuaX scripts with LuaX and Zig
    local function compile_zig(tmp, current_output, target_definition)
        if not quiet then print() end
        log("target", "%s", target_definition.name)
        log("output", "%s", current_output)

        -- Install Zig (to cross compile and link C sources)
        local zig_config = require "luax_config".zig
        if not fs.is_file(zig_config.zig) then
            log("Zig", "download and install Zig to %s", zig_config.path)
            zig_config.install()
            if not fs.is_file(zig_config.zig) then
                help.err("Unable to install Zig to %s", zig_config.path)
            end
        end

        -- Extract precompiled LuaX libraries
        local lib = findscript("luax-"..target_definition.name..".lib")
        if not fs.is_file(lib) then
            help.err("%s: LuaX library not found, please check LuaX installation", lib)
        end
        local libs = F(assert(cbor.decode(assert(assert(fs.read_bin(lib)):unlz4()))))
        libs:foreachk(function(filename, content)
            fs.write_bin(tmp/filename, content)
        end)
        local libnames = F.keys(libs)
            : filter(function(f) return f:ext():match"^%.[ao]$" end)
            : map(function(f) return tmp/f end)

        -- Compile the input LuaX scripts
        local app_bundle_c = "app_bundle.c"
        local app_bundle = assert(bundle.bundle {
            scripts = scripts,
            output = tmp/app_bundle_c,
            target = "c",
            entry = "app",
            product_name = current_output:basename():splitext(),
            bytecode = bytecode,
            strip = strip,
            key = key,
        })
        app_bundle : foreachk(fs.write_bin)

        local function zig_target(t)
            return {"-target", F{t.arch, t.os, t.libc}:str"-"}
        end

        -- Compile and link the generated source with Zig
        local zig_opt = {
            zig_target(target_definition),
            "-std=gnu2x",
            "-O3",
            "-I"..tmp,
            "-fPIC",
            "-s",
            "-lm",
            F.case(target_definition.os) {
                linux   = "-flto=thin",
                macos   = {},
                windows = {"-flto=thin", "-lws2_32 -ladvapi32"},
            },
            F.case(target_definition.libc) {
                gnu  = "-rdynamic",
                musl = {},
                none = "-rdynamic",
            },
        }
        assert(sh.run { zig_config.zig, "cc", zig_opt, libnames, tmp/app_bundle_c, "-o", current_output })

        print_size(current_output)
    end

    local interpreter = lua_interpreters[target or "luax"]
    if interpreter then
        compile_lua(output, name, interpreter)
        return
    end

    local target_definition = targets:filter(function(t) return t.name==target end):head()
    if target_definition then
        fs.with_tmpdir(function(tmp)
            compile_zig(tmp, output, target_definition)
        end)
        return
    end

    help.err(target..": unknown target")

end

actions:add(run_compiler)

actions:run()
