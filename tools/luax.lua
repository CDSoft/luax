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

--@MAIN

local fs = require "fs"
local sys = require "sys"
local F = require "F"
local I = F.I(_G)

local has_compiler = pcall(require, "bundle")

local welcome = I{sys=sys}[[
 _               __  __  |  http://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version $(_LUAX_VERSION)
| |__| |_| | (_| |/  \   |  Powered by $(_VERSION)
|_____\__,_|\__,_/_/\_\  |$(PANDOC_VERSION and "  and Pandoc "..tostring(PANDOC_VERSION) or "")
                         |  $(sys.os:cap()) $(sys.arch) $(sys.abi)
]]

local LUA_INIT = F{
    "LUA_INIT_" .. _VERSION:words()[2]:gsub("%.", "_"),
    "LUA_INIT",
}

local usage = F.unlines(F.flatten {
    I{fs=fs}[==[
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
]==],
    has_compiler and [==[
Compilation options:
  -t target         name of the targetted platform
  -t all            compile for all available targets
  -t list           list available targets
  -o file           name the executable file to create
  -r                use rlwrap (lua and pandoc targets only)

Scripts for compilation:
  file name         name of a Lua package to add to the binary

Lua and Compilation options can not be mixed.
]==] or {},
    I{init=LUA_INIT}[==[
Environment variables:

  $(init[1]), $(init[2])
                    code executed before handling command line options
                    and scripts (not in compilation mode).
                    When $(init[1]) is defined, $(init[2]) is ignored.

  PATH              PATH shall contain the bin directory where LuaX
                    is installed

  LUA_PATH          LUA_PATH shall point to the lib directory where
                    the Lua implementation of LuaX lbraries are installed

  LUA_CPATH         LUA_CPATH shall point to the lib directory where
                    LuaX shared libraries are installed
]==],
    [==[
PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
with « luax env ».
E.g.: eval $(luax env)
]==]
    })

local welcome_already_printed = false

local function print_welcome()
    if welcome_already_printed then return end
    print(welcome)
    welcome_already_printed = true
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

local external_interpreters = F{
    ["lua"]          = { interpreter="lua",        format="-lua",    library="-l luax",    loader="" },
    ["lua-lua"]      = { interpreter="lua",        format="-lua",    library="-l luax",    loader="" },
    ["lua-luax"]     = { interpreter="lua",        format="-binary", library="-l libluax", loader="-l rt0" },
    ["luax"]         = { interpreter="luax",       format="-binary", library={},           loader="-l rt0" },
    ["luax-luax"]    = { interpreter="luax",       format="-binary", library={},           loader="-l rt0" },
    ["pandoc"]       = { interpreter="pandoc lua", format="-lua",    library="-l luax",    loader="" },
    ["pandoc-lua"]   = { interpreter="pandoc lua", format="-lua",    library="-l luax",    loader="" },
    ["pandoc-luax"]  = { interpreter="pandoc lua", format="-binary", library="-l libluax", loader="-l rt0" },
}

local function print_targets()
    print "Targets producing standalone LuaX executables:"
    local config = require "luax_config"
    F(config.targets):map(function(target)
        local compiler = fs.join(fs.dirname(findpath(arg[0])), "luax-"..target..ext(target))
        print(("    %-22s%s%s"):format(
            target,
            compiler:gsub("^"..os.getenv"HOME", "~"),
            fs.is_file(compiler) and "" or " [NOT FOUND]"
        ))
    end)
    print ""
    print "Targets based on an external Lua interpreter:"
    external_interpreters:items():map(function(name_def)
        local name, def = F.unpack(name_def)
        local exe = def.interpreter:words():head()
        local path = fs.findpath(exe)
        print(("    %-22s%s%s"):format(
            name,
            path and path:gsub("^"..os.getenv"HOME", "~") or exe,
            path and "" or " [NOT FOUND]"))
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
    local trace = F.flatten {
        "luax: "..message,
        debug.traceback():lines(),
    }
    local pos = 1
    trace:mapi(function(i, line)
        if line:trim() == "[C]: in function 'xpcall'" then
            pos = i-1
        end
    end)
    io.stderr:write(trace:take(pos):unlines())
end

-- Read options

local interpreter_mode = false
local compiler_mode = false
local interactive = #arg == 0
local run_stdin = false
local args = {}
local output = nil
local target = nil
local rlwrap = false

local luax_loaded = false

local actions = setmetatable({
        actions = F{}
    }, {
    __index = {
        add = function(self, action) self.actions[#self.actions+1] = action end,
        run = function(self) self.actions:map(F.call) end,
    },
})

--[=[-----------------------------------------------------------------------@@@
# LuaX interactive usage

The LuaX REPL can be run in various environments:

- the full featured LuaX interpreter based on the LuaX runtime
- the reduced version running on a plain Lua interpreter

## Full featured LuaX interpreter

### Self-contained interpreter

``` sh
$ luax
```

### Shared library usable with a standard Lua interpreter

``` sh
$ LUA_CPATH="lib/?.so" lua -l luax-x86_64-linux-gnu
```

## Reduced version for plain Lua interpreters

### LuaX with a plain Lua interpreter

``` sh
lua luax-lua.lua
```

### LuaX with the Pandoc Lua interpreter

``` sh
pandoc lua luax-lua.lua
```

The integration with Pandoc is interresting
to debug Pandoc Lua filters and inspect Pandoc AST.
E.g.:

``` sh
$ rlwrap pandoc lua luax-lua.lua

 _               __  __  |  http://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version X.Y
| |__| |_| | (_| |/  \   |  Powered by Lua X.Y
|_____\__,_|\__,_/_/\_\  |  and Pandoc X.Y
                         |  <OS> <ARCH>

>> pandoc.read "*Pandoc* is **great**!"
Pandoc (Meta {unMeta = fromList []}) [Para [Emph [Str "Pandoc"],Space,Str "is",Space,Strong [Str "great"],Str "!"]]
```

Note that [rlwrap](https://github.com/hanslub42/rlwrap)
can be used to give nice edition facilities to the Pandoc Lua interpreter.

@@@]=]

--[[@@@

## Additional modules

The `luax` repl provides a few functions for the interactive mode.

In interactive mode, these functions are available as global functions.
`show`{.lua} is used by the LuaX REPL to print results.
@@@]]

local function populate_repl()

    -- luax functions loaded at the top level in interactive mode only

    if luax_loaded then return end
    luax_loaded = true

    local show_opt = F{}

--[[@@@
```lua
show(x)
```
returns a string representing `x` with nice formatting for tables and numbers.
@@@]]

    function _ENV.show(x, opt)
        return F.show(x, show_opt:patch(opt))
    end

--[[@@@
```lua
precision(len, frac)
```
changes the format of floats. `len` is the
total number of characters and `frac` the number of decimals after the floating
point (`frac` can be `nil`). `len` can also be a string (custom format string)
or `nil` (to reset the float format). `b` can be `10` (decimal numbers), `16`
(hexadecimal numbers), `8` (octal numbers), a custom format string or `nil` (to
reset the integer format).
@@@]]

    function _ENV.precision(len, frac)
        show_opt.flt =
            type(len) == "string"                               and len
            or type(len) == "number" and type(frac) == "number" and ("%%%s.%sf"):format(len, frac)
            or type(len) == "number" and frac == nil            and ("%%%sf"):format(len, frac)
            or "%s"
    end

--[[@@@
```lua
base(b)
```
changes the format of integers. `b` can be `10` (decimal
numbers), `16` (hexadecimal numbers), `8` (octal numbers), a custom format
string or `nil` (to reset the integer format).
@@@]]

    function _ENV.base(b)
        show_opt.int =
            type(b) == "string" and b
            or b == 10          and "%s"
            or b == 16          and "0x%x"
            or b == 8           and "0o%o"
            or "%s"
    end

--[[@@@
```lua
indent(i)
```
indents tables (`i` spaces). If `i` is `nil`, tables are not indented.
@@@]]

    function _ENV.indent(i)
        show_opt.indent = i
    end

--[[@@@
```lua
prints(x)
```
prints `show(x)`
@@@]]

    function _ENV.prints(x)
        print(show(x))
    end

--[[@@@
```lua
inspect(x)
```
calls `inspect(x)` to build a human readable
representation of `x` (see the `inspect` package).
@@@]]

    local inspect = require "inspect"

    local remove_all_metatables = function(item, path)
        if path[#path] ~= inspect.METATABLE then return item end
    end

    local default_options = {
        process = remove_all_metatables,
    }

    function _ENV.inspect(x, options)
        return inspect(x, F.merge{default_options, options})
    end

--[[@@@
```lua
printi(x)
```
prints `inspect(x)` (without the metatables).
@@@]]

    if inspect then

        function _ENV.printi(x)
            print(inspect.inspect(x))
        end

    end

end

local function run_lua_init()
    if compiler_mode then return end
    LUA_INIT
        : filter(function(var) return os.getenv(var) ~= nil end)
        : take(1)
        : map(function(var)
            local code = assert(os.getenv(var))
            local filename = code:match "^@(.*)"
            local chunk, chunk_err
            if filename then
                chunk, chunk_err = loadfile(filename)
            else
                chunk, chunk_err = load(code, "="..var)
            end
            if not chunk then
                print(chunk_err)
                os.exit(1)
            end
            if chunk and not xpcall(chunk, traceback) then
                os.exit(1)
            end
        end)
end

local has_shell_env, shell_env = pcall(require, "shell_env")
if #arg == 1 and arg[1] == "env" then
    if has_shell_env then
        print(shell_env())
        os.exit()
    else
        print("use « luax env » instead")
        os.exit(1)
    end
end

actions:add(run_lua_init)

do
    local i = 1
    -- Scan options
    while i <= #arg do
        local a = arg[i]
        if a == '-e' then
            interpreter_mode = true
            i = i+1
            local stat = arg[i]
            if stat == nil then wrong_arg(a) end
            actions:add(function()
                assert(stat)
                populate_repl()
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
                        print(table.unpack(F.map(show, res)))
                    end
                else
                    os.exit(1)
                end
            end)
        elseif a == '-i' then
            interpreter_mode = true
            interactive = true
        elseif a == '-l' then
            interpreter_mode = true
            i = i+1
            local lib = arg[i]
            if lib == nil then wrong_arg(a) end
            actions:add(function()
                assert(lib)
                _G[lib] = require(lib)
            end)
        elseif has_compiler and a == '-o' then
            compiler_mode = true
            i = i+1
            if output then wrong_arg(a) end
            output = arg[i]
        elseif has_compiler and a == '-t' then
            compiler_mode = true
            i = i+1
            if target then wrong_arg(a) end
            target = arg[i]
            if target == "list" then
                print_targets()
                os.exit()
            end
        elseif has_compiler and a == "-r" then
            compiler_mode = true
            rlwrap = true
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
        elseif a:match "^%-" then
            wrong_arg(a)
        else
            -- this is not an option but a file to execute/compile
            break
        end
        i = i+1
    end

    local arg_shift = i

    -- scan files/arguments to execute/compile
    while i <= #arg do
        args[#args+1] = arg[i]
        i = i+1
    end

    interpreter_mode = interpreter_mode or not compiler_mode

    if interpreter_mode and compiler_mode then
        err "Lua options and compiler options can not be mixed"
    end

    if compiler_mode and not output then
        err "No output specified"
    end

    if interactive and run_stdin then
        err "Interactive mode and stdin execution are incompatible"
    end

    if interpreter_mode then
        -- shift arg such that arg[0] is the name of the script to execute
        local n = #arg
        for j = 0, n do
            arg[j-arg_shift] = arg[j]
        end
        for j = n-arg_shift+1, n do
            arg[j] = nil
        end
        if arg[0] == "-" then arg[0] = "stdin" end
    end

end

local function run_interpreter()

    -- scripts

    populate_repl()

    if #args >= 1 then
        local script = args[1]
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
                print(table.unpack(F.map(show, res)))
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
                if res ~= nil then print(table.unpack(F.map(show, res))) end
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

    -- Check the target parameter
    local config = require "luax_config"
    local valid_targets = F.from_set(F.const(true), config.targets)
    local compilers = {}
    local function rmext(compiler_target, name) return name:gsub(ext(compiler_target):gsub("%.", "%%.").."$", "") end
    F(target == "all" and valid_targets:keys() or target and {target} or {}):map(function(compiler_target)
        if external_interpreters[target] then return end
        if not valid_targets[compiler_target] then err("Invalid target: %s", compiler_target) end
        local compiler = fs.join(fs.dirname(findpath(arg[0])), "luax-"..compiler_target..ext(compiler_target))
        if fs.is_file(compiler) then compilers[#compilers+1] = {compiler, compiler_target} end
    end)
    if not target then
        local compiler = findpath(arg[0])
        if fs.is_file(compiler) then compilers[#compilers+1] = {compiler, nil} end
    end

    -- luax lib path
    local luax_lib_path = F.flatten {
        fs.join(fs.dirname(arg[0]), "luax.lua"),
        fs.join(fs.dirname(arg[0]), "..", "lib", "luax.lua"),
        fs.join(fs.dirname(arg[0]), "lib", "luax.lua"),
    }:filter(fs.is_file):head()

    -- List scripts
    local head = "scripts"
    for i = 1, #scripts do
        log(head, "%s", scripts[i])
        head = ""
    end

    -- Compile scripts for each targets
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

    -- Prepare scripts for a Lua / Pandoc Lua target
    local function compile_lua(current_output, name, interpreter)
        if target == "all" then
            current_output = current_output.."-"..name:words():head()
        end

        print()
        log("interpreter", "%s", name)
        log("output", "%s", current_output)

        local bundle = require "bundle"
        local chunk = bundle.combine_lua{interpreter.format, scripts}
        local exe = F.flatten{
                "#!/usr/bin/env -S",

                -- call the interpreter with rlwrap (option -r)
                rlwrap and {"rlwrap -C", fs.basename(current_output)} or {},

                -- "luax", "lua" or "pandoc lua" interpreter
                interpreter.interpreter,

                -- load luax library (.lua or .so)
                interpreter.library,

                -- load the LuaX runtime
                interpreter.loader,

                -- remaining parameters are given to the main script
                "--",
            }:unwords()
            .."\n"
            ..chunk
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
    external_interpreters:mapk(function(name, interpreter)
        if target == "all" or target == name then
            compile_lua(output, name, interpreter)
        end
    end)

end

actions:add(compiler_mode and run_compiler or run_interpreter)

actions:run()

-- vim: set ts=4 sw=4 foldmethod=marker :
