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
https://github.com/cdsoft/luax
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
local lzip = require "lzip"

local lua_interpreters = F{
    { name="luax",   add_luax_runtime=false },
    { name="lua",    add_luax_runtime=true  },
    { name="pandoc", add_luax_runtime=true  },
}

local function print_targets()
    print(("%-22s%-25s"):format("Target", "Interpreter / LuaX archive"))
    print(("%-22s%-25s"):format(("-"):rep(21), ("-"):rep(25)))
    local home = os.getenv(F.case(sys.os) {
        windows = "LOCALAPPDATA",
        [F.Nil] = "HOME",
    })
    lua_interpreters:foreach(function(interpreter)
        local name = interpreter.name
        local path = (name..sys.exe):findpath()
        print(("%-22s%s%s"):format(
            name,
            path and path:gsub("^"..home, "~") or name,
            path and "" or " [NOT FOUND]"))
    end)
    local assets = require "luax_assets"
    if assets.path and assets.targets then
        local luax_lar = assets.path:gsub("^"..home, "~")
        if assets.targets[sys.name] then
            print(("%-22s%s"):format("native", luax_lar))
        end
        targets:foreach(function(target)
            if assets.targets[target.name] then
                print(("%-22s%s"):format(target.name, luax_lar))
            end
        end)
    end
    print("")
    print(("Lua compiler: %s (LuaX %s)"):format(_VERSION, _LUAX_VERSION))
    if assets.path and assets.targets then
        local build_config = require "luax_build_config"
        print(("C compiler  : %s"):format(build_config.compiler.full_version))
    end
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

    if not fs.write_bin(current_output, exe) then
        help.err("Can not create "..current_output)
    end

    fs.chmod(current_output, fs.aX|fs.aR|fs.uW)

    print_size(current_output)
end

-- Compile LuaX scripts with LuaX and Zig, gcc or clang
local function compile_native(tmp, current_output, target_definition)
    if current_output:ext():lower() ~= target_definition.exe then
        current_output = current_output..target_definition.exe
    end
    if not quiet then print() end
    log("target", "%s", target_definition.name)
    log("output", "%s", current_output)

    -- Build configuration
    local build_config = require "luax_build_config"

    local function uncompressed_name(name)
        local uncompressed, ext = name:splitext()
        return F.case(ext) {
            [".lz"]  = function() return uncompressed, lzip.unlzip end,
            [F.Nil]  = function() return name, F.id end,
        }()
    end

    -- Extract precompiled LuaX libraries
    local assets = require "luax_assets"
    local headers = F(assets.headers or {})
    local libs = F(assets.targets and assets.targets[target_definition.name] or {})
    if headers:null() or libs:null() then
        help.err("Compilation not available")
    end
    local function tmp_file(filename, content)
        local name, uncompress = uncompressed_name(filename)
        fs.write_bin(tmp/name:basename(), uncompress(content))
    end
    headers:foreachk(tmp_file)
    libs:foreachk(tmp_file)
    local rank = {
        ["luax.o"]      = 1,
        ["libluax.o"]   = 2,
        ["libluax.a"]   = 3,
        ["liblua.a"]    = 4,
        ["libssl.a"]    = 5,
        ["libcrypto.a"] = 6,
    }
    local libnames = libs:keys(function(a, b)
        local rank_a = assert(rank[uncompressed_name(a)], a..": unknown library")
        local rank_b = assert(rank[uncompressed_name(b)], b..": unknown library")
        return rank_a < rank_b
    end)
    : map(function(name)
        return tmp/uncompressed_name(name):basename()
    end)

    -- Compile the input LuaX scripts
    local app_bundle_c = "app_bundle.c"
    local app_bundle = assert(bundle.bundle {
        scripts = scripts,
        output = tmp/app_bundle_c,
        target = "c",
        entry = "app",
        product_name = current_output:basename():splitext(),
        bytecode = bytecode or "-b", -- defaults to bytecode compilation for native builds
        strip = strip,
        key = key,
    })
    app_bundle : foreachk(fs.write_bin)

    local tmp_output = tmp/current_output:basename()

    local function optional(flag)
        return flag and F.id or F.const{}
    end

    -- fix_lto fixes a zig 0.14.0 bug
    -- malloc is missing with musl and fast+lto compilation
    local fix_lto =
        build_config.compiler=="zig"
        and target_definition.os=="linux" and target_definition.libc=="musl"
        and build_config.mode=="fast"
            and F.const{}
            or F.id

    local flto = F.case(build_config.compiler.name) {
        zig   = fix_lto "-flto=thin",
        gcc   = fix_lto "-flto=auto",
        clang = fix_lto "-flto=thin",
    }

    local cflags = {
        F.case( build_config.compiler.name) {
            gcc   = {},
            clang = {},
            zig   = {"cc", "-target", F{target_definition.arch, target_definition.os, target_definition.libc}:str"-"},
        },
        "-std=gnu2x",
        F.case(build_config.mode) {
            fast  = "-O3",
            small = "-Os",
            debug = { "-g", "-Og" },
        },
        "-pipe",
        "-I"..tmp,
        "-fPIC",
        optional(build_config.lto)(F.case(target_definition.os) {
            linux   = flto,
            macos   = {},
            windows = flto,
        }),
        F.case(build_config.compiler.name) {
            gcc   = "-Wstringop-overflow=0",
            clang = "-Wno-single-bit-bitfield-constant-conversion",
            zig   = "-Wno-single-bit-bitfield-constant-conversion",
        },
    }
    local ldflags = {
        F.case(build_config.mode) {
            fast  = "-s",
            small = "-s",
            debug = {},
        },
        "-lm",
        F.case(target_definition.os) {
            linux   = {},
            macos   = {},
            windows = {
                "-lshlwapi",
                optional(build_config.socket) "-lws2_32",
                optional(build_config.ssl) "-lcrypt32",
            }
        },
        F.case(target_definition.libc) {
            gnu  = "-rdynamic",
            musl = {},
            none = "-rdynamic",
        },
    }

    local compiler = build_config.compiler.name

    if compiler == "zig" then

        -- Zig configuration
        local zig_version = build_config.compiler.version
        local zig_path = F.case(sys.os) {
            windows = build_config.zig.path_win:gsub("^~", os.getenv"LOCALAPPDATA" or "~"),
            [F.Nil] = build_config.zig.path:gsub("^~", os.getenv"HOME" or "~"),
        }/zig_version

        local zig = zig_path/"zig"..sys.exe

        -- Install Zig (to cross compile and link C sources)
        if not zig:is_file() then
            log("Zig", "download and install Zig to %s", zig_path)
            local archive = "zig-"..sys.os.."-"..sys.arch.."-"..zig_version..(sys.os=="windows" and ".zip" or ".tar.xz")
            local url = "https://ziglang.org/download/"..zig_version.."/"..archive
            local curl = require "curl"
            local term = require "term"
            assert(curl.request {
                "-fSL",
                (quiet or not term.isatty(io.stdout)) and "-s" or "-#",
                url,
                "-o", tmp/archive,
            })
            fs.mkdirs(zig_path)
            assert(sh.run("tar -xJf", tmp/archive, "-C", zig_path, "--strip-components", 1))
            if not zig:is_file() then
                help.err("Unable to install Zig to %s", zig_path)
            end
        end

        compiler = zig

    end

    -- Compile and link the generated source
    assert(sh.run(compiler, cflags, libnames, tmp/app_bundle_c, ldflags, "-o", tmp_output))

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
            compile_native(tmp, output, target_definition)
        end)

    else

        help.err(target..": unknown target")

    end

end
