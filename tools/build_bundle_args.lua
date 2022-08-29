local autoexec = {
    ["src/crypt/cryptx.lua"]    = true,
    ["src/fs/fsx.lua"]          = true,
    ["src/std/stringx.lua"]     = true,
}

local submodule = {
    ["src/socket/luasocket/ftp.lua"]        = "socket.ftp",
    ["src/socket/luasocket/headers.lua"]    = "socket.headers",
    ["src/socket/luasocket/http.lua"]       = "socket.http",
    ["src/socket/luasocket/smtp.lua"]       = "socket.smtp",
    ["src/socket/luasocket/tp.lua"]         = "socket.tp",
    ["src/socket/luasocket/url.lua"]        = "socket.url",
}

local function emit(x) io.stdout:write(x, " ") end

for i = 1, #arg do

    if autoexec[arg[i]] then
        emit "-autoexec"
    end

    local submodule_name = submodule[arg[i]]
    if submodule_name then
        arg[i] = arg[i]..":"..submodule_name
    end

    emit(arg[i])

end
