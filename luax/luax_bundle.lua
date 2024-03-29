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

-- bundle a set of scripts into a single Lua script that can be added to the runtime

local bundle = {}

local F = require "F"
local fs = require "fs"
require "lz4"
require "crypt"
local config = require "luax_config"

local char = string.char

local function read(name)
    if not name:is_file() then
        io.stderr:write("error: ", name, ": File not found\n")
        os.exit(1)
    end
    return fs.read(name)
end

local function Bundle()
    local self = {}
    local fragments = F{}
    function self.emit(s) fragments[#fragments+1] = s end
    function self.get() return fragments:str() end
    return self
end

local function last_line(s)
    return s
    : lines()
    : drop_while_end(F.compose{string.null, string.trim})
    : last() or ""
end

local function mlstr(code)
    local n = (code:matches"](=*)]":map(F.op.len):maximum() or 0) + 1
    local eqs = ("="):rep(n)
    return F.str{"[", eqs, "[", code, "]", eqs, "]"}
end

local function qstr(code)
    return string.format("%q", code)
end

local function path_shortener(path_list)

    local function strip_common_path(ps)
        if #ps == 0 then return {} end
        local split = F.map(function(p) return p:split(fs.sep) end, ps)
        local function join()
            return split:map(fs.join)
        end
        while true do
            local common = nil
            for i = 1, #split do
                if #split[i] <= 1 then return join() end
                if common == nil then
                    common = split[i][1]
                else
                    if split[i][1] ~= common then return join() end
                end
            end
            split = split:map(F.partial(F.drop, 1))
        end
    end

    local function external(p)
        -- remove full path from sources generated in local cache or build directories
        return p:has_prefix "~/." or p:has_prefix "." or p:has_prefix(fs.sep)
    end

    local exts, ints = path_list:partition(external)

    return
        (  F{ints, strip_common_path(ints)}:zip()
        .. F{exts, exts:map(fs.basename)}:zip()
        ) : from_list()
end

local function chunks_of(n, xs)
    local chunks = F{}
    local i = 1
    while i <= #xs do
        local chunk = F{}
        for j = 1, n do
            chunk[j] = xs[i]
            i = i+1
        end
        chunks[#chunks+1] = chunk
    end
    return chunks
end

local function invert(s)
    return s:bytes():map(function(b) return char(b~0xff) end):str()
end

function bundle.bundle(arg, opts)

    local kind = "app"
    local format = nil
    local scripts = F{}
    local explicit_main = false
    local product_name = assert(opts.name, "Missing output name")
    local bytecode = F{ compile = false, strip = false }
    arg = F.map(function(a)
        local fname = a:match"^@(.+)"
        if not fname then return a end
        return read(fname):words()
    end, arg) : flatten()
    for i = 1, #arg do
        if arg[i]:match"^%-name=" then product_name = arg[i]:match"=(.*)"
        elseif arg[i] == "-lib" then kind = "lib"
        elseif arg[i] == "-app" then kind = "app"
        elseif arg[i] == "-lua" then format = "lua"
        elseif arg[i] == "-c"   then format = "c"
        elseif arg[i] == "-b"   then bytecode = bytecode:patch { compile=true }
        elseif arg[i] == "-s"   then bytecode = bytecode:patch { compile=true, strip=true }
        elseif arg[i]:match"^%-" then io.stderr:write("error: ", arg[i], ": invalid argument\n"); os.exit(1)
        elseif arg[i]:ext() == ".lua" then
            local content = bundle.comment_shebang(read(arg[i]))
            local new_name = content:match("@".."LIB=([%w%._%-]+)")
            local name = new_name or arg[i]:basename():splitext()
            local main = content:match("@".."MAIN")
            local load = content:match("@".."LOAD")
            local new_load_name = content:match("@".."LOAD=([%w%._%-]+)")
            local load_name = new_load_name or name
            local lib = new_name or load or content:match("@".."LIB")
            local maybe_main =
                    not lib
                and not load
                and not main
                and not last_line(content):match "^%s*return"
            scripts[#scripts+1] = {
                path = arg[i],
                name = name,
                main = main,
                lib = lib,
                load = load,
                load_name = load_name,
                maybe_main = maybe_main,
                content = content,
            }
            explicit_main = explicit_main or main
        else
            -- file embeded as a Lua module returning the content of the file
            local name = arg[i]:basename()
            local content = read(arg[i])
            if content:match "^[%g%s]*$" then
                content = ("return %s"):format(mlstr(content))
            else
                content = ("return require'crypt'.unbase64 %s"):format(mlstr(content:base64()))
            end
            scripts[#scripts+1] = {
                path = arg[i],
                name = name,
                main = false,
                lib = true,
                load = false,
                load_name = name,
                maybe_main = false,
                content = content,
            }
        end
    end

    product_name = product_name : basename() : splitext()

    local shortener = path_shortener(scripts:map(F.partial(F.nth, "path")))
    for i = 1, #scripts do
        scripts[i].short_path = shortener[scripts[i].path]
    end

    local main_scripts = {}
    if explicit_main then
        -- If there are explicit main scripts, only keep them
        for i = 1, #scripts do
            if scripts[i].main then
                main_scripts[#main_scripts+1] = scripts[i].path
            end
            scripts[i].maybe_main = false
        end
    else
        -- No explicit main, count other plausible main scripts
        for i = 1, #scripts do
            if scripts[i].maybe_main then
                scripts[i].main = true
                main_scripts[#main_scripts+1] = scripts[i].path
            end
        end
    end
    if kind == "lib" then
        -- libraries shall not contain main scripts
        if #main_scripts > 0 then
            error "The LuaX runtime shall not contain main scripts"
        end
    else
        -- real LuaX applications shall contain one and only one main script
        if #main_scripts > 1 then
            error("Too many main scripts:\n"..table.concat(main_scripts, "\n"))
        elseif #main_scripts == 0 then
            error "No main script"
        end
    end

    local home = os.getenv"HOME"

    local function home_path(name)
        if name:has_prefix(home) then
            return "~"..name:sub(#home+1)
        end
        return name
    end

    local plain = Bundle()
    if kind == "lib" and format == "lua" and config.version then
        plain.emit("--@LOAD=_: load luax to expose LuaX modules\n")
        plain.emit("_LUAX_VERSION = '"..config.version.."'\n");
        plain.emit("_LUAX_DATE = '"..config.date.."'\n");
    end
    if bytecode.strip then
        plain.emit("local function lib(src) return assert(load(src)) end\n")
    else
        plain.emit(("local function lib(path, src) return assert(load(src, '@$%s:'..path)) end\n"):format(product_name))
    end
    local function compile(script)
        -- check script compilation (with the actual file path in error messages)
        assert(load(script.content, ("@%s"):format(script.path)))
        if bytecode.compile then
            -- compile the script with file path containing the product name
            local chunk = assert(load(script.content, ("@$%s:%s"):format(product_name, script.path)))
            return qstr(string.dump(chunk, bytecode.strip))
        else
            return mlstr(script.content)
        end
    end
    local function compile_library(script)
        if bytecode.strip then
            plain.emit(("[%q] = lib(%s),\n"):format(script.name, compile(script)))
        else
            plain.emit(("[%q] = lib(%q, %s),\n"):format(script.name, home_path(script.short_path), compile(script)))
        end
    end
    local function load_library(script)
        if script.load_name == "_" then
            plain.emit(("require %q\n"):format(script.name))
        else
            plain.emit(("_ENV[%q] = require %q\n"):format(script.load_name, script.name))
        end
    end
    local function run_script(script)
        if bytecode.strip then
            plain.emit(("return lib(%s)()\n"):format(compile(script)))
        else
            plain.emit(("return lib(%q, %s)()\n"):format(home_path(script.short_path), compile(script)))
        end
    end
    if #scripts > 1 then -- there are libs
        plain.emit "local libs = {\n"
        for i = 1, #scripts do
            -- add non main scripts to the libs table used by the require function
            if not scripts[i].main then
                compile_library(scripts[i])
            end
        end
        plain.emit "}\n"
        plain.emit "table.insert(package.searchers, 2, function(name) return libs[name] end)\n"
    end
    for i = 1, #scripts do
        if scripts[i].load then
            -- load packages are require'd and stored in a global variable
            load_library(scripts[i])
        end
    end
    for i = 1, #scripts do
        if scripts[i].main then
            -- finally the main script is executed
            run_script(scripts[i])
        end
    end

    local plain_payload = plain.get()

    if bytecode.compile then
        plain_payload = string.dump(assert(load(plain_payload, product_name)), true)
    end

    if format == "lua" then
        return plain_payload
    end

    local payload = invert(plain_payload:lz4())

    if format == "c" then
        return ([[
#include <stdlib.h>
extern const size_t %s_bundle_len;
extern const unsigned char %s_bundle[];
const size_t %s_bundle_len = %d;
const unsigned char %s_bundle[] = {
%s};
]]):format(kind, kind, kind, #payload, kind,
    chunks_of(16, payload:bytes()):map(function(g) return "    "..g:str",".."," end):unlines()
)
    end

    error(format..": invalid format")

end

function bundle.comment_shebang(script)
    return script : gsub("^#!", "--") -- comment the shebang before loading the script
end

function bundle.combine_lua(name, scripts)
    return bundle.bundle(F.flatten{scripts}, {name=name})
end

local function called_by(f, level)
    level = level or 1
    local caller = debug.getinfo(level, "f")
    if caller == nil then return false end
    if caller.func == f then return true end
    return called_by(f, level+1)
end

if called_by(require) then return bundle end

io.stdout:write(bundle.bundle(arg, {name="luax"}))
