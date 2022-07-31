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

-- functions added to the string package

function string.split(s, sep, maxsplit, plain)
    assert(sep and sep ~= "")
    maxsplit = maxsplit or (1/0)
    local items = {}
    if #s > 0 then
        local init = 1
        for _ = 1, maxsplit do
            local m, n = s:find(sep, init, plain)
            if m and m <= n then
                table.insert(items, s:sub(init, m - 1))
                init = n + 1
            else
                break
            end
        end
        table.insert(items, s:sub(init))
    end
    return items
end

function string.lines(s)
    local lines = s:split('\r?\n\r?')
    if lines[#lines] == "" and s:match('\r?\n\r?$') then table.remove(lines) end
    return lines
end

function string.words(s)
    local words = s:split('%s+')
    if words[1] == "" and s:match('^%s+') then table.remove(words, 1) end
    if words[#words] == "" and s:match('%s+$') then table.remove(words) end
    return words
end

function string.ltrim(s)
    return s:match("^%s*(.*)")
end

function string.rtrim(s)
    return s:match("(.-)%s*$")
end

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end
