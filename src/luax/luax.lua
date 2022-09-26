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

local luax = {}

local float_format = "%s"
local int_format = "%s"

function luax.precision(len, frac)
    float_format =
        type(len) == "string"                               and len
        or type(len) == "number" and type(frac) == "number" and ("%%%s.%sf"):format(len, frac)
        or type(len) == "number" and frac == nil            and ("%%%sf"):format(len, frac)
        or "%s"
end

function luax.base(b)
    int_format =
        type(b) == "string" and b
        or b == 10          and "%s"
        or b == 16          and "0x%x"
        or b == 8           and "0o%o"
        or "%s"
end

function luax.pretty(x)
    local M = require "Map"

    local tokens = {}
    local function emit(token) tokens[#tokens+1] = token end
    local function drop() table.remove(tokens) end

    local stack = {}
    local function push(val) stack[#stack + 1] = val end
    local function pop() table.remove(stack) end
    local function in_stack(val)
        for i = 1, #stack do
            if rawequal(stack[i], val) then return true end
        end
    end

    local function fmt(val)
        if type(val) == "table" then
            if in_stack(val) then
                emit "{...}" -- recursive table
            else
                push(val)
                emit "{"
                local n = 0
                for i = 1, #val do
                    fmt(val[i])
                    emit ", "
                    n = n + 1
                end
                for k, v in M.pairs(val) do
                    if type(k) == "number" or math.type(k) == "integer" then
                        if k < 1 or k > #val then
                            emit(("[%d]="):format(k))
                            fmt(v)
                            emit ", "
                            n = n + 1
                        end
                    else
                        emit(("%s="):format(k))
                        fmt(v)
                        emit ", "
                        n = n + 1
                    end
                end
                if n > 0 then drop() end
                emit "}"
                pop()
            end
        elseif type(val) == "number" then
            if math.type(val) == "integer" then
                emit(int_format:format(val))
            elseif math.type(val) == "float" then
                emit(float_format:format(val))
            else
                emit(("%s"):format(val))
            end
        elseif type(val) == "string" then
            emit(("%q"):format(val))
        else
            emit(("%s"):format(val))
        end
    end

    fmt(x)
    return table.concat(tokens)
end

luax.inspect = require "inspect"

function luax.printi(x)
    print(luax.inspect(x))
end

return luax
