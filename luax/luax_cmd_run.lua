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
local sys = require "sys"
local F = require "F"

local bundle = require "luax_bundle"
local welcome = require "luax_welcome"
local help = require "luax_help"

local arg0 <const> = arg[0]

local function wrong_arg(a)
    help.err("unrecognized option '%s'", a)
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

local interactive = #arg == 0
local run_stdin = false
local args = F{}

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

 _               __  __  |  https://github.com/cdsoft/luax
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

    function show(x, opt)
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

    function precision(len, frac)
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

    function base(b)
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

    function indent(i)
        show_opt.indent = i
    end

--[[@@@
```lua
prints(x)
```
prints `show(x)`
@@@]]

    function prints(x)
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
            interactive = true
        elseif a == '-l' then
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
        elseif a == '-v' then
            require "luax_cmd_version"
            os.exit()
        elseif a == '-h' then
            help.print()
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
        help.err "Interactive mode and stdin execution are incompatible"
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

    -- scripts

    if #args >= 1 then
        local script = args[1]
        local show, chunk, msg
        if script == "-" then
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
            chunk, msg = load(bundle.comment_shebang(assert(fs.read_bin(real_script))), "@"..real_script)
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
        local home = F.case(sys.os) {
            windows = "APPDATA",
            [F.Nil] = "HOME",
        }
        local history = os.getenv(home) / ".luax_history"
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
        welcome()
        populate_repl()
        local prompts = {">> ", ".. "}
        while true do
            local inputs = {}
            local prompt = prompts[1]
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
                prompt = prompts[2]
            end
        end
    end

end

actions:add(run_interpreter)

actions:run()
