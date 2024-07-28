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
local sys = require "sys"

local bundle = require "luax_bundle"
local help = require "luax_help"
local welcome = require "luax_welcome"
local targets = require "targets"

local lua_interpreters = F{
    { name="luax",   add_luax_runtime=false },
    { name="lua",    add_luax_runtime=true  },
    { name="pandoc", add_luax_runtime=true  },
}

local function print_targets()
    print(("%-22s%-25s"):format("Target", "Interpeter / LuaX archive"))
    print(("%-22s%-25s"):format(("-"):rep(21), ("-"):rep(25)))
    local home = os.getenv(F.case(sys.os) {
        windows = "LOCALAPPDATA",
        [F.Nil] = "HOME",
    })
    lua_interpreters:foreach(function(interpreter)
        local name = interpreter.name
        local exe = name
        local path = exe:findpath()
        print(("%-22s%s%s"):format(
            name,
            path and path:gsub("^"..home, "~") or exe,
            path and "" or " [NOT FOUND]"))
    end)
    local assets = require "luax_assets"
    local luax_lar = assets.path and assets.path:gsub("^"..home, "~") or "luax.lar"
    local luax_lar_found = assets.path and "" or " [NOT FOUND]"
    print(("%-22s%s%s"):format("native", luax_lar, luax_lar_found))
    targets:foreach(function(target)
        print(("%-22s%s%s"):format( target.name, luax_lar, luax_lar_found))
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

if not quiet then welcome() end

local scripts = inputs

if #scripts == 0 then help.err "No input script specified" end
if output == nil then help.err "No output specified (option -o)" end

local function log(k, fmt, ...)
    if quiet then return end
    print(("%-7s: %s"):format(k, fmt:format(...)))
end

-- List scripts
local head = "scripts"
for i = 1, #scripts do
    log(head, "%s", scripts[i])
    head = ""
end

local function print_size(current_output)
    local size, unit = assert(current_output:stat()).size, "bytes"
    if size > 64*1024 then size, unit = size//1024, "Kb" end
    log("Total", "%d %s", size, unit)
end

-- Prepare scripts for a Lua / Pandoc Lua target
local function compile_lua(current_output, interpreter)
    if not quiet then print() end
    log("target", "%s", interpreter.name)
    log("output", "%s", current_output)

    local files = bundle.bundle {
        scripts = scripts,
        add_luax_runtime = interpreter.add_luax_runtime,
        output = current_output,
        target = interpreter.name,
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
    if current_output:ext():lower() ~= target_definition.exe then
        current_output = current_output..target_definition.exe
    end
    if not quiet then print() end
    log("target", "%s", target_definition.name)
    log("output", "%s", current_output)

    -- Zig configuration
    local zig_version = require "luax_config".zig_version

    local home, zig_path = F.unpack(F.case(sys.os) {
        windows = { "LOCALAPPDATA", "zig" / zig_version },
        [F.Nil] = { "HOME", ".local/opt" / "zig" / zig_version },
    })
    zig_path = os.getenv(home) / zig_path
    local zig = zig_path/"zig"..sys.exe

    -- Install Zig (to cross compile and link C sources)
    if not zig:is_file() then
        log("Zig", "download and install Zig to %s", zig_path)
        local archive = "zig-"..sys.os.."-"..sys.arch.."-"..zig_version..".tar.xz"
        local url = "https://ziglang.org/download"/zig_version/archive
        local curl = fs.findpath("curl"..sys.exe)
        local wget = fs.findpath("wget"..sys.exe)
        local tar  = fs.findpath("tar"..sys.exe)
        local xz   = fs.findpath("xz"..sys.exe)
        assert(curl or wget, "curl or wget required to download Zig")
        assert(tar and xz, "tar and xz required to install Zig")
        assert(sh.run(
            curl and { curl, "-fSL", quiet and "-s" or "-#", url, "-o", tmp/archive }
            or
            wget and { wget, quiet and "-q" or "--progress=bar", url, "-O", tmp/archive }
        ))
        fs.mkdirs(zig_path)
        assert(sh.run("tar", "xJf", tmp/archive, "-C", zig_path, "--strip-components", 1))
        if not zig:is_file() then
            help.err("Unable to install Zig to %s", zig_path)
        end
    end

    -- Extract precompiled LuaX libraries
    local assets = require "luax_assets"
    local headers = F(assets.headers)
    local libs = F(assets[target_definition.name])
    headers:foreachk(function(filename, content) fs.write_bin(tmp/filename, content) end)
    libs:foreachk(function(filename, content) fs.write_bin(tmp/filename, content) end)
    local libnames = libs:keys()
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
            windows = {"-flto=thin", "-lws2_32 -ladvapi32 -lshlwapi"},
        },
        F.case(target_definition.libc) {
            gnu  = "-rdynamic",
            musl = {},
            none = "-rdynamic",
        },
    }
    local tmp_output = tmp/current_output:basename()
    assert(sh.run(zig, "cc", zig_opt, libnames, tmp/app_bundle_c, "-o", tmp_output))
    assert(fs.copy(tmp_output, current_output))

    print_size(current_output)
end

local interpreter = lua_interpreters:find(function(t)
    return t.name == (target or "luax")
end)

if interpreter then

    compile_lua(output, interpreter)

else

    local target_definition = targets:find(function(t)
        return t.name == (target=="native" and sys.name or target)
    end)

    if target_definition then

        fs.with_tmpdir(function(tmp)
            compile_zig(tmp, output, target_definition)
        end)

    else

        help.err(target..": unknown target")

    end

end
