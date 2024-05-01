#!/usr/bin/env luax
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

local M = {}

local F = require "F"
local fs = require "fs"

local format = string.format

local function parse_args(args)
    local parser = require "argparse"()
        : name "bundle"
    parser : argument "script"
        : description "Lua script"
        : args "+"
        : target "scripts"
    parser : option "-o"
        : description "Output file"
        : argname "output"
        : target "output"
    parser : option "-t"
        : description "Target"
        : argname "target"
        : target "target"
        : choices { "lib", "luax", "lua", "pandoc", "c" }
    parser : option "-e"
        : description "Entry type"
        : argname "entry"
        : target "entry"
        : choices { "lib", "app" }
    parser : option "-n"
        : description "Product name"
        : argname "product_name"
        : target "product_name"
    parser : flag "-b"
        : description "Compile scripts to Lua bytecode"
        : target "bytecode"
    parser : flag "-s"
        : description "Strip debug information"
        : target "strip"
    return F{
        scripts = nil,              -- Lua script list
        output = nil,               -- output file
        target = "luax",            -- lib, lua, luax, c
        entry = "app",              -- lib, app
        bytecode = nil,             -- compile to Lua bytecode
        strip = nil,                -- strip Lua bytecode
    } : patch(parser:parse(args))
end

local function main(args)
    M.bundle(parse_args(args)) : foreachk(fs.write)
end

local function last_line(s)
    return s
    : lines()
    : drop_while_end(F.compose{string.null, string.trim})
    : last() or ""
end

local function to_bool(x)
    if x then return true end
end

local function to_string(x)
    if x then return x end
end

local function mlstr(s)
    local n = (s:matches"](=*)]":map(F.op.len):maximum() or -1) + 1
    local eqs = ("="):rep(n)
    return F.str{"[", eqs, "[", s, "]", eqs, "]"}
end

local function qstr(s)
    if s:match "^[%g%s]*$" then
        -- printable string => use multiline Lua strings
        return mlstr(s)
    else
        -- non printable string => escape non printable chars
        return format("'%s'", s:bytes():map(function(b) return format("\\%d", b) end):str())
    end
end

function M.comment_shebang(script)
    return script
        : gsub("^#!.-\n(\x1b)", "%1")   -- remove the whole shebang of compiled scripts
        : gsub("^#!", "--")             -- comment the shebang before loading the script
end

local function find_main(scripts)
    local explicit_main = {}
    local implicit_main = {}
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
        error("Too many main scripts: "..F.str(explicit_main, ", "))
    elseif #explicit_main == 1 then
        main_script = explicit_main[1]
    elseif #implicit_main > 1 then
        error("Too many main scripts: "..F.str(implicit_main, ", "))
    elseif #implicit_main == 1 then
        main_script = implicit_main[1]
    end
    return main_script, scripts:filter(function(script) return script ~= main_script end)
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

