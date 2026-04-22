local version = "10.2.1"
local year = 2026
local url = "codeberg.org/cdsoft/luax"
local author = "Christophe Delord"

--@LIB

return setmetatable({
    version = version,
    copyright = ("Copyright (C) 2021-%d %s, %s"):format(year, url, author),
    url = url,
    author = author,
}, {
    __tostring = function() return "LuaX "..version end,
})
