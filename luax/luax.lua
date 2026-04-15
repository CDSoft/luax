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
https://codeberg.org/cdsoft/luax
--]]

--@MAIN

local F = require "F"
local fs = require "fs"
local term = require "term"

-------------------------------------------------------------------------------
-- Help command
-------------------------------------------------------------------------------

local function colorize(fd)
    term.color.enable(term.isatty(fd))
end

local function print_welcome()

    local sys = require "sys"
    local version = require "luax-version"

    local I = (F.I % "%%{}")(_G){
        sys = sys,
        version = version,
    }

    local welcome = I[===[
 _               __  __  |  https://%{version.url}
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version %{version.version}
| |__| |_| | (_| |/  \   |  Powered by %{_VERSION}
|_____\__,_|\__,_/_/\_\  |%{PANDOC_VERSION and "  and Pandoc "..tostring(PANDOC_VERSION) or ""}
                         |  %{sys.os:cap()} %{sys.arch} %{sys.libc}
]===]

    if term.isatty(io.stdout) then
        colorize(1)
        print((term.color.green+term.color.bold)(welcome))
    end

    print_welcome = F.const() -- print the welcome message once
end

local function usage()
    colorize(1)
    local I = (F.I % "%%{}") (term.color) {
        arg = arg,
        lua_init = { "LUA_INIT_".._VERSION:words()[2]:gsub("%.", "_"), "LUA_INIT" },
    }
    return (I[===[
usage: %{arg[0]:basename()} [cmd] [options]

%{green'Commands:'}
  "help"    (or "-h")   Show this help
  "version" (or "-v")   Show LuaX version
  "run"     (or none)   Run scripts
  "compile" (or "c")    Compile scripts
  "env"                 Set LuaX environment variables
  "postinstall"         Post install updates

%{green'"run" options:'}
  -e stat         execute string 'stat'
  -i              enter interactive mode after executing 'script'
  -l name         require library 'name' into global 'name'
  -l g=name       require library 'name' into global 'g'
  -l _=name       require library 'name' (no global variable)
  -v              show version information
  -W              turn warnings on
  --              stop handling options
  -               stop handling options and execute stdin
  script [args]   script to execute

%{green'"compile" options:'}
  -t target       name of the targetted platform
  -t list         list available targets
  -o file         name the executable file to create
  -b              compile to Lua bytecode
  -s              emit bytecode without debug information
  -k key          script encryption key
  -q              quiet compilation (error messages only)
  scripts         scripts to compile

%{green'"postinstall" options:'}
  -f              do not ask for confirmations

%{green'Environment variables:'}

  %{lua_init[1]}, %{lua_init[2]}
                code executed before handling command line
                options and scripts (not in compilation
                mode). When %{lua_init[1]} is defined,
                %{lua_init[2]} is ignored.

  PATH          PATH shall contain the bin directory where
                LuaX is installed

  LUA_PATH      LUA_PATH shall point to the lib directory
                where the Lua implementation of LuaX
                libraries are installed

PATH and LUA_PATH can be set in %{italic'.bashrc'} or %{italic'.zshrc'}
with "%{italic'luax env'}".
E.g.: %{italic'eval $(luax env)'}

"%{italic'luax env"'} can also generate shell variables from a script
or a TOML file.
E.g.: %{italic'eval $(luax env script.lua)'}
]===]):trim()
end

local function print_usage()
    print_welcome()
    print(usage())
end

local function print_error(fmt, ...)
    colorize(2)
    io.stderr:write("\n")
    io.stderr:write((term.color.red"error: %s"):format(fmt:format(...)), "\n")
    io.stderr:write("\n")
    os.exit(1)
end

local function cmd_help()

    print_usage()

end
-------------------------------------------------------------------------------
-- Version command
-------------------------------------------------------------------------------

local function cmd_version()

    local luax_version = require "luax-version"
    io.stdout:write(tostring(luax_version), "  ", luax_version.copyright, "\n")

end

-------------------------------------------------------------------------------
-- Run command
-------------------------------------------------------------------------------

local function comment_shebang(script)
    return script
        : gsub("^#!.-\n(\x1b)", "%1")   -- remove the whole shebang of compiled scripts
        : gsub("^#!", "--")             -- comment the shebang before loading the script
end

local function wrong_arg(a)
    print_error("unrecognized option '%s'", a)
end

local function cmd_run()

    local function msgtostr(msg)
        if type(msg) == "string" then return msg end
        local mt = getmetatable(msg)
        if mt and mt.__tostring then
            local str = tostring(msg)
            if type(str) == "string" then return str end
        end
        return string.format("(error object is a %s value)", type(msg))
    end

    local function traceback(message)
        colorize(2)
        local trace = F.flatten {
            term.color.red("luax: "..msgtostr(message)),
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

    local interactive = #arg == 0
    local run_stdin = false
    local args = F{}

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

### Lua library usable with a standard Lua interpreter

``` sh
$ lua -l libluax
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

 _               __  __  |  https://codeberg.org/cdsoft/luax
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

        populate_repl = F.const() -- run this function one

--[[@@@
LuaX preloads the following modules with the `-e` option or before entering the REPL:

- F
- crypt
- fs
- ps
- sh
- sys

@@@]]

        F"F crypt fs ps sh sys"
            : words()
            : foreach(function(name) _ENV[name] = require(name) end)

        local show_opt = F{}

--[[@@@
```lua
show(x)
```
returns a string representing `x` with nice formatting for tables and numbers.
@@@]]

        function _G.show(x, opt)
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

        function _G.precision(len, frac)
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

        function _G.base(b)
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

        function _G.indent(i)
            show_opt.indent = i
        end

--[[@@@
```lua
prints(x)
```
prints `show(x)`
@@@]]

        function _G.prints(x)
            print(show(x))
        end

    end

    local function run_lua_init()
        F{ "LUA_INIT_".._VERSION:words()[2]:gsub("%.", "_"), "LUA_INIT" }
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
                    colorize(2)
                    io.stderr:write(term.color.red(chunk_err), "\n")
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
                i = i+1
                local stat = arg[i]
                if stat == nil then wrong_arg(a) end
                actions:add(function()
                    populate_repl()
                    assert(stat)
                    local chunk, msg = load(stat, "=(command line)")
                    if not chunk then
                        colorize(2)
                        io.stderr:write((term.color.red"%s: %s"):format(arg[0], msg), "\n")
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
                interactive = true
            elseif a == '-l' then
                i = i+1
                local lib = arg[i]
                if lib == nil then wrong_arg(a) end
                actions:add(function()
                    assert(lib)
                    local modname, filename = lib:split("=", 1) : unpack()
                    filename = filename or lib
                    local mod = require(filename)
                    if modname ~= "_" then
                        _G[modname] = mod
                    end
                end)
            elseif a == '-W' then
                warn "@on"
            elseif a == '-v' then
                cmd_version()
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
                -- this is not an option but a file to execute
                break
            end
            i = i+1
        end

        local arg_shift = i

        -- scan files/arguments to execute
        while i <= #arg do
            args[#args+1] = arg[i]
            i = i+1
        end

        if interactive and run_stdin then
            print_error "Interactive mode and stdin execution are incompatible"
        end

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

    local function run_interpreter()

        local sys = require "sys"

        -- scripts

        if #args >= 1 then
            local script = args[1]
            local show, chunk, msg
            if script == "-" then
                chunk, msg = load(comment_shebang(io.stdin:read "*a"))
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
                    colorize(2)
                    candidates : foreach(function(path)
                        io.stderr:write((term.color.red"    no file '%s' in '%s'"):format(name, path), "\n")
                    end)
                    os.exit(1)
                end
                local real_script = findscript(script)
                chunk, msg = load(comment_shebang(assert(fs.read_bin(real_script))), "@"..real_script)
            end
            if not chunk then
                colorize(2)
                io.stderr:write((term.color.red"%s: %s"):format(script, msg), "\n")
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
            local home = F.case(sys.os) {
                windows = "APPDATA",
                [F.Nil] = "HOME",
            }
            local history = os.getenv(home) / ".luax_history"
            local readline = require "readline"
            readline.name "LuaX"
            readline.load(history)
            local function hist(input)
                readline.add(input)
                readline.save(history)
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
            local initial_prompt      = ">> "
            local continuation_prompt = ".. "
            while true do
                local inputs = {}
                local prompt = initial_prompt
                while true do
                    local line = readline.read(prompt)
                    if not line then os.exit() end
                    hist(line)
                    table.insert(inputs, line)
                    local input = table.concat(inputs, "\n")
                    local try_expr, err_expr = try("return "..input)
                    if try_expr == "done" then break end
                    local try_stat, err_stat = try(input)
                    if try_stat == "done" then break end
                    if try_expr ~= "cont" and try_stat ~= "cont" then
                        colorize(2)
                        io.stderr:write(term.color.red(try_stat == nil and err_stat or err_expr), "\n")
                        break
                    end
                    prompt = continuation_prompt
                end
            end
        end

    end

    actions:add(run_interpreter)

    actions:run()

end

-------------------------------------------------------------------------------
-- Compile command
-------------------------------------------------------------------------------

local function find_exe(name)

    local sys = require "sys"

    local exe = fs.is_file(name) and name
            or (sys.exe ~= "" and fs.is_file(name..sys.exe) and name..sys.exe)
            or fs.findpath(name)
            or (sys.exe ~= "" and fs.findpath(name..sys.exe))
    if not exe then
        print_error("%s: not found", name)
    end
    return exe
end

local function cmd_compile()

    local crypt = require "crypt"
    local sys = require "sys"
    local targets = require "luax-targets"
    local luax_version = require "luax-version"

    local format = string.format
    local byte = string.byte
    local char = string.char
    local sub = string.sub

    local magic = "LuaX"

    local lua_interpreters = F{
        { name="luax",   add_luax_runtime=false },
        { name="lua",    add_luax_runtime=true  },
        { name="pandoc", add_luax_runtime=true  },
    }

    local function last_line(s)
        return s
        : lines()
        : drop_while_end(F.compose{string.null, string.trim})
        : last() or ""
    end

    local function mlstr(s)
        local n = (s:matches"](=*)]":map(F.op.len):maximum() or -1) + 1
        local eqs = ("="):rep(n)
        return F.str{"[", eqs, "[", s, "]", eqs, "]"}
    end

    local esc = {
        ["'"]  = "\\'",     -- ' must be escaped as it is embeded in single quoted strings
        ["\\"] = "\\\\",    -- \ must be escaped to avoid confusion with escaped chars
    }
    F.flatten{
        F.range(0, 31),     -- non printable control chars
        F.range(48, 57),    -- 0..9 must be escaped to avoid confusion decimal escape codes
        F.range(128, 255)   -- non 7-bit ASCII codes are also not printable
    }
    : foreach(function(b) esc[char(b)] = format("\\%d", b) end)

    local function escape(s)
        return format("'%s'", s:gsub(".", esc))
    end

    local function qstr(s)
        if s:match "^[%g%s]*$" then
            -- printable string => use multiline Lua strings
            return mlstr(s)
        else
            -- non printable string => escape non printable chars
            return escape(s)
        end
    end

    local function find_main(scripts)
        local explicit_main = F{}
        local implicit_main = F{}
        for i = 1, #scripts do
            local script = scripts[i]
            if script.is_main then
                explicit_main[#explicit_main+1] = script
            elseif not script.is_lib and not script.is_load and not script.maybe_lib then
                implicit_main[#implicit_main+1] = script
            end
        end
        local main_script = nil
        if #explicit_main > 1 then
            error("Too many main scripts: "..explicit_main:map(F.partial(F.nth, "path")):str", ")
        elseif #explicit_main == 1 then
            main_script = explicit_main[1]
        elseif #implicit_main > 1 then
            error("Too many main scripts: "..implicit_main:map(F.partial(F.nth, "path")):str", ")
        elseif #implicit_main == 1 then
            main_script = implicit_main[1]
        end
        return main_script, scripts:filter(function(script) return script ~= main_script end)
    end

    local function make_key(input, opt)
        local function chunks_of_chars(n, s)
            local chunks = F{}
            for i = 1, #s, n do
                chunks[#chunks+1] = sub(s, i, i+n-1)
            end
            return chunks
        end
        local kmin <const>, kmax <const> = 8, 256
        local mmin <const>, mmax <const> = 256, 64*1024
        local key_size = F.floor(kmin + (#input-mmin)*((kmax-kmin)/(mmax-mmin)))
        key_size = F.max(kmin, F.min(kmax, key_size))
        return chunks_of_chars(key_size, input:arc4(opt.key)) : fold1(crypt.arc4)
    end

    local function compact(s)
        return s
            : lines()
            : map(string.trim)
            : filter(function(l) return #l>0 end)
            : str";"
    end

    local function bytecode(code, opt, names)
        if opt.bytecode then
            code = assert(string.dump(assert(load(code, "@$"..F(names):str":")), opt.strip))
        end
        return code
    end

    local function obfuscate_lua(code, opt, names)
        code = bytecode(code, opt, names)
        if opt.key then
            -- Encrypt code by xoring bytes with pseudo random values
            local key = make_key(code, opt)
            local a <const>, c <const> = 6364136223846793005, 1
            local seed = tonumber(key:hash(), 16)
            local r = seed
            local xs = {}
            for i = 1, #code do
                local b = byte(code, i)
                r = r*a + c
                xs[i] = char(b ~ ((r>>33) & 0xff))
            end
            code = compact(F.I { a=a, c=c, b=escape(table.concat(xs)), seed=seed } [===[
                local b,a,c,r,x,bt,ch,l,tc=$(b),$(a),$(c),$(("0x%x"):format(seed)),{},string.byte,string.char,load,table.concat
                for i=1,#b do r=r*a+c x[i]=ch(bt(b,i)~((r>>33)&0xff))end
                return l(tc(x))()
            ]===])
            code = bytecode(code, opt, F.take(1, names))
        end
        return code
    end

    local function obfuscate_luax(code, opt, names)

        code = bytecode(code, opt, names)

        if opt.key then
            local key = make_key(code, opt)
            code = compact(F.I { b=escape(code:arc4(key)), k=escape(key) } [===[
                return load(require"_crypt".unarc4($(b), $(k)))()
            ]===])
            code = bytecode(code, opt, F.take(1, names))
        end

        return code
    end

    local known_modules = {}

    local function ensure_unique_module(script)
        local name = script.lib_name
        if known_modules[name] then
            error(name..": duplicate module")
        end
        known_modules[name] = true
    end

    local function bundle(opt)

        opt.bytecode = opt.bytecode or opt.strip -- strip implies bytecode

        local scripts = F{}

        local function load_script(script, prefix, patch)
            local len_prefix = prefix and #prefix+2 or 1
            local content = assert(fs.read_bin(script))
            local ext = fs.ext(script)
            local module
            if ext == ".lua" then
                module = F {
                    path      = script:sub(len_prefix),
                    content   = comment_shebang(content),
                    is_main   = content:match("@".."MAIN"),
                    is_lib    = content:match("@".."LIB"),
                    lib_name  = content:match("@".."LIB=([%w%._%-]+)") or script:basename():splitext(),
                    is_load   = content:match("@".."LOAD"),
                    load_name = content:match("@".."LOAD=([%w%._%-]+)"),
                    maybe_lib = last_line(content):match "^%s*return",
                }
            else
                -- file embeded as a Lua module returning the content of the file
                if content:match"^[%g%s]*$" and #content:lines() <= 1 then content = content:trim() end
                local safe_content = qstr(content)
                module = F {
                    path      = script:sub(len_prefix),
                    content   = "return "..safe_content,
                    is_main   = false,
                    is_lib    = true,
                    lib_name  = script:basename(),
                    is_load   = false,
                    load_name = false,
                    maybe_lib = false,
                }
            end
            if patch then module = module:patch(patch) end
            scripts[#scripts+1] = module
        end

        if opt.add_luax_runtime then
            local prefix = find_exe(arg[0]):realpath():dirname():dirname()
            fs.ls(prefix/"lib/luax/*.lua") : foreach(function(script)
                load_script(script, prefix, { is_main=false })
            end)
            if opt.add_ext_runtime then
                fs.ls(prefix/"lib/luax/ext/*.lua") : foreach(function(script)
                    load_script(script, prefix, { is_main=false })
                end)
            end
        end

        F.foreach(opt.scripts, load_script)

        if not opt.output then
            return F{}
        end

        if opt.target:match "^lua" or opt.target == "pandoc" then
            local product_name = opt.product_name or opt.output:basename():splitext()
            local preloads = {}
            local loads = {}
            local run_main = {}
            local interpreter = {
                lua    = "lua",
                pandoc = "pandoc lua",
                luax   = "luax",
            }
            local shebang = interpreter[opt.target] and "#!/usr/bin/env -S "..interpreter[opt.target].." --" or {}
            local out = F{
                "",
                "-- Generated with LuaX",
                ("-- %s"):format(luax_version.copyright),
                "",
                ("_LUAX_VERSION = %q"):format(tostring(luax_version)),
                "",
                opt.strip and {
                    "local function lib(src) return assert(load(src)) end",
                } or {
                    ("local function lib(path, src) return assert(load(src, '@$%s:'..path)) end"):format(product_name)
                },
                preloads,
                loads,
                run_main,
            }
            local function compile(script)
                -- check script compilation (with the actual file path in error messages)
                assert(load(script.content, ("@%s"):format(script.path)))
                if opt.bytecode then
                    -- compile the script with file path containing the product name
                    return qstr(bytecode(script.content, opt, {product_name, script.path}))
                else
                    return mlstr(script.content)
                end
            end
            local main_script, libs = find_main(scripts)
            for i = 1, #libs do
                local script = libs[i]
                local name = script.lib_name
                ensure_unique_module(script)
                if opt.strip then
                    preloads[#preloads+1] = ("package.preload[%q] = lib(%s)"):format(name, compile(script))
                else
                    preloads[#preloads+1] = ("package.preload[%q] = lib(%q, %s)"):format(name, script.path, compile(script))
                end
            end
            for i = 1, #libs do
                local script = libs[i]
                if script.is_load then
                    local lib_name  = script.lib_name
                    local load_name = script.load_name or lib_name
                    if load_name == "_" then
                        loads[#loads+1] = ("require %q"):format(lib_name)
                    else
                        loads[#loads+1] = ("_ENV[%q] = require %q"):format(load_name, lib_name)
                    end
                end
            end
            if main_script then
                local script = main_script
                if opt.strip then
                    run_main[#run_main+1] = ("return lib(%s)()"):format(compile(script))
                else
                    run_main[#run_main+1] = ("return lib(%q, %s)()"):format(script.path, compile(script))
                end
            end
            local obfuscate = opt.target:match "^luax" and obfuscate_luax or obfuscate_lua
            out = obfuscate(out:flatten():unlines(), F(opt):patch{strip=true}, {product_name})
            return F{
                [opt.output] = F{shebang, out}:flatten():unlines(),
            }
        end

        error(tostring(opt.target)..": unknown target")
    end

    local function print_targets()
        colorize(1)
        print((term.color.green"%-22s%-25s"):format("Target", "Interpreter / LuaX loader"))
        print((term.color.green"%-22s%-25s"):format(("-"):rep(21), ("-"):rep(25)))
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
                path and "" or term.color.red" [NOT FOUND]"))
        end)
        local prefix = ("luax"..sys.exe):findpath():dirname():dirname()
        local native = prefix/"lib/luax/luax-loader-"..sys.name..sys.exe
        print(("%-22s%s%s"):format(
            "native",
            native and native:gsub("^"..home, "~") or native,
            fs.is_file(native) and "" or term.color.red" [NOT FOUND]"))
        targets:foreach(function(target)
            local loader = prefix/"lib/luax/luax-loader-"..target.name..target.exe
            print(("%-22s%s%s"):format(
                target.name,
                loader and loader:gsub("^"..home, "~") or loader,
                fs.is_file(loader) and "" or term.color.red" [NOT FOUND]"))
        end)
        print("")
        print((term.color.green"Lua compiler: %s (%s)"):format(_VERSION, luax_version))
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
                key = F.even(#arg[i]) and arg[i]:match("^[0-9A-Fa-f]+$") and arg[i]:unhex() or arg[i]
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
            print_error "No output specified"
        end

    end

    if not quiet then print_welcome() end

    local scripts = inputs

    if #scripts == 0 then print_error "No input script specified" end
    if output == nil then print_error "No output specified (option -o)" end

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

        local files = bundle {
            scripts = scripts,
            add_luax_runtime = interpreter.add_luax_runtime,
            add_ext_runtime = false,
            add_shebang = interpreter.add_shebang,
            output = current_output,
            target = interpreter.name,
            bytecode = bytecode,
            strip = strip,
            key = key,
        }
        local exe = files[current_output]

        if not fs.write_bin(current_output, exe) then
            print_error("Can not create %s", current_output)
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)

        print_size(current_output)
    end

    -- Compile LuaX scripts with LuaX and prepend a precompiled loader
    local function compile_loader(current_output, target_definition)
        if current_output:ext():lower() ~= target_definition.exe then
            current_output = current_output..target_definition.exe
        end
        if not quiet then print() end
        log("target", "%s", target_definition.name)
        log("output", "%s", current_output)

        -- Find the precompiled LuaX loader
        local prefix = find_exe(arg[0]):realpath():dirname():dirname()
        local loader = prefix/"lib/luax/luax-loader-"..target_definition.name..target_definition.exe
        if not fs.is_file(loader) then
            print_error("%s: no %s loader", prefix, target_definition.name)
        end

        -- Compile the input LuaX scripts
        local files = assert(bundle {
            scripts = scripts,
            add_luax_runtime = true,
            add_ext_runtime = true,
            output = current_output,
            target = "luax-loader",
            add_shebang = false,
            bytecode = bytecode or "-b",
            strip = strip,
            key = key,
        })

        local header = string.pack("<c4I4", magic, #files[current_output])
        local payload = F.str {
            files[current_output],
            header,
            header:hash32():unhex(),
        }

        local exe = assert(fs.read_bin(loader)) .. payload

        if not fs.write_bin(current_output, exe) then
            print_error("Can not create %s", current_output)
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)

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

        if not target_definition then
            print_error("%s: unknown target", target)
        end

        compile_loader(output, target_definition)

    end

end

-------------------------------------------------------------------------------
-- Env command
-------------------------------------------------------------------------------

local function cmd_env()

    local function luax_env(luax)

        local exe = find_exe(luax)
        local bin = assert(exe):dirname():realpath()
        local prefix = bin:dirname()
        local lib_lua = prefix / "lib" / "?.lua"

        local function update(lua_var, var_name, separator, new_path)
            return F{
                "export ", var_name, "=\"",
                F.flatten {
                    new_path,
                    lua_var : split(separator),
                    (os.getenv(var_name) or "") : split(separator),
                } : nub() : str(separator),
                "\";",
            } : str()
        end

        local lua_path_sep = package.config:words()[2]

        return F.unlines {
            update("",            "PATH",      fs.path_sep,  bin),
            update(package.path,  "LUA_PATH",  lua_path_sep, lib_lua),
        }
    end

    local function user_env(scripts)
        local import = require "import"
        local tomlx = require "tomlx"
        local function read(name)
            if name:ext() == ".toml" then return assert(tomlx.read(name)) end
            return assert(import(name))
        end
        local script = {}
        local function dump(t, p)
            if type(t) == "table" then
                F.foreachk(t, function(k, v)
                    dump(v, (p and p.."_" or "")..k)
                end)
            else
                local s = tostring(t)
                    : gsub('\\', '\\\\')
                    : gsub('\"', '\\"')
                    : gsub('`', '\\`')
                    : gsub('%$', '\\$')
                    : gsub('\n', '\\n')
                    : gsub('\r', '\\r')
                p = p : gsub("[^%w]", "_")
                script[#script+1] = F{"export ", p:upper(), '="', s, '";'}:str()
            end
        end
        F.foreach(scripts, F.compose{dump, read})
        return F.unlines(script)
    end

    if not arg or #arg==0 then
        io.stdout:write(luax_env(arg[0]))
    else
        io.stdout:write(user_env(arg))
    end

end

-------------------------------------------------------------------------------
-- Postinstall command
-------------------------------------------------------------------------------

local function cmd_postinstall()

    local sys = require "sys"
    local readline = require "readline"
    local version = require "luax-version"

    local found = term.color.green "✔"
    local not_found = term.color.red "✖"
    local recycle = term.color.yellow "♻"

    colorize(1)

    local expected_files = F.flatten {
        (sys.libc=="gnu" or sys.libc=="musl") and {
            "bin"/"luax"..sys.exe,
            "bin"/"bang"..sys.exe,
            "bin"/"lsvg"..sys.exe,
            "bin"/"ypp"..sys.exe,
        } or {},
        "bin"/"luax.lua",
        "bin"/"luax-pandoc.lua",
        "bin"/"bang.lua",
        "bin"/"lsvg.lua",
        "bin"/"ypp.lua",
        "bin"/"ypp-pandoc.lua",
        "lib"/"libluax.lua",
        require "luax-libs.txt" : lines(),
        require "luax-targets" : map(function(target) return "lib/luax/luax-loader-"..target.name..target.exe end),
    }
    local expected_dirs = expected_files : map(fs.dirname) : nub()

    local force = false
    local interactive = term.isatty(0) and term.isatty(1)

    do
        local i = 1
        while i <= #arg do
            local a = arg[i]
            if a == '-f' then
                force = true
            else
                wrong_arg(a)
            end
            i = i + 1
        end
    end

    local exe = find_exe(arg[0]):realpath()
    local prefix = assert(exe):dirname():dirname():realpath()
    local bin = prefix/"bin"
    local lib = prefix/"lib"
    local new_files = expected_files : map(function(file) return prefix/file end)
    local new_dirs = expected_dirs : map(function(dir) return prefix/dir end)

    local copyright = F.flatten{
        tostring(version),
        version.copyright : match "(Copyright.-%d+%-%d+)%s+(.-),%s+(.*)",
    }
    copyright[#copyright+1] = ("="):rep(copyright:map(F.op.len):maximum())
    print(copyright : map(term.color.green) : unlines())

    local function confirm(msg, ...)
        local prompt = string.format(msg, ...).."? [y/N]"
        local ans = nil
        repeat
            ans = readline.read(prompt) : trim() : lower()
        until ans:match "^[yn]?$"
        return ans == "y"
    end

    -- Search for installed files

    local all_found = true
    new_files : foreach(function(file)
        local exists = fs.is_file(file)
        print((exists and found or not_found).." "..(exists and F.id or term.color.red)(file))
        all_found = all_found and exists
    end)

    if not all_found then print_error("Some files are missing") end

    -- Search for obsolete files

    local obsolete_files = (fs.ls(bin/"**") .. fs.ls(lib/"**"))
        : filter(function(file) return file:basename():match "luax" end)
        : filter(function(file) return new_files:not_elem(file) and new_dirs:not_elem(file) end)

    if #obsolete_files > 0 then
        print("")
        obsolete_files : foreach(function(file)
            local rm = fs.is_dir(file) and fs.rmdir or fs.is_file(file) and fs.remove
            if not rm then return end -- may have been removed by a previous rmdir
            if force then
                print(string.format("%s remove %s", recycle, term.color.yellow(file)))
                assert(rm(file))
            elseif interactive then
                if confirm("%s remove obsolete LuaX %s '%s'", recycle, fs.is_dir(file) and "directory" or "file" ,term.color.yellow(file)) then
                    assert(rm(file))
                end
            else
                print(string.format("%s %s is obsolete", recycle, term.color.yellow(file)))
            end
        end)
    end

end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

local function run(func, drop)
    return function()
        for _ = 1, drop or 1 do table.remove(arg, 1) end
        return func()
    end
end

F.case(arg[1]) {
    help        = run(cmd_help),
    version     = run(cmd_version),
    [F.Nil]     = run(cmd_run, 0),
    run         = run(cmd_run),
    compile     = run(cmd_compile),
    c           = run(cmd_compile),
    env         = run(cmd_env),
    postinstall = run(cmd_postinstall),
}()