function M.bundle(opt)

    local cbor = require "cbor"

    opt.bytecode = opt.bytecode or opt.strip -- strip implies bytecode

    local scripts = F{}

    F.foreach(opt.scripts, function(script)
        local content = assert(fs.read(script))
        local ext = fs.ext(script)
        if ext == ".lib" then
            local lib_scripts = assert(cbor.decode(content))
            for i = 1, #lib_scripts do
                scripts[#scripts+1] = lib_scripts[i]
            end
        elseif ext == ".lua" then
            scripts[#scripts+1] = {
                path      = script,
                content   = M.comment_shebang(content),
                is_main   = to_bool(content:match("@".."MAIN")),
                is_lib    = to_bool(content:match("@".."LIB")),
                lib_name  = to_string(content:match("@".."LIB=([%w%._%-]+)")) or script:basename():splitext(),
                is_load   = to_bool(content:match("@".."LOAD")),
                load_name = to_string(content:match("@".."LOAD=([%w%._%-]+)")),
                maybe_lib = to_bool(last_line(content):match "^%s*return"),
            }
        else
            -- file embeded as a Lua module returning the content of the file
            if content:match"^[%g%s]*$" and #content:lines() <= 1 then content = content:trim() end
            local safe_content = qstr(content)
            scripts[#scripts+1] = {
                path      = script,
                content   = "return "..safe_content,
                is_main   = nil,
                is_lib    = true,
                lib_name  = script:basename(),
                is_load   = nil,
                load_name = nil,
                maybe_lib = nil,
            }
        end
    end)

    if not opt.output then
        return F{}
    end

    if opt.target == "lib" then
        return F{
            [opt.output] = cbor.encode(scripts, {pairs=F.pairs}),
        }
    end

    if opt.target == "lua" or opt.target == "pandoc" or opt.target == "luax" then
        local product_name = opt.product_name or opt.output:basename():splitext()
        local preloads = {}
        local loads = {}
        local run_main = {}
        local config = require "luax_config"
        local interpreter = {
            lua    = "lua",
            pandoc = "pandoc lua",
            luax   = "luax",
        }
        local out = F{
            "#!/usr/bin/env -S "..interpreter[opt.target].." --",
            interpreter[opt.target] ~= "luax" and {
                "_LUAX_VERSION = '"..config.version.."'",
                "_LUAX_DATE    = '"..config.date.."'",
            } or {},
            "local libs = {}",
            "table.insert(package.searchers, 2, function(name) return libs[name] end)",
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
                local chunk = assert(load(script.content, ("@$%s:%s"):format(product_name, script.path)))
                return qstr(string.dump(chunk, opt.strip))
            else
                return mlstr(script.content)
            end
        end
        local main_script, libs = find_main(scripts)
        for i = 1, #libs do
            local script = libs[i]
            local name = script.lib_name
            if opt.strip then
                preloads[#preloads+1] = ("libs[%q] = lib(%s)"):format(name, compile(script))
            else
                preloads[#preloads+1] = ("libs[%q] = lib(%q, %s)"):format(name, script.path, compile(script))
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
        if opt.bytecode then
            out = F{
                out:head(),
                assert(string.dump(assert(load(out:drop(1):flatten():unlines(), "@$"..product_name)), opt.strip)),
            }
        end
        return F{
            [opt.output] = out:flatten():unlines(),
        }
    end

    if opt.target == "c" then
        local product_name = opt.product_name or opt.output:basename():splitext()
        local mods = F{}        -- luaopen_xxx functions
        local preloads = F{}    -- _PRELOAD population
        local loads = F{}       -- modules preloaded to global variables
        local traceback = F{}
        local run_main = F{}    -- main script
        local out = F{
            '#include "lua.h"',
            '#include "lauxlib.h"',
            '#include "stdlib.h"',
            "int run_"..opt.entry.."(lua_State *L);",
            mods,
            traceback,
            "int run_"..opt.entry.."(lua_State *L) {",
            "  luaL_getsubtable(L, LUA_REGISTRYINDEX, \"_PRELOAD\");",
            preloads,
            "  lua_pop(L, 1);",
            loads,
            run_main,
            "}",
        }
        local function compile(script)
            -- check script compilation (with the actual file path in error messages)
            assert(load(script.content, ("@%s"):format(script.path)))
            if opt.bytecode then
                -- compile the script with file path containing the product name
                local chunk = assert(load(script.content, ("@$%s:%s"):format(product_name, script.path)))
                return string.dump(chunk, opt.strip)
            else
                return script.content
            end
        end
        local main_script, libs = find_main(scripts)
        for i = 1, #libs do
            local script = libs[i]
            local name = script.lib_name
            local func_name = name : gsub("[^%w]", "_")
            local code = compile(script) : bytes()
            mods[#mods+1] = {
                "static int luaopen_"..func_name.."(lua_State *L) {",
                "  static const unsigned char code[] = {",
                chunks_of(16, code) : map(function(g) return "    "..g:str",".."," end),
                "  };",
                "  const int arg = lua_gettop(L);",
                "  if (luaL_loadbuffer(L, (const char*)code, sizeof(code), \"@$"..product_name..":"..script.path.."\") != LUA_OK) {",
                "    fprintf(stderr, \"%s\\n\", lua_tostring(L, -1));",
                "    exit(EXIT_FAILURE);",
                "  }",
                "  lua_insert(L, 1);",
                "  lua_call(L, arg, 1);",
                "  return 1;",
                "}",
            }
            preloads[#preloads+1] = {
                "  lua_pushcfunction(L, luaopen_"..func_name.."); lua_setfield(L, -2, \""..name.."\");",
            }
        end
        for i = 1, #libs do
            local script = libs[i]
            if script.is_load then
                local lib_name  = script.lib_name
                local load_name = script.load_name or lib_name
                loads[#loads+1] = {
                    script.load_name == "_"
                        and "  lua_getglobal(L, \"require\"); lua_pushstring(L, \""..lib_name.."\"); lua_call(L, 1, 0);"
                        or  "  lua_getglobal(L, \"require\"); lua_pushstring(L, \""..lib_name.."\"); lua_call(L, 1, 1); lua_setglobal(L, \""..load_name.."\");"
                }
            end
        end
        if main_script then
            local script = main_script
            local code = compile(script) : bytes()
            traceback[1] = {
                "static int traceback(lua_State *L)",
                "{",
                "  const char *msg = lua_tostring(L, 1);",
                "  luaL_traceback(L, L, msg, 1);",
                "  const char *tb = lua_tostring(L, -1);",
                "  fprintf(stderr, \"%s\\n\", tb!=NULL ? tb : msg);",
                "  lua_pop(L, 1);",
                "  return 0;",
                "}",
            }
            run_main[#run_main+1] = {
                "  static const unsigned char code[] = {",
                chunks_of(16, code) : map(function(g) return "    "..g:str",".."," end),
                "  };",
                "  if (luaL_loadbuffer(L, (const char*)code, sizeof(code), \"@$"..product_name..":"..script.path.."\") != LUA_OK) {",
                "    fprintf(stderr, \"%s\\n\", lua_tostring(L, -1));",
                "    exit(EXIT_FAILURE);",
                "  }",
                "  const int base = lua_gettop(L);",
                "  lua_pushcfunction(L, traceback);",
                "  lua_insert(L, base);",
                "  const int status = lua_pcall(L, 0, 0, base);",
                "  lua_remove(L, base);",
                "  return status;",
            }
        else
            run_main[#run_main+1] = {
                "  return LUA_OK;",
            }
        end

        return F{
            [opt.output] = out:flatten():unlines(),
        }
    end

    error(tostring(opt.target)..": unknown target")
end

local function called_by(f, level)
    level = level or 1
    local caller = debug.getinfo(level, "f")
    if caller == nil then return false end
    if caller.func == f then return true end
    return called_by(f, level+1)
end

if called_by(require) then return M end
main(arg)
