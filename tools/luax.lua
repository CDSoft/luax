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

local fun = require "fun"
local fs = require "fs"
local sys = require "sys"

local welcome = fun.I(_G)(sys)[[
 _               __  __  |  Documentation: http://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version $(_LUAX_VERSION)
| |__| |_| | (_| |/  \   |  Powered by $(_VERSION)
|_____\__,_|\__,_/_/\_\  |
                         |  $(os:cap()) $(arch) $(abi) build
]]

local usage = fun.I(_G){fs=fs}[==[
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
  -t target         name of the luax binary compiled for the targetted platform
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
                        print(table.unpack(res))
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

if compiler_mode and not output then
    err "No output specified"
end

if interpretor_mode and compiler_mode then
    err "Lua options and compiler options can not be mixed"
    os.exit(1)
end

if interactive and run_stdin then
    err "Interactive mode and stdin execution are incompatible"
    os.exit(1)
end

-- run actions
fun.foreach(actions, function(action) action() end)

local function run_interpretor()

    -- scripts

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
                print(table.unpack(res))
            end
        else
            os.exit(1)
        end
    end

    -- interactive REPL

    if interactive then
        local rl = require "rl"
        local function try(input)
            local chunk, msg = load(input, "=stdin")
            if not chunk then
                if msg and type(msg) == "string" and msg:match "<eof>$" then return "cont" end
                return nil, msg
            end
            local res = table.pack(xpcall(chunk, traceback))
            local ok = table.remove(res, 1)
            if ok then
                if res ~= nil then print(table.unpack(res)) end
            end
            return "done"
        end
        print_welcome()
        while true do
            local inputs = {}
            local prompt = ">> "
            while true do
                local line = rl.read(prompt)
                if not line then os.exit() end
                table.insert(inputs, rl.read(prompt))
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

function run_compiler()

    print_welcome()

    local scripts = args

    if #scripts == 0 then err "No input script specified" end
    if output == nil then err "No output specified (option -o)" end

    local function search_in_path(name)
        local sep = sys.os == "windows" and ";" or ":"
        local pathes = os.getenv("PATH"):split(sep)
        for i = 1, #pathes do
            local path = fs.join(pathes[i], fs.basename(name))
            if fs.is_file(path) then return path end
        end
    end

    actual_target = target or arg[0]
    if not fs.is_file(actual_target) then
        actual_target = search_in_path(actual_target) or actual_target
    end
    if not fs.is_file(actual_target) then
        local luax = search_in_path(arg[0])
        actual_target = fs.join(fs.dirname(luax), fs.basename(actual_target))
    end
    if not fs.is_file(actual_target) then
        err("Can not find "..target)
    end

    local function log(k, fmt, ...)
        print(("%-8s: %s"):format(k, fmt:format(...)))
    end

    log("target", "%s", actual_target)
    log("output", "%s", output)
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

    local bundle = require "bundle"
    local exe, chunk = bundle.combine(actual_target, scripts)
    log("Chunk", "%7d bytes", #chunk)
    log("Total", "%7d bytes", #exe)

    assert(output)
    local f = io.open(output, "wb")
    if f == nil then err("Can not create "..output)
    else
        f:write(exe)
        f:close()
    end

    fs.chmod(output, fs.aX|fs.aR|fs.uW)

end

if interpretor_mode or not compiler_mode then run_interpretor() end
if compiler_mode then run_compiler() end
