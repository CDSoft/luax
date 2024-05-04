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
local term = require "term"
local luax_config = require "luax_config"

local bundle = require "luax_bundle"

local I = F.I % "%%{}"

local welcome = I(_G){sys=sys}[[
 _               __  __  |  https://cdelord.fr/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version %{_LUAX_VERSION} (%{_LUAX_DATE})
| |__| |_| | (_| |/  \   |  Powered by %{_VERSION}
|_____\__,_|\__,_/_/\_\  |%{PANDOC_VERSION and "  and Pandoc "..tostring(PANDOC_VERSION) or ""}
                         |  %{sys.os:cap()} %{sys.arch} %{sys.libc}
]]

local LUA_INIT = F{
    "LUA_INIT_" .. _VERSION:words()[2]:gsub("%.", "_"),
    "LUA_INIT",
}

local arg0 = arg[0]

local usage = I{arg0=arg0, init=LUA_INIT}(luax_config)[==[
usage: %{arg0:basename()} [options] [script [args]]

General options:
  -h                show this help
  -v                show version information
  --                stop handling options

Lua options:
  -e stat           execute string 'stat'
  -i                enter interactive mode after executing
                    'script'
  -l name           require library 'name' into global 'name'
  -l g=name         require library 'name' into global 'g'
  -l _=name         require library 'name' (no global variable)
  -                 stop handling options and execute stdin
                    (incompatible with -i)

Compilation options:
  -t target         name of the targetted platform
  -t list           list available targets
  -o file           name the executable file to create
  -b                compile to Lua bytecode
  -s                emit bytecode without debug information
  -k key            script encryption key
  -q                quiet compilation (error messages only)

Scripts for compilation:
  file.lua          name of a Lua package to add to the binary.
  file.xxx          file embeded as a module
                    returning the content of the file.

Lua and Compilation options can not be mixed.

Environment variables:

  %{init[1]}, %{init[2]}
                    code executed before handling command line
                    options and scripts (not in compilation
                    mode). When %{init[1]} is defined,
                    %{init[2]} is ignored.

  PATH              PATH shall contain the bin directory where
                    LuaX is installed

  LUA_PATH          LUA_PATH shall point to the lib directory
                    where the Lua implementation of LuaX
                    lbraries are installed

  LUA_CPATH         LUA_CPATH shall point to the lib directory
                    where LuaX shared libraries are installed

PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
with « luax env ».
E.g.: eval $(luax env)

« luax env » can also generate shell variables from a script.
E.g.: eval $(luax env script.lua)

Copyright:
  %{copyright}
  %{authors}
]==]

local welcome_already_printed = false

local function print_welcome()
    if welcome_already_printed then return end
    if term.isatty() then
        print(welcome)
    end
    welcome_already_printed = true
end

local function print_usage(fmt, ...)
    print_welcome()
    if fmt then
        print(("error: %s"):format(fmt:format(...)))
        print("")
    end
    print(usage:trim())
end

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
        print(("%-12s%s%s"):format(
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
    trace:foreachi(function(i, line)
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
local args = F{}
local output = nil
local target = nil
local quiet = false
local bytecode = nil
local strip = nil
local key = nil

local luax_loaded = false

local actions = setmetatable({
        actions = F{}
    }, {
    __index = {
        add = function(self, action) self.actions[#self.actions+1] = action end,
        run = function(self) self.actions:foreach(F.call) end,
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
$ lua -l luax
```

## Reduced version for plain Lua interpreters

### LuaX with a plain Lua interpreter

``` sh
luax.lua
```

### LuaX with the Pandoc Lua interpreter

``` sh
luax-pandoc.lua
```

The integration with Pandoc is interesting
to debug Pandoc Lua filters and inspect Pandoc AST.
E.g.:

``` sh
$ rlwrap luax-pandoc.lua

 _               __  __  |  https://cdelord.fr/luax
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

In interactive mode, these functions are available as global functions and modules.
@@@]]

local function populate_repl()

    -- luax functions loaded at the top level in interactive mode only

    if luax_loaded then return end
    luax_loaded = true

--[[@@@
LuaX preloads the following modules with the `-e` option or before entering the REPL:

- F
- complex
- crypt
- fs
- imath
- lz4
- mathx
- ps
- qmath
- sh
- sys

@@@]]

    F"F complex crypt fs imath lz4 mathx ps qmath sh sys lz4"
        : words()
        : foreach(function(name) _ENV[name] = require(name) end)

    local show_opt = F{}

--[[@@@
```lua
show(x)
```
returns a string representing `x` with nice formatting for tables and numbers.
@@@]]

    function _ENV.show(x, opt)
        if type(x) == "string" then return x end
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

end

local function run_lua_init()
    if compiler_mode then return end
    LUA_INIT
        : filter(function(var) return os.getenv(var) ~= nil end)
        : take(1)
        : foreach(function(var)
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

actions:add(run_lua_init)

local function pack_res(ok, ...)
    return { ok = ok, n = select("#", ...), ... }
end

local function show_res(res, show)
    show = show or F.show
    return F.range(1, res.n):map(function(i) return show(res[i]) end)
end

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
                populate_repl()
                assert(stat)
                local chunk, msg = load(stat, "=(command line)")
                if not chunk then
                    io.stderr:write(("%s: %s\n"):format(arg0, msg))
                    os.exit(1)
                end
                assert(chunk)
                local res = pack_res(xpcall(chunk, traceback))
                if res.ok then
                    if res.n > 0 then
                        print(show_res(res, show):unpack())
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
                local modname, filename = lib:match "(.-)=(.+)"
                if not modname then
                    modname, filename = lib, lib
                end
                local mod = require(filename)
                if modname ~= "_" then
                    _G[modname] = mod
                end
            end)
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
            if target == "list" then print_targets() os.exit() end
        elseif a == '-b' then
            compiler_mode = true
            bytecode = true
        elseif a == '-s' then
            compiler_mode = true
            bytecode = true
            strip = true
        elseif a == '-k' then
            compiler_mode = true
            i = i+1
            if key then wrong_arg(a) end
            key = arg[i]
        elseif a == '-q' then
            compiler_mode = true
            quiet = true
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

    if #args >= 1 then
        local script = args[1]
        local show, chunk, msg
        if script == "env" then
            local shell_env = require "luax_shell_env"
            show, chunk = F.id, function() return shell_env(arg0, args:drop(1)) end
        elseif script == "-" then
            chunk, msg = load(bundle.comment_shebang(io.stdin:read "*a"))
        else
            local function findscript(name)
                local candidates = F.nub({".", fs.dirname(arg[-1])} .. os.getenv"PATH":split(fs.path_sep))
                for _, path in ipairs(candidates) do
                    local candidate = path/name
                    if fs.is_file(candidate) then
                        if path=="." then return name end
                        return candidate
                    end
                end
                candidates : foreach(function(path)
                    io.stderr:write(("    no file '%s' in '%s'\n"):format(name, path))
                end)
                os.exit(1)
            end
            local real_script = findscript(script)
            chunk, msg = load(bundle.comment_shebang(assert(fs.read(real_script))), "@"..real_script)
        end
        if not chunk then
            io.stderr:write(("%s: %s\n"):format(script, msg))
            os.exit(1)
        end
        assert(chunk)
        local res = pack_res(xpcall(chunk, traceback))
        if res.ok then
            if res.n > 0 then
                print(show_res(res, show):unpack())
            end
        else
            os.exit(1)
        end
    end

    -- interactive REPL

    if interactive then
        local history = sys.os == "windows"
            and os.getenv "APPDATA" / "luax_history"
            or os.getenv "HOME" / ".luax_history"
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
            local res = pack_res(xpcall(chunk, traceback))
            if res.ok and res.n > 0 then
                print(show_res(res, show):unpack())
            end
            return "done"
        end
        print_welcome()
        populate_repl()
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

    if not quiet then print_welcome() end

    local scripts = args

    if #scripts == 0 then err "No input script specified" end
    if output == nil then err "No output specified (option -o)" end

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

    -- Prepare scripts for a Lua / Pandoc Lua target
    local function compile_lua(current_output, name, interpreter)
        if not quiet then print() end
        log("interpreter", "%s", name)
        log("output", "%s", current_output)

        local function findscript(script_name)
            return (  os.getenv "LUAX_LIB"
                   or (findpath(arg0):dirname():dirname() / "lib")
                   ) / script_name
        end
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
        log("Total", "%7d bytes", #exe)

        local f = io.open(current_output, "wb")
        if f == nil then err("Can not create "..current_output)
        else
            f:write(exe)
            f:close()
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)
    end

    local interpreter = lua_interpreters[target or "luax"]
        or err(target..": unknown interpreter")
    compile_lua(output, name, interpreter)

end

actions:add(compiler_mode and run_compiler or run_interpreter)

actions:run()
