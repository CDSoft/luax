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

local fun = {}

local deprecated
deprecated = function()
    io.stderr:write("WARNING: the luax module 'fun' is deprecated\n")
    deprecated = function() end
end

-- deprecated by P.id
function fun.id(...)
    deprecated()
    return ...
end

-- deprecated by P.const
function fun.const(...)
    deprecated()
    local res = {...}
    return function() return table.unpack(res) end
end

-- deprecated by M.keys
function fun.keys(t)
    deprecated()
    local ks = {}
    for k,_ in pairs(t) do table.insert(ks, k) end
    table.sort(ks, function(a, b)
        local ta, tb = type(a), type(b)
        if ta == tb then return a < b else return ta < tb end
    end)
    return ks
end

-- deprecated by M.values
function fun.values(t)
    deprecated()
    local vs = {}
    for _,v in fun.pairs(t) do table.insert(vs, v) end
    return vs
end

-- deprecated by M.pairs
function fun.pairs(t)
    deprecated()
    local ks = fun.keys(t)
    local i = 1
    return function()
        if i <= #ks then
            local k = ks[i]
            local v = t[k]
            i = i+1
            return k, v
        end
    end
end

-- deprecated by L.concat
function fun.concat(...)
    deprecated()
    local t = {}
    for i = 1, select("#", ...) do
        local ti = select(i, ...)
        for _, v in ipairs(ti) do table.insert(t, v) end
    end
    return t
end

-- deprecated by M.unions
function fun.merge(...)
    deprecated()
    local t = {}
    for i = 1, select("#", ...) do
        local ti = select(i, ...)
        for k, v in pairs(ti) do t[k] = v end
    end
    return t
end

-- deprecated by L.flatten
function fun.flatten(...)
    deprecated()
    local xs = {}
    local function f(...)
        for i = 1, select("#", ...) do
            local x = select(i, ...)
            if type(x) == "table" then
                f(table.unpack(x))
            else
                table.insert(xs, x)
            end
        end
    end
    f(...)
    return xs
end

-- deprecated by L.replicate
function fun.replicate(n, x)
    deprecated()
    local xs = {}
    for _ = 1, n do table.insert(xs, x) end
    return xs
end

-- deprecated by P.compose
function fun.compose(...)
    deprecated()
    local n = select("#", ...)
    local fs = {...}
    local function apply(i, ...)
        if i > 0 then return apply(i-1, fs[i](...)) end
        return ...
    end
    return function(...)
        return apply(n, ...)
    end
end

-- deprecated by L.map
function fun.map(f, xs)
    deprecated()
    if type(f) == "table" and type(xs) == "function" then f, xs = xs, f end
    local ys = {}
    for i, x in ipairs(xs) do table.insert(ys, (f(x, i))) end
    return ys
end

-- deprecated by M.map
function fun.tmap(f, t)
    deprecated()
    if type(f) == "table" and type(t) == "function" then f, t = t, f end
    local t2 = {}
    for k, v in fun.pairs(t) do
        t2[k] = (f(v, k))
    end
    return t2
end

-- deprecated by L.filter
function fun.filter(p, xs)
    deprecated()
    if type(p) == "table" and type(xs) == "function" then p, xs = xs, p end
    local ys = {}
    for i, x in ipairs(xs) do
        if p(x, i) then table.insert(ys, x) end
    end
    return ys
end

-- deprecated by M.filter[WithKey]
function fun.tfilter(p, t)
    deprecated()
    if type(p) == "table" and type(t) == "function" then p, t = t, p end
    local t2 = {}
    for k, v in fun.pairs(t) do
        if p(v, k) then t2[k] = v end
    end
    return t2
end

-- deprecated by L.map
function fun.foreach(xs, f)
    deprecated()
    if type(f) == "table" and type(xs) == "function" then f, xs = xs, f end
    for i, x in ipairs(xs) do f(x, i) end
end

-- deprecated by M.map[WithKey]
function fun.tforeach(t, f)
    deprecated()
    if type(f) == "table" and type(t) == "function" then f, t = t, f end
    for k, v in fun.pairs(t) do f(v, k) end
end

-- deprecated by P.prefix
function fun.prefix(pre)
    deprecated()
    return function(s) return pre..s end
end

-- deprecated by P.suffix
function fun.suffix(suf)
    deprecated()
    return function(s) return s..suf end
end

-- deprecated L.range
function fun.range(a, b, step)
    deprecated()
    assert(step ~= 0, "range step can not be zero")
    if not b then a, b = 1, a end
    step = step or (a < b and 1) or (a > b and -1)
    local r = {}
    if a < b then
        assert(step > 0, "step shall be positive")
        while a <= b do
            table.insert(r, a)
            a = a + step
        end
    elseif a > b then
        assert(step < 0, "step shall be negative")
        while a >= b do
            table.insert(r, a)
            a = a + step
        end
    else
        table.insert(r, a)
    end
    return r
end

-- deprecated by P.memo1
function fun.memo(f)
    deprecated()
    return setmetatable({}, {
        __index = function(self, k) local v = f(k); self[k] = v; return v; end,
        __call = function(self, k) return self[k] end
    })
end

local function interpolate(s, t)
    return (s:gsub("%$(%b())", function(x)
        local y = ((assert(load("return "..x, nil, "t", t)))())
        if type(y) == "table" then y = tostring(y) end
        return y
    end))
end

local function Interpolator(t)
    return function(x)
        if type(x) == "table" then return Interpolator(fun.merge(t, x)) end
        if type(x) == "string" then return interpolate(x, t) end
    end
end

-- deprecated by I
function fun.I(t)
    deprecated()
    return Interpolator(fun.merge(t))
end

return fun
