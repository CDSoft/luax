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

bundle.magic = string.unpack("<I4", "LuaX")

local header_format = "<I4I4"

local function read(name)
    local f = io.open(name)
    if f == nil then
        io.stderr:write("error: ", name, ": File not found\n")
        os.exit(1)
    end
    assert(f)
    local content = f:read "a"
    f:close()
    return content
end

local function Bundle()
    local self = {}
    local fragments = {}
    function self.emit(s) fragments[#fragments+1] = s end
    function self.get() return table.concat(fragments) end
    return self
end

local function basename(path)
    return path:gsub(".-([^/\\]+)$", "%1")
end

local function strip_ext(path)
    return path:gsub("%.lua$", "")
end

function bundle.bundle(arg)

    local format = "binary"
    local main = true
    local scripts = {}
    local autoload_next = false
    local autoexec_next = false
    local autoload_all = false
    local autoexec_all = false
    for i = 1, #arg do
        if arg[i] == "-nomain" then             main = false
        elseif arg[i] == "-ascii" then          format = "ascii"
        elseif arg[i] == "-autoload" then       autoload_next = true
        elseif arg[i] == "-autoload-all" then   autoload_all = true
        elseif arg[i] == "-autoload-none" then  autoload_none = false
        elseif arg[i] == "-autoexec" then       autoexec_next = true
        elseif arg[i] == "-autoexec-all" then   autoexec_all = true
        elseif arg[i] == "-autoexec-none" then  autoexec_none = false
        else
            local local_path, dest_path = arg[i]:match "(.-):(.*)"
            local_path = local_path or arg[i]
            scripts[#scripts+1] = {
                local_path = local_path,
                path = dest_path or basename(local_path),
                name = dest_path and strip_ext(dest_path) or basename(strip_ext(local_path)),
                autoload = autoload_next or autoload_all,
                autoexec = autoexec_next or autoexec_all,
            }
            autoload_next = false
            autoexec_next = false
        end
    end

    local plain = Bundle()
    plain.emit "do\n"
    local function compile_library(script)
        local script_source = read(script.local_path):gsub("^#![^\n]*", "")
        assert(load(script_source, script.local_path, 't'))
        plain.emit(("[%q] = assert(load(%q, %q, 't')),\n"):format(script.name, script_source, "@"..script.path))
    end
    local function load_library(script)
        plain.emit(("_ENV[%q] = require %q\n"):format(script.name, script.name))
    end
    local function run_script(script)
        local script_source = read(script.local_path):gsub("^#![^\n]*", "")
        assert(load(script_source, script.local_path, 't'))
        plain.emit(("assert(load(%q, %q, 't'))()\n"):format(script_source, "@"..script.path))
    end
    plain.emit "local libs = {\n"
    for i = main and 2 or 1, #scripts do
        -- add non autoexec scripts to the libs table used by the require function
        if not scripts[i].autoexec then
            compile_library(scripts[i])
        end
    end
    plain.emit "}\n"
    plain.emit "table.insert(package.searchers, 1, function(name) return libs[name] end)\n"
    for i = main and 2 or 1, #scripts do
        if scripts[i].autoload then
            -- autoload packages are require'd and stored in a global variable
            load_library(scripts[i])
        elseif scripts[i].autoexec then
            -- autoexec scripts are executed before main and can not be require'd
            run_script(scripts[i])
        end
    end
    if main then
        -- finally the main script is executed
        run_script(scripts[1])
    end
    plain.emit "end\n"

    local payload = require"lz4".lz4(plain.get())

    if format == "binary" then
        payload = require"crypt".aes(payload)
        local chunk = Bundle()
        local header = header_format:pack(#payload, bundle.magic)
        chunk.emit(payload)
        chunk.emit(header)
        return chunk.get()
    end

    if format == "ascii" then
        payload = require"crypt".rc4(payload)
        local hex = Bundle()
        local _ = payload:gsub(".", function(c)
            hex.emit(("'\\x%02X',"):format(c:byte()))
        end)
        hex.emit "\n"
        return hex:get()
    end

end

local function drop_chunk(exe)
    local header_size = header_format:packsize()
    local size, magic = header_format:unpack(exe, #exe - header_size + 1)
    if magic ~= bundle.magic then
        io.stderr:write("error: no LuaX header found in the current target\n")
        os.exit(1)
    end
    return exe:sub(1, #exe - header_size - size + 1)
end

function bundle.combine(target, scripts)
    local runtime = drop_chunk(read(target))
    local chunk = bundle.bundle(scripts)
    return runtime..chunk, chunk
end

local function called_by(f)
    for level = 2, 10 do
        local caller = debug.getinfo(level, "f")
        if caller == nil then return false end
        if caller.func == f then return true end
    end
end

if called_by(require) then return bundle end

io.stdout:write(bundle.bundle(arg))
