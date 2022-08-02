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

-- WARNING: bundle.lua is used to create the first Luax executable
-- and is executed by a standard Lua interpretor.
-- It can not use Luax packages such as fun or fs.

local bundle = {}

bundle.magic = string.unpack("<I8", "LuaX/CD!")

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

local function package_name(path)
    return basename(path):gsub("%.lua$", "")
end

function bundle.bundle(arg)

    local format = "b"
    local scripts = {}
    local autoload = {}
    local autoload_next = false
    for i = 1, #arg do
        if arg[i] == "-c" then
            format = "c"
        elseif arg[i] == "-l" then
            autoload_next = true
        else
            scripts[#scripts+1] = arg[i]
            if autoload_next then
                autoload[#autoload+1] = arg[i]
                autoload_next = false
            end
        end
    end

    local plain = Bundle()
    plain.emit "do\n"
    plain.emit "local libs = {\n"
    for i = 1, #scripts do
        local script_source = read(scripts[i]):gsub("^(#!)", "--%1")
        assert(load(script_source, scripts[i], 't'))
        plain.emit(("%s = assert(load(%q, '@%s', 't')),"):format(package_name(scripts[i]), script_source, scripts[i]))
    end
    plain.emit "}\n"
    plain.emit "table.insert(package.searchers, 1, function(name) return libs[name] end)\n"
    for i = 2, #autoload do
        plain.emit(("require '%s'\n"):format(package_name(autoload[i])))
    end
    plain.emit(("require '%s'\n"):format(package_name(scripts[1])))
    plain.emit "end\n"

    local encoded = Bundle()
    local last = 0
    local _ = plain.get():gsub(".", function(c)
        local c1 = (c:byte() - last) & 0xFF
        last = c:byte()
        encoded.emit(string.pack("B", c1))
    end)

    if format == "b" then
        local chunk = Bundle()
        local payload = encoded.get()
        local header = string.pack("<I8I8", #payload, bundle.magic)
        chunk.emit(payload)
        chunk.emit(header)
        return(chunk.get())
    end

    if format == "c" then
        local hex = Bundle()
        local n = 0
        local _ = encoded.get():gsub(".", function(c)
            if n % 16 == 0 then hex.emit("\n") end
            n = n+1
            hex.emit((" 0x%02X,"):format(c:byte()))
        end)
        hex.emit("\n")
        return hex:get()
    end

end

local function drop_chunk(exe)
    local size, magic = string.unpack("<I8I8", exe, #exe - 15)
    if magic ~= bundle.magic then
        io.stderr:write("error: no LuaX header found in the current target\n")
        os.exit(1)
    end
    return exe:sub(1, #exe - 16 - size)
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
