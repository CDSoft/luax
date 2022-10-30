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

local fs = require "fs"
local sys = require "sys"
local F = require "fun"
local I = F.I(_G)

local welcome = I(sys)[[
 _               __  __  |  http://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version $(_LUAX_VERSION)
| |__| |_| | (_| |/  \   |  Powered by $(_VERSION)
|_____\__,_|\__,_/_/\_\  |
                         |  $(os:cap()) $(arch) $(abi)
]]

local usage = I{fs=fs}[==[
usage: $(fs.basename(arg[0])) [options] [script [args]]

General options:
  -h                show this help
  -v                show version information
  --                stop handling options

Lua options:
  -e stat           execute string 'stat'
  -i                enter interactive mode after executing 'script'
  -l name           require library 'name' into global 'name'
  -                 stop handling options and execute stdin
                    (incompatible with -i)

Compilation options:
  -t target         name of the targetted platform
  -t all            compile for all available targets
  -t list           list available targets
  -o file           name the executable file to create

Scripts for compilation:
  file name         name of a Lua package to add to the binary
                    (the first one is the main script)
  -autoload         the next package will be loaded with require
                    and stored in a global variable of the same name
                    when the binary starts
  -autoload-all     all following packages (until -autoload-none)
                    are loaded with require when the binary starts
  -autoload-none    cancel -autoload-all
  -autoexec         the next package will be executed with require
                    when the binary start
  -autoexec-all     all following packages (until -autoexec-none)
                    are executed with require when the binary starts
  -autoexec-none    cancel -autoexec-all

Lua and Compilation options can not be mixed.
]==]

local function print_welcome()
    print(welcome)
end

local function print_usage(fmt, ...)
    print_welcome()
    if fmt then
        print(("error: %s"):format(fmt:format(...)))
        print("")
    end
    print(usage)
end

local function is_windows(compiler_target) return compiler_target:match "-windows-" end
local function ext(compiler_target) return is_windows(compiler_target) and ".exe" or "" end

local function findpath(name)
    if fs.is_file(name) then return name end
    local full_path = fs.findpath(name)
    return full_path and fs.realpath(full_path) or name
end

local function print_targets()
    F(require "targets"):map(function(target)
        local compiler = fs.join(fs.dirname(findpath(arg[0])), "luax-"..target..ext(target))
        print(("%-20s%s%s"):format(target, compiler, fs.is_file(compiler) and "" or " [NOT FOUND]"))
    end)
end

local function err(fmt, ...)
    print_usage(fmt, ...)
    os.exit(1)
end

local function wrong_arg(a)
    err("unrecognized option '%s'", a)
end

local function traceback(message)
    local trace = {"luax: "..message.."\n"}
    local luax = 0
    for _, line in ipairs(debug.traceback():lines()) do
        if line:match "^%s+luax.lua:" then luax = luax + 1
        elseif luax < 2 then table.insert(trace, line.."\n")
        end
    end
    table.remove(trace)
    io.stderr:write(table.concat(trace))
end

-- Read options

local interpretor_mode = false
local compiler_mode = false
local interactive = #arg == 0
local run_stdin = false
local actions = {}
local args = {}
local output = nil
local target = nil

local luax_loaded = false

local function load_luax()
    if not luax_loaded then
        -- luax functions loaded at the top level in interactive mode only
        local luax = require "luax"
        for k, v in pairs(luax) do _ENV[k] = v end
        luax_loaded = true
    end
end

do
    local i = 1
    -- Scan options
    while i <= #arg do
        local a = arg[i]
        if a == '-e' then
            interpretor_mode = true
            i = i+1
            local stat = arg[i]
            if stat == nil then wrong_arg(a) end
            actions[#actions+1] = function()
                assert(stat)
                load_luax()
                local chunk, msg = load(stat, "=(command line)")
                if not chunk then
                    io.stderr:write(("%s: %s\n"):format(arg[0], msg))
                    os.exit(1)
                end
                assert(chunk)
                local res = table.pack(xpcall(chunk, traceback))
                local ok = table.remove(res, 1)
                if ok then
                    if #res > 0 then
                        print(table.unpack(F.map(pretty, res)))
                    end
                else
                    os.exit(1)
                end
            end
        elseif a == '-i' then
            interpretor_mode = true
            interactive = true
        elseif a == '-l' then
            interpretor_mode = true
            i = i+1
            local lib = arg[i]
            if lib == nil then wrong_arg(a) end
            actions[#actions+1] = function()
                assert(lib)
                _G[lib] = require(lib)
            end
        elseif a == '-o' then
            compiler_mode = true
            i = i+1
            if output then wrong_arg(a) end
            output = arg[i]
        elseif a == '-t' then
            compiler_mode = true
            i = i+1
            if target then wrong_arg(a) end
            target = arg[i]
            if target == "list" then
                print_targets()
                os.exit()
            end
        elseif a == '-v' then
            print_welcome()
            os.exit()
        elseif a == '-h' then
            print_usage()
            os.exit(0)
        elseif a == '--' then
            i = i+1
            break
        elseif a == '-' then
            run_stdin = true
            -- this is not an option but a file (stdin) to execute
            args[#args+1] = arg[i]
            break
        elseif a == '-autoload' or a == '-autoload-all' or a == '-autoload-none'
            or a == '-autoexec' or a == '-autoexec-all' or a == '-autoexec-none' then
            -- this is an option for the compiler
            compiler_mode = true
            break
        elseif a:match "^%-" then
            wrong_arg(a)
        else
            -- this is not an option but a file to execute/compile
            break
        end
        i = i+1
    end
    -- scan files/arguments to execute/compile
    while i <= #arg do
        args[#args+1] = arg[i]
        i = i+1
    end
end

local function run_interpretor()

    -- scripts

    load_luax()

    if #args >= 1 then
        arg = {}
        local script = args[1]
        arg[0] = script == "-" and "stdin" or script
        for i = 2, #args do arg[i-1] = args[i] end
        local chunk, msg
        if script == "-" then
            chunk, msg = load(io.stdin:read "*a")
        else
            chunk, msg = loadfile(script)
        end
        if not chunk then
            io.stderr:write(("%s: %s\n"):format(script, msg))
            os.exit(1)
        end
        assert(chunk)
        local res = table.pack(xpcall(chunk, traceback))
        local ok = table.remove(res, 1)
        if ok then
            if #res > 0 then
                print(table.unpack(F.map(pretty, res)))
            end
        else
            os.exit(1)
        end
    end

    -- interactive REPL

    if interactive then
        local history = sys.os == "windows"
            and fs.join(os.getenv "APPDATA", "luax_history")
            or fs.join(os.getenv "HOME", ".luax_history")
        local linenoise = require "linenoise"
        linenoise.load(history)
        local function hist(input)
            linenoise.add(input)
            linenoise.save(history)
        end
        local function try(input)
            local chunk, msg = load(input, "=stdin")
            if not chunk then
                if msg and type(msg) == "string" and msg:match "<eof>$" then return "cont" end
                return nil, msg
            end
            local res = table.pack(xpcall(chunk, traceback))
            local ok = table.remove(res, 1)
            if ok then
                if res ~= nil then print(table.unpack(F.map(pretty, res))) end
            end
            return "done"
        end
        print_welcome()
        while true do
            local inputs = {}
            local prompt = ">> "
            while true do
                local line = linenoise.read(prompt)
                if not line then os.exit() end
                hist(line)
                table.insert(inputs, line)
                local input = table.concat(inputs, "\n")
                local try_expr, err_expr = try("return "..input)
                if try_expr == "done" then break end
                local try_stat, err_stat = try(input)
                if try_stat == "done" then break end
                if try_expr ~= "cont" and try_stat ~= "cont" then
                    print(try_stat == nil and err_stat or err_expr)
                    break
                end
                prompt = ".. "
            end
        end
    end

end

local function run_compiler()

    print_welcome()

    local scripts = args

    if #scripts == 0 then err "No input script specified" end
    if output == nil then err "No output specified (option -o)" end

    local function log(k, fmt, ...)
        print(("%-9s: %s"):format(k, fmt:format(...)))
    end

    -- List scripts
    local head = "scripts"
    local autoload = false
    local autoexec = false
    local autoload_all = false
    local autoexec_all = false
    for i = 1, #scripts do
        if scripts[i] == "-autoload" then autoload = true
        elseif scripts[i] == "-autoload-all" then autoload_all = true
        elseif scripts[i] == "-autoload-none" then autoload_all = false
        elseif scripts[i] == "-autoexec" then autoexec = true
        elseif scripts[i] == "-autoexec-all" then autoexec_all = true
        elseif scripts[i] == "-autoexec-none" then autoexec_all = false
        else
            if (autoload or autoload_all) and (autoexec or autoexec_all) then
                err("Can not autoload and autoexec a package")
            end
            log(head, "%s%s",
                (autoload or autoload_all) and "autoload "
                or (autoexec or autoexec_all) and "autoexec"
                or "",
                scripts[i])
            autoload = false
            autoexec = false
        end
        head = ""
    end

    -- Compile scripts for each targets
    local valid_targets = F.from_set(F.const(true), require "targets")
    local compilers = {}
    local function rmext(compiler_target, name) return name:gsub(ext(compiler_target):gsub("%.", "%%.").."$", "") end
    F(target == "all" and valid_targets:keys() or target and {target} or {}):map(function(compiler_target)
        if not valid_targets[compiler_target] then err("Invalid target: %s", compiler_target) end
        local compiler = fs.join(fs.dirname(findpath(arg[0])), "luax-"..compiler_target..ext(compiler_target))
        if fs.is_file(compiler) then compilers[#compilers+1] = {compiler, compiler_target} end
    end)
    if not target then
        local compiler = findpath(arg[0])
        if fs.is_file(compiler) then compilers[#compilers+1] = {compiler, nil} end
    end

    local function compile_target(current_output, compiler)
        local compiler_exe, compiler_target = table.unpack(compiler)
        if target == "all" then
            current_output = rmext(compiler_target, current_output).."-"..compiler_target..ext(compiler_target)
        end
        if compiler_target then
            current_output = rmext(compiler_target, current_output)..ext(compiler_target)
        end

        print()
        log("compiler", "%s", compiler_exe)
        log("output", "%s", current_output)

        local bundle = require "bundle"
        local exe, chunk = bundle.combine(compiler_exe, scripts)
        log("Chunk", "%7d bytes", #chunk)
        log("Total", "%7d bytes", #exe)

        local f = io.open(current_output, "wb")
        if f == nil then err("Can not create "..current_output)
        else
            f:write(exe)
            f:close()
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)
    end

    F(compilers):map(function(compiler)
        compile_target(output, compiler)
    end)

end

if interpretor_mode and compiler_mode then
    err "Lua options and compiler options can not be mixed"
end

if compiler_mode and not output then
    err "No output specified"
end

if interactive and run_stdin then
    err "Interactive mode and stdin execution are incompatible"
end

actions[#actions+1] = compiler_mode and run_compiler or run_interpretor

-- run actions
F.map(F.call, actions)
