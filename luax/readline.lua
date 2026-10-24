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

--@LIB

local term = require "term"

local has_M, M = pcall(require, "_readline")

if not has_M then
    local function nop() return nop end
    return setmetatable({read=term.prompt}, {__index=nop})
end

local start_prompt = "\027]133;A\027\\"
local end_prompt   = "\027]133;B\027\\"
local end_input    = "\027]133;C\027\\"
local end_output   = "\027]133;D\027\\"

local read = M.read

function M.read(p)
    local isatty = term.isatty(io.stdin)
    if isatty then
        io.stdout:write(end_output, start_prompt)
    end
    local line = read(p)
    if isatty then
        io.stdout:write(end_prompt, end_input)
    end
    return line
end

return M
