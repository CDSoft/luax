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

-------------------------------------------------------------------------------
-- Help command
-------------------------------------------------------------------------------

local function print_welcome()

    local sys = require "sys"
    local term = require "term"

    local I = (F.I % "%%{}")(_G){sys=sys}

    local welcome = I[===[
 _               __  __  |  https://codeberg.org/cdsoft/luax
| |   _   _  __ _\ \/ /  |
| |  | | | |/ _` |\  /   |  Version %{_LUAX_VERSION} (%{_LUAX_DATE})
| |__| |_| | (_| |/  \   |  Powered by %{_VERSION}
|_____\__,_|\__,_/_/\_\  |%{PANDOC_VERSION and "  and Pandoc "..tostring(PANDOC_VERSION) or ""}
                         |  %{sys.os:cap()} %{sys.arch} %{sys.libc}
]===]

    if term.isatty() then
        print(welcome)
    end

    print_welcome = F.const() -- print the welcome message once
end

local function usage()
    local I = (F.I % "%%{}") (F.patch(require "luax_config", {
        arg = arg,
        lua_init = { "LUA_INIT_".._VERSION:words()[2]:gsub("%.", "_"), "LUA_INIT" },
    }))
    return (I[===[
usage: %{arg[0]:basename()} [cmd] [options]

Commands:
  "help"    (or "-h")   Show this help
  "version" (or "-v")   Show LuaX version
  "run"     (or none)   Run scripts
  "compile" (or "c")    Compile scripts
  "env"                 Set LuaX environment variables
  "postinstall"         Post install updates

"run" options:
  -e stat         execute string 'stat'
  -i              enter interactive mode after executing 'script'
  -l name         require library 'name' into global 'name'
  -l g=name       require library 'name' into global 'g'
  -l _=name       require library 'name' (no global variable)
  -v              show version information
  --              stop handling options
  -               stop handling options and execute stdin
  script [args]   script to execute

"compile" options:
  -t target       name of the targetted platform
  -t list         list available targets
  -o file         name the executable file to create
  -c              use a C compiler instead of the loader
  -b              compile to Lua bytecode
  -s              emit bytecode without debug information
  -z              compress with lzip
  -k key          script encryption key
  -q              quiet compilation (error messages only)
  scripts         scripts to compile

"postinstall" options:
  -f              do not ask for confirmations

Environment variables:

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

  LUA_CPATH     LUA_CPATH shall point to the lib directory
                where LuaX shared libraries are installed

PATH, LUA_PATH and LUA_CPATH can be set in .bashrc or .zshrc
with "luax env".
E.g.: eval $(luax env)

"luax env" can also generate shell variables from a script.
E.g.: eval $(luax env script.lua)
]===]):trim()
end

local function print_usage()
    print_welcome()
    print(usage())
end

local function print_error(fmt, ...)
    print("")
    print(("error: %s"):format(fmt:format(...)))
    print("")
    os.exit(1)
end

local function cmd_help()

    print_usage()

end
-------------------------------------------------------------------------------
-- Version command
-------------------------------------------------------------------------------

local function cmd_version()

    local luax_config = require "luax_config"

    local copyright_pattern = "(%S+%s+)(%S+%s*)(.*)"
    local luax_name, luax_version, luax_copyright = luax_config.copyright:match(copyright_pattern)
    local lua_name,  lua_version,  lua_copyright  = luax_config.lua_copyright:match(copyright_pattern)

    local w_name = math.max(#luax_name, #lua_name)
    local w_version = math.max(#luax_version, #lua_version)

    io.stdout:write(F.str{luax_name:ljust(w_name), luax_version:ljust(w_version), luax_copyright}, "\n")
    io.stdout:write(F.str{lua_name :ljust(w_name), lua_version :ljust(w_version), lua_copyright }:rtrim(), "\n")

end

-------------------------------------------------------------------------------
-- Run command
-------------------------------------------------------------------------------

local function wrong_arg(a)
    print_error("unrecognized option '%s'", a)
end

local function cmd_run()

    local bundle = require "luax_bundle"

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
        local trace = F.flatten {
            "luax: "..msgtostr(message),
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
                        io.stderr:write(("%s: %s\n"):format(arg[0], msg))
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

        local fs = require "fs"
        local sys = require "sys"

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
            print_welcome()
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

end

-------------------------------------------------------------------------------
-- Compile command
-------------------------------------------------------------------------------

local function cmd_compile()

    local fs = require "fs"
    local sh = require "sh"
    local sys = require "sys"

    local bundle = require "luax_bundle"
    local targets = require "targets"
    local lzip = require "lzip"
    local assets = require "luax_assets"
    local build_config = require "luax_build_config"

    local magic = "LuaX"

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
            print(("C compiler  : %s"):format(build_config.compiler.full_version))
        end
    end

    -- Read options

    local inputs = F{}
    local output = nil
    local target = nil
    local quiet = false
    local use_cc = false
    local bytecode = nil
    local strip = nil
    local compression = false
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
            elseif a == '-c' then
                use_cc = true
            elseif a == '-b' then
                bytecode = true
            elseif a == '-s' then
                bytecode = true
                strip = true
            elseif a == '-z' then
                compression = true
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

        local files = bundle.bundle {
            scripts = scripts,
            add_luax_runtime = interpreter.add_luax_runtime,
            add_shebang = interpreter.add_shebang,
            output = current_output,
            target = interpreter.name,
            bytecode = bytecode,
            strip = strip,
            compression = compression,
            key = key,
        }
        local exe = files[current_output]

        if not fs.write_bin(current_output, exe) then
            print_error("Can not create "..current_output)
        end

        fs.chmod(current_output, fs.aX|fs.aR|fs.uW)

        print_size(current_output)
    end

    local function uncompressed_name(name)
        local uncompressed, ext = name:splitext()
        return F.case(ext) {
            [".lz"]  = function() return uncompressed, lzip.unlzip end,
            [F.Nil]  = function() return name, F.id end,
        }()
    end

    local function assert_sh(ok, _, code)
        assert(ok and code==0)
    end

    -- Compile LuaX scripts with LuaX and Zig, gcc or clang
    local function compile_native(tmp, current_output, target_definition)
        if current_output:ext():lower() ~= target_definition.exe then
            current_output = current_output..target_definition.exe
        end
        if not quiet then print() end
        log("target", "%s", target_definition.name)
        log("output", "%s", current_output)

        -- Extract precompiled LuaX libraries
        local headers = F(assets.headers or {})
        local libs = F(assets.targets and assets.targets[target_definition.name] or {})
        if headers:null() or libs:null() then
            print_error("Compilation not available")
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
            compression = compression,
            key = key,
        })
        app_bundle : foreachk(fs.write_bin)

        local tmp_output = tmp/current_output:basename()

        local function optional(flag)
            return flag and F.id or F.const{}
        end

        local flto = F.case(build_config.compiler.name) {
            zig   = "-flto=thin",
            gcc   = "-flto=auto",
            clang = "-flto=thin",
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
                clang = {},
                zig   = {},
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
            local zig_key = build_config.zig.key;

            local zig = zig_path/"zig"..sys.exe

            -- Install Zig (to cross compile and link C sources)
            if not zig:is_file() then
                local term = require "term"
                log("Zig", "download and install Zig to %s", zig_path)
                local curl = require "curl"
                local ext = F.case(sys.os) { windows=".zip", [F.Nil]=".tar.xz" }
                local archive
                local mirrors = curl "https://ziglang.org/download/community-mirrors.txt" : lines() : shuffle()
                for _, mirror in ipairs(mirrors) do
                    local url = string.format("%s/zig-%s-%s-%s%s", mirror, sys.arch, sys.os, zig_version, ext)
                    local source = "?source=luax-zig-setup"
                    log("Zig", "try mirror %s", mirror)
                    archive = url:basename()
                    local curl_ok = curl.request {
                        "-fSL",
                        (quiet or not term.isatty(io.stdout)) and "-s" or "-#",
                        url..source,
                        "-o", tmp/archive,
                    }
                    if curl_ok then
                        assert(curl.request {
                            "-fSL",
                            (quiet or not term.isatty(io.stdout)) and "-s" or "-#",
                            url..".minisig"..source,
                            "-o", tmp/archive..".minisig",
                        })
                        local minisign_ok, _, minisign_code  = sh.run { "minisign", "-V", "-m", tmp/archive, "-x", tmp/archive..".minisig", "-P", zig_key }
                        if not minisign_ok        then archive = nil -- minisign not installed ?
                        elseif minisign_code ~= 0 then archive = nil -- bad signature
                        end
                        break
                    end
                    archive = nil -- archive not found, try another mirror
                end
                if archive then
                    fs.mkdirs(zig_path)
                    assert_sh(sh.run("tar -xJf", tmp/archive, "-C", zig_path, "--strip-components", 1))
                end
                if not zig:is_file() then
                    print_error("Unable to install Zig to %s", zig_path)
                end
            end

            compiler = zig

        end

        -- Compile and link the generated source
        assert_sh(sh.run(compiler, cflags, libnames, tmp/app_bundle_c, ldflags, "-o", tmp_output))

        assert(fs.copy(tmp_output, current_output))

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

        -- Extract precompiled LuaX loader
        local loader = assets.loaders and assets.loaders[target_definition.name]
        if not loader then
            print_error("No "..target_definition.name.." loader")
        end

        -- Compile the input LuaX scripts
        local files = assert(bundle.bundle {
            scripts = scripts,
            output = current_output,
            target = "luax-loader",
            add_shebang = false,
            bytecode = bytecode or "-b",
            strip = strip,
            compression = compression,
            key = key,
        })

        loader = F(loader) : mapk2a(function(k, bin)
            local _, uncompress = uncompressed_name(k)
            return uncompress(bin)
        end)
        if #loader ~= 1 then
            print_error("Invalid "..target_definition.name.." loader")
        end

        local header = string.pack("<c4I4", magic, #files[current_output])
        local payload = F.str {
            files[current_output],
            header,
            header:hash32():unhex(),
        }

        local exe = loader[1] .. payload

        if not fs.write_bin(current_output, exe) then
            print_error("Can not create "..current_output)
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
            print_error(target..": unknown target")
        end

        if use_cc then
            fs.with_tmpdir(function(tmp)
                compile_native(tmp, output, target_definition)
            end)
        else
            compile_loader(output, target_definition)
        end

    end

end

-------------------------------------------------------------------------------
-- Env command
-------------------------------------------------------------------------------

local function find_exe(name)

    local fs = require "fs"
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

local function cmd_env()

    local fs = require "fs"
    local sys = require "sys"

    local function luax_env(luax)

        local exe = find_exe(luax)
        local bin = assert(exe):dirname():realpath()
        local prefix = bin:dirname()
        local lib_lua = prefix / "lib" / "?.lua"
        local lib_so = prefix / "lib" / "?"..sys.so

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
            update(package.cpath, "LUA_CPATH", lua_path_sep, lib_so),
        }
    end

    local function user_env(scripts)
        local import = require "import"
        local script = {}
        local function dump(t, p)
            if type(t) == "table" then
                F.foreachk(t, function(k, v)
                    dump(v, (p and p.."_" or "")..k)
                end)
            else
                local s = tostring(t)
                    : gsub("\n", "\\n")
                    : gsub("\'", "\\'")
                p = p : gsub("[^%w]", "_")
                script[#script+1] = F{"export ", p:upper(), "='", s, "';"}:str()
            end
        end
        F.foreach(scripts, F.compose{dump, import})
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

    local fs = require "fs"
    local sys = require "sys"
    local term = require "term"
    local linenoise = require "linenoise"

    local expected_files = F.flatten {
        (sys.libc=="gnu" or sys.libc=="musl") and "bin"/"luax"..sys.exe or {},
        "bin"/"luax.lua",
        "bin"/"luax-pandoc.lua",
        sys.libc=="gnu" and "lib"/"libluax"..sys.so or {},
        "lib"/"libluax.lar",
        "lib"/"libluax.lua",
    }

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

    local exe = find_exe(arg[0])
    local prefix = assert(exe):dirname():dirname():realpath()
    local bin = prefix/"bin"
    local lib = prefix/"lib"
    local new_files = expected_files : map(function(file) return prefix/file end)

    print(_LUAX_COPYRIGHT)
    print(("="):rep(#_LUAX_COPYRIGHT))

    local found = term.color.green "✔"
    local not_found = term.color.red "✖"
    local recycle = term.color.yellow "♻"

    local function confirm(msg, ...)
        local prompt = string.format(msg, ...).."? [y/N]"
        local ans = nil
        repeat
            ans = linenoise.read(prompt) : trim() : lower()
        until ans:match "^[yn]?$"
        return ans == "y"
    end

    -- Search for installed files

    print("")
    local all_found = true
    new_files : foreach(function(file)
        local exists = fs.is_file(file)
        print((exists and found or not_found).." "..file)
        all_found = all_found and exists
    end)

    if not all_found then print_error("Some files are missing") end

    -- Search for obsolete files

    local obsolete_files = (fs.ls(bin) .. fs.ls(lib))
        : filter(function(file) return file:basename():match "luax" end)
        : filter(function(file) return new_files:not_elem(file) end)

    if #obsolete_files > 0 then
        print("")
        obsolete_files : foreach(function(file)
            if force then
                print(string.format("%s remove %s", recycle, file))
                assert(fs.remove(file))
            elseif interactive then
                if confirm("%s remove obsolete LuaX file '%s'", recycle, file) then
                    assert(fs.remove(file))
                end
            else
                print(string.format("%s %s is obsolete", recycle, file))
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
