local socket_submodules = { "ftp", "headers", "http", "smtp", "tp", "url" }

local function emit(x) io.stdout:write(x, " ") end

for i = 1, #arg do

    -- autoexec *x.lua only
    if arg[i]:match "x%.lua$" then
        emit "-autoexec"
    end

    -- some luasocket packages are socket submodules
    for _, submodule in ipairs(socket_submodules) do
        if arg[i]:match("luasocket/"..submodule.."%.lua$") then
            arg[i] = arg[i]..":socket."..submodule
        end
    end

    emit(arg[i])

end
