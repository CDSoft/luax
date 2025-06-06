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
https://codeberg.org/cdsoft/luax
--]]

-- bundle a set of scripts into a single Lua script that can be added to the runtime

local M = {}

local F = require "F"
local fs = require "fs"
local crypt = require "crypt"
local lar = require "lar"

local format = string.format
local byte = string.byte
local char = string.char
local sub = string.sub

local unpack = table.unpack

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

function M.comment_shebang(script)
    return script
        : gsub("^#!.-\n(\x1b)", "%1")   -- remove the whole shebang of compiled scripts
        : gsub("^#!", "--")             -- comment the shebang before loading the script
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

local function chunks_of(n, xs)
    local chunks = F{}
    for i = 1, #xs, n do
        chunks[#chunks+1] = F{unpack(xs, i, i+n-1)}
    end
    return chunks
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

local function bytes(s)
    local N <const> = 512*1024
    if #s <= N then return s:bytes() end
    local bs = {}
    for i = 1, #s, N do
        bs[#bs+1] = {byte(s, i, i+N-1)}
    end
    return F.concat(bs)
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

local function compress(code, opt)
    if not opt.compression and not opt.key then return code, "" end
    local compressed_code = code:lzip(0) -- level 0 to reduce the memory usage at decompression
    if #compressed_code > 0.75 * #code then return code, "" end
    return compressed_code, ":unlzip()"
end

local function obfuscate_luax(code, opt, names)

    code = bytecode(code, opt, names)

    local uncompress
    code, uncompress = compress(code, opt)

    if opt.key then
        local key = make_key(code, opt)
        code = compact(F.I { b=escape(code:arc4(key)), k=escape(key), uncompress=uncompress } [===[
            return load(($(b)):unarc4$(k)$(uncompress))()
        ]===])
        code = bytecode(code, opt, F.take(1, names))
    elseif opt.compression then
        code = compact(F.I { b=escape(code), uncompress=uncompress } [===[
            return load(($(b))$(uncompress))()
        ]===])
        code = bytecode(code, opt, F.take(1, names))
    end

    return code
end

local known_modules = {}

local runtime_modules = setmetatable({}, {
    __index = function(self, k)
        local assets = require "luax_assets"
        local luax = assets.lua_runtime and lar.unlar(assets.lua_runtime["luax.lar"]) or {}
        for i = 1, #luax do
            local script = luax[i]
            self[script.lib_name] = true
        end
        return rawget(self, k)
    end,
})

local function ensure_unique_module(opt, script)
    local name = script.lib_name
    if opt.entry ~= "lib" and not script.dont_check_runtime_unicity then
        if runtime_modules[name] then
            error(name..": duplicate module (already defined in the LuaX runtime)")
        end
    end
    if known_modules[name] then
        error(name..": duplicate module")
    end
    known_modules[name] = true
end

function M.bundle(opt)

    opt.bytecode = opt.bytecode or opt.strip -- strip implies bytecode

    local scripts = F{}

    if opt.add_luax_runtime then
        local assets = require "luax_assets"
        local runtime = assets.lua_runtime and assets.lua_runtime["luax.lar"]
        if not runtime then assets.error() end
        runtime = lar.unlar(runtime)
        for i = 1, #runtime do
            -- runtime script => ensure_unique_module shall not check it is not part of the runtime!
            runtime[i].dont_check_runtime_unicity = true
            scripts[#scripts+1] = runtime[i]
        end
    end

    F.foreach(opt.scripts, function(script)
        local content = assert(fs.read_bin(script))
        local ext = fs.ext(script)
        if ext == ".lua" then
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
        local lar_opt = {
            compress = opt.compress or "lzip",
            key = opt.key,
        }
        return F{
            [opt.output] = lar.lar(scripts, lar_opt),
        }
    end

    if opt.target:match "^lua" or opt.target == "pandoc" then
        local product_name = opt.product_name or opt.output:basename():splitext()
        local preloads = {}
        local loads = {}
        local run_main = {}
        local config = require "luax_config"
        local interpreter = {
            lua    = "lua",
            pandoc = "pandoc lua",
            luax   = "luax",
            ["luax-loader"] = nil, -- no shebang in the appended payload
        }
        local shebang = interpreter[opt.target] and "#!/usr/bin/env -S "..interpreter[opt.target].." --" or {}
        local out = F{
            opt.target:match "^luax" and {} or {
                "_LUAX_VERSION   = '"..config.version.."'",
                "_LUAX_DATE      = '"..config.date.."'",
                "_LUAX_COPYRIGHT = '"..config.copyright.."'",
            },
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
                return qstr(bytecode(script.content, opt, {product_name, script.path}))
            else
                return mlstr(script.content)
            end
        end
        local main_script, libs = find_main(scripts)
        for i = 1, #libs do
            local script = libs[i]
            local name = script.lib_name
            ensure_unique_module(opt, script)
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
        local obfuscate = opt.target:match "^luax" and obfuscate_luax or obfuscate_lua
        out = obfuscate(out:flatten():unlines(), F(opt):patch{strip=true}, {product_name})
        return F{
            [opt.output] = F{shebang, out}:flatten():unlines(),
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
            return obfuscate_luax(script.content, opt, {product_name, script.path})
        end
        local function stripped(prefix, name)
            return prefix .. (opt.strip and "" or ":"..name)
        end
        local main_script, libs = find_main(scripts)
        for i = 1, #libs do
            local script = libs[i]
            local name = script.lib_name
            ensure_unique_module(opt, script)
            local func_name = name : gsub("[^%w]", "_")
            local code = bytes(compile(script))
            mods[#mods+1] = {
                "static int luaopen_"..func_name.."(lua_State *L) {",
                "  static const unsigned char code[] = {",
                chunks_of(16, code) : map(function(g) return "    "..g:str",".."," end),
                "  };",
                "  const int arg = lua_gettop(L);",
                "  if (luaL_loadbuffer(L, (const char*)code, sizeof(code), \"@$"..stripped(product_name, script.path).."\") != LUA_OK) {",
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
            local code = bytes(compile(script))
            traceback[1] = {
                "static int traceback(lua_State *L)",
                "{",
                "  const char *msg = lua_tostring(L, 1);",
                "  if (msg == NULL) {",
                "    if (luaL_callmeta(L, 1, \"__tostring\") && lua_type(L, -1) == LUA_TSTRING) {",
                "      msg = lua_tostring(L, -1);",
                "    } else {",
                "      msg = lua_pushfstring(L, \"(error object is a %s value)\", luaL_typename(L, 1));",
                "    }",
                "  }",
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
                "  if (luaL_loadbuffer(L, (const char*)code, sizeof(code), \"@$"..stripped(product_name, script.path).."\") != LUA_OK) {",
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

return M
