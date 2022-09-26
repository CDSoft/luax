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

--[[------------------------------------------------------------------------@@@
# List

[`Data.List`]: https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html

`List` is a module inspired by the Haskell module [`Data.List`].

Note: contrary to the original Haskell modules, all these functions are evaluated strictly
(i.e. no lazy evaluation, no infinite list, ...).

```lua
local L = require "List"
```
@@@]]

local L = {}

local mt = {
    __index = {},
}

--[[------------------------------------------------------------------------@@@
## Basic functions
@@@]]

--[[@@@
```lua
L.clone(xs)
xs:clone()
```
> Clone a list
@@@]]

function L.clone(xs)
    local ys = {}
    for i = 1, #xs do ys[i] = xs[i] end
    return setmetatable(ys, mt)
end

mt.__index.clone = L.clone

--[[@@@
```lua
L.ipairs(xs)
xs:ipairs()
```
> Like Lua ipairs function
@@@]]

function L.ipairs(xs)
    local i = 0
    return function()
        if i < #xs then
            i = i + 1
            local v = xs[i]
            return i, v
        end
    end
end

mt.__index.ipairs = L.ipairs

--[[@@@
```lua
xs .. ys
```
> Append two lists, i.e.,
> ```lua
> L{x1, ..., xn} .. L{y1, ..., yn} == L{x1, ..., xn, y1, ..., yn}
> ```
@@@]]
function mt.__concat(xs, ys)
    return L.concat{xs, ys}
end

--[[@@@
```lua
L.head(xs)
xs:head()
```
> Extract the first element of a list.
> ```lua
> head{1,2,3} == 1
> head{} == nil
> ```
@@@]]
function L.head(xs)
    return xs[1]
end

mt.__index.head = L.head

--[[@@@
```lua
L.last(xs)
xs:last()
```
> Extract the last element of a list.
> ```lua
> last{1,2,3} == 3
> last{} == nil
> ```
@@@]]
function L.last(xs)
    return xs[#xs]
end

mt.__index.last = L.last

--[[@@@
```lua
L.tail(xs)
xs:tail()
```
> Extract the elements after the head of a list
> ```lua
> tail{1,2,3} == {2,3}
> tail{} == nil
> ```
@@@]]
function L.tail(xs)
    if #xs == 0 then return nil end
    local tail = {}
    for i = 2, #xs do tail[#tail+1] = xs[i] end
    return L(tail)
end

mt.__index.tail = L.tail

--[[@@@
```lua
L.init(xs)
xs:init()
```
> Return all the elements of a list except the last one.
> ```lua
> init{1,2,3} == {1,2}
> init{} = nil
> ```
@@@]]
function L.init(xs)
    if #xs == 0 then return nil end
    local init = {}
    for i = 1, #xs-1 do init[#init+1] = xs[i] end
    return L(init)
end

mt.__index.init = L.init

--[[@@@
```lua
L.uncons(xs)
xs:uncons()
```
> Decompose a list into its head and tail.
> ```lua
> uncons{1,2,3} == 1, {2,3}
> uncons{} = nil, nil
> ```
@@@]]
function L.uncons(xs)
    return L.head(xs), L.tail(xs)
end

mt.__index.uncons = L.uncons

--[[@@@
```lua
L.singleton(x)
```
> Produce singleton list.
> ```lua
> singleton(true) == {true}
> ```
@@@]]
function L.singleton(x)
    return L{x}
end

--[[@@@
```lua
L.null(xs)
xs:null()
```
> Test whether the structure is empty.
> ```lua
> null{} == true
> null{1,2,3} == false
> ```
@@@]]
function L.null(xs)
    return #xs == 0
end

mt.__index.null = L.null

--[[@@@
```lua
L.length(xs)
xs:length()
```
> Returns the length of a list.
> ```lua
> length{} == 0
> length{1,2,3} == 3
> ```
@@@]]
function L.length(xs)
    return #xs
end

mt.__index.length = L.length

--[[------------------------------------------------------------------------@@@
## List transformations
@@@]]

--[[@@@
```lua
L.map(f, xs)
xs:map(f)
```
> Returns the list obtained by applying f to each element of xs
> ```lua
> map(f, {x1, x2, ...}) == {f(x1), f(x2), ...}
> ```
@@@]]
function L.map(f, xs)
    local ys = {}
    for i = 1, #xs do
        ys[i] = f(xs[i])
    end
    return L(ys)
end

mt.__index.map = function(t, f) return L.map(f, t) end

--[[@@@
```lua
L.mapWithIndex(f, xs)
xs:mapWithIndex(f)
```
> Returns the list obtained by applying f to each element of xs with their positions
> ```lua
> mapWithIndex(f, {x1, x2, ...}) == {f(1, x1), f(2, x2), ...}
> ```
@@@]]
function L.mapWithIndex(f, xs)
    local ys = {}
    for i = 1, #xs do
        ys[i] = f(i, xs[i])
    end
    return L(ys)
end

mt.__index.mapWithIndex = function(t, f) return L.mapWithIndex(f, t) end

--[[@@@
```lua
L.reverse(xs)
xs:reverse()
```
> Returns the elements of xs in reverse order.
> ```lua
> reverse{1,2,3} == {3,2,1}
> ```
@@@]]
function L.reverse(xs)
    local reverse = {}
    for i = #xs, 1, -1 do reverse[#reverse+1] = xs[i] end
    return L(reverse)
end

mt.__index.reverse = L.reverse

--[[@@@
```lua
L.intersperse(x, xs)
xs:intersperse(x)
```
> Intersperses a element x between the elements of xs.
> ```lua
> intersperse(x, {x1, x2, x3}) == {x1, x, x2, x, x3}
> ```
@@@]]
function L.intersperse(sep, xs)
    local intersperse = {xs[1]}
    for i = 2, #xs do
        intersperse[#intersperse+1] = sep
        intersperse[#intersperse+1] = xs[i]
    end
    return L(intersperse)
end

mt.__index.intersperse = function(xs, sep) return L.intersperse(sep, xs) end

--[[@@@
```lua
intercalate(xs, xss)
xss:intercalate(xs)
```
> Inserts the list xs in between the lists in xss and concatenates the result.
> ```lua
> intercalate({x1, x2}, {{y1, y2}, {y3, y4}, {y5, y6}}) ==
>   {y1, y2, x1, x2, y3, y4, x1, x2, y5, y6}
> ```
@@@]]
function L.intercalate(xs, xss)
    return L.concat(L.intersperse(xs, xss))
end

mt.__index.intercalate = function(xss, xs) return L.intercalate(xs, xss) end

--[[@@@
```lua
L.transpose(xss)
xss:transpose()
```
> Transposes the rows and columns of its argument.
> ```lua
> transpose{{x1,x2,x3},{y1,y2,y3}} == {{x1,y1},{x2,y2},{x3,y3}}
> ```
@@@]]
function L.transpose(xss)
    local N = #xss
    local M = math.max(table.unpack(L.map(L.length, xss)))
    local yss = {}
    for j = 1, M do
        local ys = {}
        for i = 1, N do ys[#ys+1] = xss[i][j] end
        yss[j] = ys
    end
    return L(yss)
end

mt.__index.transpose = L.transpose

--[[@@@
```lua
L.subsequences(xs)
xs:subsequences()
```
> Returns the list of all subsequences of the argument.
> ```lua
> subsequences{"a", "b", "c"} ==
>   {{}, {"a"}, {"b"}, {"a","b"}, {"c"}, {"a","c"}, {"b","c"}, {"a","b","c"}}
> ```
@@@]]
function L.subsequences(xs)
    if L.null(xs) then return L{{}} end
    local inits = L.subsequences(L.init(xs))
    local last = L.last(xs)
    return inits .. L.map(function(seq) return L.concat{seq, {last}} end, inits)
end

mt.__index.subsequences = L.subsequences

--[[@@@
```lua
L.permutations(xs)
xs:permutations()
```
> Returns the list of all permutations of the argument.
> ```lua
> permutations{"a", "b", "c"} ==
>   { {"a","b","c"}, {"a","c","b"},
>     {"b","a","c"}, {"b","c","a"},
>     {"c","b","a"}, {"c","a","b"} }
> ```
@@@]]
function L.permutations(xs)
    local perms = {}
    local n = #xs
    xs = L.clone(xs)
    local function permute(k)
        if k > n then perms[#perms+1] = L.clone(xs)
        else
            for i = k, n do
                xs[k], xs[i] = xs[i], xs[k]
                permute(k+1)
                xs[k], xs[i] = xs[i], xs[k]
            end
        end
    end
    permute(1)
    return L(perms)
end

mt.__index.permutations = L.permutations

--[[@@@
```lua
L.flatten(xs)
xs:flatten()
```
> Returns a flat list with all elements recursively taken from xs
@@@]]
function L.flatten(xs)
    local ys = {}
    local function f(xs)
        for i = 1, #xs do
            local x = xs[i]
            if type(x) == "table" then
                f(x)
            else
                ys[#ys+1] = x
            end
        end
    end
    f(xs)
    return L(ys)
end

mt.__index.flatten = L.flatten

--[[------------------------------------------------------------------------@@@
## Reducing lists (folds)
@@@]]

--[[@@@
```lua
L.foldl(f, x, xs)
xs:foldl(f, x)
```
> Left-associative fold of a structure.
> ```lua
> foldl(f, x, {x1, x2, x3}) == f(f(f(x, x1), x2), x3)
> ```
@@@]]
function L.foldl(fzx, z, xs)
    for i = 1, #xs do
        z = fzx(z, xs[i])
    end
    return z
end

mt.__index.foldl = function(xs, fzx, z) return L.foldl(fzx, z, xs) end

--[[@@@
```lua
L.foldl1(f, xs)
xs:foldl1(f)
```
> Left-associative fold of a structure (the initial value is `xs[1]`).
> ```lua
> foldl1(f, {x1, x2, x3}) == f(f(x1, x2), x3)
> ```
@@@]]
function L.foldl1(fzx, xs)
    if #xs == 0 then return nil end
    local z = xs[1]
    for i = 2, #xs do
        z = fzx(z, xs[i])
    end
    return z
end

mt.__index.foldl1 = function(xs, fzx) return L.foldl1(fzx, xs) end

--[[@@@
```lua
L.foldr(f, x, xs)
xs:foldr(f, x)
```
> Right-associative fold of a structure.
> ```lua
> foldr(f, x, {x1, x2, x3}) == f(x1, f(x2, f(x3, x)))
> ```
@@@]]
function L.foldr(fxz, z, xs)
    for i = #xs, 1, -1 do
        z = fxz(xs[i], z)
    end
    return z
end

mt.__index.foldr = function(xs, fxz, z) return L.foldr(fxz, z, xs) end

--[[@@@
```lua
L.foldr1(f, xs)
xs:foldr1(f)
```
> Right-associative fold of a structure (the initial value is `xs[#xs]`).
> ```lua
> foldr1(f, {x1, x2, x3}) == f(x1, f(x2, x3))
> ```
@@@]]
function L.foldr1(fxz, xs)
    if #xs == 0 then return nil end
    local z = xs[#xs]
    for i = #xs-1, 1, -1 do
        z = fxz(xs[i], z)
    end
    return z
end

mt.__index.foldr1 = function(xs, fxz) return L.foldr1(fxz, xs) end

--[[------------------------------------------------------------------------@@@
## Special folds
@@@]]

--[[@@@
```lua
L.concat(xss)
xss:concat()
```
> The concatenation of all the elements of a container of lists.
> ```lua
> concat{{x1, x2}, {x3}, {x4, x5}} == {x1,x2,x3,x4,x5}
> ```
@@@]]
function L.concat(xss)
    local t = {}
    for i = 1, #xss do
        local xs = xss[i]
        for j = 1, #xs do t[#t+1] = xs[j] end
    end
    return L(t)
end

mt.__index.concat = L.concat

--[[@@@
```lua
L.concatMap(f, xs)
xs:concatMap(f)
```
> Map a function over all the elements of a container and concatenate the resulting lists.
@@@]]
function L.concatMap(fx, xs)
    return L.concat(L.map(fx, xs))
end

mt.__index.concatMap = function(xs, fx) return L.concatMap(fx, xs) end

--[[@@@
```lua
L.and_(bs)
bs:and_()
```
> Returns the conjunction of a container of Bools.
@@@]]
function L.and_(bs)
    for i = 1, #bs do if not bs[i] then return false end end
    return true
end

mt.__index.and_ = L.and_

--[[@@@
```lua
L.or_(bs)
bs:or_()
```
> Returns the disjunction of a container of Bools.
@@@]]
function L.or_(bs)
    for i = 1, #bs do if bs[i] then return true end end
    return false
end

mt.__index.or_ = L.or_

--[[@@@
```lua
L.any(p, xs)
xs:any(p)
```
> Determines whether any element of the structure satisfies the predicate.
@@@]]
function L.any(p, xs)
    for i = 1, #xs do if p(xs[i]) then return true end end
    return false
end

mt.__index.any = function(xs, p) return L.any(p, xs) end

--[[@@@
```lua
L.all(p, xs)
xs:all(p)
```
> Determines whether all elements of the structure satisfy the predicate.
@@@]]
function L.all(p, xs)
    for i = 1, #xs do if not p(xs[i]) then return false end end
    return true
end

mt.__index.all = function(xs, p) return L.all(p, xs) end

--[[@@@
```lua
L.sum(xs)
xs:sum()
```
> Returns the sum of the numbers of a structure.
@@@]]
function L.sum(xs)
    local s = 0
    for i = 1, #xs do s = s + xs[i] end
    return s
end

mt.__index.sum = L.sum

--[[@@@
```lua
L.product(xs)
xs:product()
```
> Returns the product of the numbers of a structure.
@@@]]
function L.product(xs)
    local p = 1
    for i = 1, #xs do p = p * xs[i] end
    return p
end

mt.__index.product = L.product

--[[@@@
```lua
L.maximum(xs)
xs:maximum()
```
> The largest element of a non-empty structure.
@@@]]
function L.maximum(xs)
    if #xs == 0 then return nil end
    return math.max(table.unpack(xs))
end

mt.__index.maximum = L.maximum

--[[@@@
```lua
L.minimum(xs)
xs:minimum()
```
> The least element of a non-empty structure.
@@@]]
function L.minimum(xs)
    if #xs == 0 then return nil end
    return math.min(table.unpack(xs))
end

mt.__index.minimum = L.minimum

--[[------------------------------------------------------------------------@@@
## Building lists
@@@]]

--[[------------------------------------------------------------------------@@@
### Scans
@@@]]

--[[@@@
```lua
L.scanl(f, x, xs)
xs:scanl(f, x)
```
> Similar to `foldl` but returns a list of successive reduced values from the left.
@@@]]
function L.scanl(fzx, z, xs)
    local zs = {z}
    for i = 1, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return L(zs)
end

mt.__index.scanl = function(xs, fzx, z) return L.scanl(fzx, z, xs) end

--[[@@@
```lua
L.scanl1(f, xs)
xs:scanl1(f)
```
> Like `scanl` but the initial value is `xs[1]`.
@@@]]
function L.scanl1(fzx, xs)
    local z = xs[1]
    local zs = {z}
    for i = 2, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return L(zs)
end

mt.__index.scanl1 = function(xs, fzx) return L.scanl1(fzx, xs) end

--[[@@@
```lua
L.scanr(f, x, xs)
xs:scanr(f, x)
```
> Similar to `foldr` but returns a list of successive reduced values from the right.
@@@]]
function L.scanr(fxz, z, xs)
    local zs = {z}
    for i = #xs, 1, -1 do
        z = fxz(xs[i], z)
        table.insert(zs, 1, z)
    end
    return L(zs)
end

mt.__index.scanr = function(xs, fzx, z) return L.scanr(fzx, z, xs) end

--[[@@@
```lua
L.scanr1(f, xs)
xs:scanr1(f)
```
> Like `scanr` but the initial value is `xs[#xs]`.
@@@]]
function L.scanr1(fxz, xs)
    local z = xs[#xs]
    local zs = {z}
    for i = #xs-1, 1, -1 do
        z = fxz(xs[i], z)
        table.insert(zs, 1, z)
    end
    return L(zs)
end

mt.__index.scanr1 = function(xs, fzx) return L.scanr1(fzx, xs) end

--[[------------------------------------------------------------------------@@@
### Infinite lists
@@@]]

--[[@@@
```lua
replicate(n, x)
```
> Returns a list of length n with x the value of every element.
@@@]]
function L.replicate(n, x)
    local xs = {}
    for _ = 1, n do
        xs[#xs+1] = x
    end
    return L(xs)
end

--[[------------------------------------------------------------------------@@@
### Unfolding
@@@]]

--[[@@@
```lua
L.unfoldr(f, z)
```
> Builds a list from a seed value (dual of `foldr`).
@@@]]
function L.unfoldr(fz, z)
    local xs = {}
    while true do
        local x
        x, z = fz(z)
        if x == nil then break end
        xs[#xs+1] = x
    end
    return L(xs)
end

--[[------------------------------------------------------------------------@@@
### Range
@@@]]

--[[@@@
```lua
L.range(a)
L.range(a, b)
L.range(a, b, step)
```
> Returns a range [1, a], [a, b] or [a, a+step, ... b]
@@@]]
function L.range(a, b, step)
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
    return L(r)
end

--[[------------------------------------------------------------------------@@@
## Sublists
@@@]]

--[[------------------------------------------------------------------------@@@
### Extracting sublists
@@@]]

--[[@@@
```lua
L.take(n, xs)
xs:take(n)
```
> Returns the prefix of xs of length n.
@@@]]
function L.take(n, xs)
    local ys = {}
    for i = 1, n do
        ys[#ys+1] = xs[i]
    end
    return L(ys)
end

mt.__index.take = function(xs, n) return L.take(n, xs) end

--[[@@@
```lua
L.drop(n, xs)
xs:drop(n)
```
> Returns the suffix of xs after the first n elements.
@@@]]
function L.drop(n, xs)
    local ys = {}
    for i = n+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return L(ys)
end

mt.__index.drop = function(xs, n) return L.drop(n, xs) end

--[[@@@
```lua
L.splitAt(n, xs)
xs:splitAt(n)
```
> Returns a tuple where first element is xs prefix of length n and second element is the remainder of the list.
@@@]]
function L.splitAt(n, xs)
    return L.take(n, xs), L.drop(n, xs)
end

mt.__index.splitAt = function(xs, n) return L.splitAt(n, xs) end

--[[@@@
```lua
L.takeWhile(p, xs)
xs:takeWhile(p)
```
> Returns the longest prefix (possibly empty) of xs of elements that satisfy p.
@@@]]
function L.takeWhile(p, xs)
    local ys = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return L(ys)
end

mt.__index.takeWhile = function(xs, p) return L.takeWhile(p, xs) end

--[[@@@
```lua
L.dropWhile(p, xs)
xs:dropWhile(p)
```
> Returns the suffix remaining after `takeWhile(p, xs)`{.lua}.
@@@]]
function L.dropWhile(p, xs)
    local zs = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return L(zs)
end

mt.__index.dropWhile = function(xs, p) return L.dropWhile(p, xs) end

--[[@@@
```lua
L.dropWhileEnd(p, xs)
xs:dropWhileEnd(p)
```
> Drops the largest suffix of a list in which the given predicate holds for all elements.
@@@]]
function L.dropWhileEnd(p, xs)
    local zs = {}
    local i = #xs
    while i > 0 and p(xs[i]) do
        i = i-1
    end
    for j = 1, i do
        zs[#zs+1] = xs[j]
    end
    return L(zs)
end

mt.__index.dropWhileEnd = function(xs, p) return L.dropWhileEnd(p, xs) end

--[[@@@
```lua
L.span(p, xs)
xs:span(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that satisfy p and second element is the remainder of the list.
@@@]]
function L.span(p, xs)
    local ys = {}
    local zs = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return L(ys), L(zs)
end

mt.__index.span = function(xs, p) return L.span(p, xs) end

--[[@@@
```lua
L.break_(p, xs)
xs:break_(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that do not satisfy p and second element is the remainder of the list.
@@@]]
function L.break_(p, xs)
    local ys = {}
    local zs = {}
    local i = 1
    while i <= #xs and not p(xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return L(ys), L(zs)
end

mt.__index.break_ = function(xs, p) return L.break_(p, xs) end

--[[@@@
```lua
L.stripPrefix(prefix, xs)
xs:stripPrefix(prefix)
```
> Drops the given prefix from a list.
@@@]]
function L.stripPrefix(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return nil end
    end
    local ys = {}
    for i = #prefix+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return L(ys)
end

mt.__index.stripPrefix = function(xs, prefix) return L.stripPrefix(prefix, xs) end

--[[@@@
```lua
L.group(xs)
xs:group()
```
> Returns a list of lists such that the concatenation of the result is equal to the argument. Moreover, each sublist in the result contains only equal elements.
@@@]]
function L.group(xs)
    local yss = {}
    if #xs == 0 then return L(yss) end
    local y = xs[1]
    local ys = {y}
    for i = 2, #xs do
        local x = xs[i]
        if x == y then
            ys[#ys+1] = x
        else
            yss[#yss+1] = ys
            y = x
            ys = {y}
        end
    end
    yss[#yss+1] = ys
    return L(yss)
end

mt.__index.group = L.group

--[[@@@
```lua
L.inits(xs)
xs:inits()
```
> Returns all initial segments of the argument, shortest first.
@@@]]
function L.inits(xs)
    local yss = {}
    for i = 0, #xs do
        local ys = {}
        for j = 1, i do
            ys[#ys+1] = xs[j]
        end
        yss[#yss+1] = ys
    end
    return L(yss)
end

mt.__index.inits = L.inits

--[[@@@
```lua
L.tails(xs)
xs:tails()
```
> Returns all final segments of the argument, longest first.
@@@]]
function L.tails(xs)
    local yss = {}
    for i = 1, #xs+1 do
        local ys = {}
        for j = i, #xs do
            ys[#ys+1] = xs[j]
        end
        yss[#yss+1] = ys
    end
    return L(yss)
end

mt.__index.tails = L.tails

--[[------------------------------------------------------------------------@@@
### Predicates
@@@]]

--[[@@@
```lua
L.isPrefixOf(prefix, xs)
prefix:isPrefixOf(xs)
```
> Returns `true` iff the first list is a prefix of the second.
@@@]]
function L.isPrefixOf(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return false end
    end
    return true
end

mt.__index.isPrefixOf = L.isPrefixOf

--[[@@@
```lua
L.isSuffixOf(suffix, xs)
suffix:isSuffixOf(xs)
```
> Returns `true` iff the first list is a suffix of the second.
@@@]]
function L.isSuffixOf(suffix, xs)
    for i = 1, #suffix do
        if xs[#xs-#suffix+i] ~= suffix[i] then return false end
    end
    return true
end

mt.__index.isSuffixOf = L.isSuffixOf

--[[@@@
```lua
L.isInfixOf(infix, xs)
infix:isInfixOf(xs)
```
> Returns `true` iff the first list is contained, wholly and intact, anywhere within the second.
@@@]]
function L.isInfixOf(infix, xs)
    for i = 1, #xs-#infix+1 do
        local found = true
        for j = 1, #infix do
            if xs[i+j-1] ~= infix[j] then found = false; break end
        end
        if found then return true end
    end
    return false
end

mt.__index.isInfixOf = L.isInfixOf

--[[@@@
```lua
L.isSubsequenceOf(seq, xs)
seq:isSubsequenceOf(xs)
```
> Returns `true` if all the elements of the first list occur, in order, in the second. The elements do not have to occur consecutively.
@@@]]
function L.isSubsequenceOf(seq, xs)
    local i = 1
    local j = 1
    while j <= #xs do
        if i > #seq then return true end
        if xs[j] == seq[i] then
            i = i+1
        end
        j = j+1
    end
    return false
end

mt.__index.isSubsequenceOf = L.isSubsequenceOf

--[[------------------------------------------------------------------------@@@
## Searching lists
@@@]]

--[[------------------------------------------------------------------------@@@
### Searching by equality
@@@]]

--[[@@@
```lua
L.elem(x, xs)
xs:elem(x)
```
> Returns `true` if x occurs in xs.
@@@]]
function L.elem(x, xs)
    for i = 1, #xs do
        if xs[i] == x then return true end
    end
    return false
end

mt.__index.elem = function(xs, x) return L.elem(x, xs) end

--[[@@@
```lua
L.notElem(x, xs)
xs:notElem(x)
```
> Returns `true` if x does not occur in xs.
@@@]]
function L.notElem(x, xs)
    for i = 1, #xs do
        if xs[i] == x then return false end
    end
    return true
end

mt.__index.notElem = function(xs, x) return L.notElem(x, xs) end

--[[@@@
```lua
L.lookup(x, xys)
xys:lookup(x)
```
> Looks up a hey `x` in an association list.
@@@]]
function L.lookup(x, xys)
    for i = 1, #xys do
        if xys[i][1] == x then return xys[i][2] end
    end
    return nil
end

mt.__index.lookup = function(xys, x) return L.lookup(x, xys) end

--[[------------------------------------------------------------------------@@@
### Searching with a predicate
@@@]]

--[[@@@
```lua
L.find(p, xs)
xs:find(p)
```
> Returns the leftmost element of xs matching the predicate p.
@@@]]
function L.find(p, xs)
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then return x end
    end
    return nil
end

mt.__index.find = function(xs, p) return L.find(p, xs) end

--[[@@@
```lua
L.filter(p, xs)
xs:filter(p)
```
> Returns the list of those elements that satisfy the predicate.
@@@]]
function L.filter(p, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x end
    end
    return L(ys)
end

mt.__index.filter = function(xs, p) return L.filter(p, xs) end

--[[@@@
```lua
L.partition(p, xs)
xs:partition(p)
```
> Returns the pair of lists of elements which do and do not satisfy the predicate, respectively.
@@@]]
function L.partition(p, xs)
    local ys = {}
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x else zs[#zs+1] = x end
    end
    return L(ys), L(zs)
end

mt.__index.partition = function(xs, p) return L.partition(p, xs) end

--[[------------------------------------------------------------------------@@@
## Indexing lists
@@@]]

--[[@@@
```lua
L.elemIndex(x, xs)
xs:elemIndex(x)
```
> Returns the index of the first element in the given list which is equal to the query element.
@@@]]
function L.elemIndex(x, xs)
    for i = 1, #xs do
        if x == xs[i] then return i end
    end
    return nil
end

mt.__index.elemIndex = function(xs, x) return L.elemIndex(x, xs) end

--[[@@@
```lua
L.elemIndices(x, xs)
xs:elemIndices(x)
```
> Returns the indices of all elements equal to the query element, in ascending order.
@@@]]
function L.elemIndices(x, xs)
    local indices = {}
    for i = 1, #xs do
        if x == xs[i] then indices[#indices+1] = i end
    end
    return L(indices)
end

mt.__index.elemIndices = function(xs, x) return L.elemIndices(x, xs) end

--[[@@@
```lua
L.findIndex(p, xs)
xs:findIndex(p)
```
> Returns the index of the first element in the list satisfying the predicate.
@@@]]
function L.findIndex(p, xs)
    for i = 1, #xs do
        if p(xs[i]) then return i end
    end
    return nil
end

mt.__index.findIndex = function(xs, p) return L.findIndex(p, xs) end

--[[@@@
```lua
L.findIndices(p, xs)
xs:findIndices(p)
```
> Returns the indices of all elements satisfying the predicate, in ascending order.
@@@]]
function L.findIndices(p, xs)
    local indices = {}
    for i = 1, #xs do
        if p(xs[i]) then indices[#indices+1] = i end
    end
    return L(indices)
end

mt.__index.findIndices = function(xs, p) return L.findIndices(p, xs) end

--[[------------------------------------------------------------------------@@@
## Zipping and unzipping lists
@@@]]

--[[@@@
```lua
L.zip(as, bs)
L.zip3(as, bs, cs)
L.zip4(as, bs, cs, ds)
L.zip5(as, bs, cs, ds, es)
L.zip6(as, bs, cs, ds, es, fs)
L.zip7(as, bs, cs, ds, es, fs, gs)
as:zip(bs)
as:zip3(bs, cs)
as:zip4(bs, cs, ds)
as:zip5(bs, cs, ds, es)
as:zip6(bs, cs, ds, es, fs)
as:zip7(bs, cs, ds, es, fs, gs)
```
> `zipN` takes `N` lists and returns a list of corresponding tuples.
@@@]]

function L.zip(as, bs)
    local zs = {}
    for i = 1, math.min(#as, #bs) do
        zs[#zs+1] = {as[i], bs[i]}
    end
    return L(zs)
end

function L.zip3(as, bs, cs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs) do
        zs[#zs+1] = {as[i], bs[i], cs[i]}
    end
    return L(zs)
end

function L.zip4(as, bs, cs, ds)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds) do
        zs[#zs+1] = {as[i], bs[i], cs[i], ds[i]}
    end
    return L(zs)
end

function L.zip5(as, bs, cs, ds, es)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es) do
        zs[#zs+1] = {as[i], bs[i], cs[i], ds[i], es[i]}
    end
    return L(zs)
end

function L.zip6(as, bs, cs, ds, es, fs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es, #fs) do
        zs[#zs+1] = {as[i], bs[i], cs[i], ds[i], es[i], fs[i]}
    end
    return L(zs)
end

function L.zip7(as, bs, cs, ds, es, fs, gs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es, #fs, #gs) do
        zs[#zs+1] = {as[i], bs[i], cs[i], ds[i], es[i], fs[i], gs[i]}
    end
    return L(zs)
end

mt.__index.zip = L.zip
mt.__index.zip3 = L.zip3
mt.__index.zip4 = L.zip4
mt.__index.zip5 = L.zip5
mt.__index.zip6 = L.zip6
mt.__index.zip7 = L.zip7

--[[@@@
```lua
L.zipWith(f, as, bs)
L.zipWith3(f, as, bs, cs)
L.zipWith4(f, as, bs, cs, ds)
L.zipWith5(f, as, bs, cs, ds, es)
L.zipWith6(f, as, bs, cs, ds, es, fs)
L.zipWith7(f, as, bs, cs, ds, es, fs, gs)
as:zipWith(f,bs)
as:zipWith3(f, bs, cs)
as:zipWith4(f, bs, cs, ds)
as:zipWith5(f, bs, cs, ds, es)
as:zipWith6(f, bs, cs, ds, es, fs)
as:zipWith7(f, bs, cs, ds, es, fs, gs)
```
> `zipWith` generalises `zip` by zipping with the function given as the first argument, instead of a tupling function.
@@@]]

function L.zipWith(f, as, bs)
    local zs = {}
    for i = 1, math.min(#as, #bs) do
        zs[#zs+1] = f(as[i], bs[i])
    end
    return L(zs)
end

function L.zipWith3(f, as, bs, cs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs) do
        zs[#zs+1] = f(as[i], bs[i], cs[i])
    end
    return L(zs)
end

function L.zipWith4(f, as, bs, cs, ds)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds) do
        zs[#zs+1] = f(as[i], bs[i], cs[i], ds[i])
    end
    return L(zs)
end

function L.zipWith5(f, as, bs, cs, ds, es)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es) do
        zs[#zs+1] = f(as[i], bs[i], cs[i], ds[i], es[i])
    end
    return L(zs)
end

function L.zipWith6(f, as, bs, cs, ds, es, fs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es, #fs) do
        zs[#zs+1] = f(as[i], bs[i], cs[i], ds[i], es[i], fs[i])
    end
    return L(zs)
end

function L.zipWith7(f, as, bs, cs, ds, es, fs, gs)
    local zs = {}
    for i = 1, math.min(#as, #bs, #cs, #ds, #es, #fs, #gs) do
        zs[#zs+1] = f(as[i], bs[i], cs[i], ds[i], es[i], fs[i], gs[i])
    end
    return L(zs)
end

mt.__index.zipWith = function(as, f, bs) return L.zipWith(f, as, bs) end
mt.__index.zipWith3 = function(as, f, bs, cs) return L.zipWith3(f, as, bs, cs) end
mt.__index.zipWith4 = function(as, f, bs, cs, ds) return L.zipWith4(f, as, bs, cs, ds) end
mt.__index.zipWith5 = function(as, f, bs, cs, ds, es) return L.zipWith5(f, as, bs, cs, ds, es) end
mt.__index.zipWith6 = function(as, f, bs, cs, ds, es, fs) return L.zipWith6(f, as, bs, cs, ds, es, fs) end
mt.__index.zipWith7 = function(as, f, bs, cs, ds, es, fs, gs) return L.zipWith7(f, as, bs, cs, ds, es, fs, gs) end

--[[@@@
```lua
L.unzip(zs)
L.unzip3(zs)
L.unzip4(zs)
L.unzip5(zs)
L.unzip6(zs)
L.unzip7(zs)
zs:unzip()
zs:unzip3()
zs:unzip4()
zs:unzip5()
zs:unzip6()
zs:unzip7()
```
> Transforms a list of n-tuples into a list of n lists
@@@]]

function L.unzip(zs)
    local as = {}
    local bs = {}
    for i = 1, #zs do
        as[i], bs[i] = table.unpack(zs[i])
    end
    return as, bs
end

function L.unzip3(zs)
    local as = {}
    local bs = {}
    local cs = {}
    for i = 1, #zs do
        as[i], bs[i], cs[i] = table.unpack(zs[i])
    end
    return as, bs, cs
end

function L.unzip4(zs)
    local as = {}
    local bs = {}
    local cs = {}
    local ds = {}
    for i = 1, #zs do
        as[i], bs[i], cs[i], ds[i] = table.unpack(zs[i])
    end
    return as, bs, cs, ds
end

function L.unzip5(zs)
    local as = {}
    local bs = {}
    local cs = {}
    local ds = {}
    local es = {}
    for i = 1, #zs do
        as[i], bs[i], cs[i], ds[i], es[i] = table.unpack(zs[i])
    end
    return as, bs, cs, ds, es
end

function L.unzip6(zs)
    local as = {}
    local bs = {}
    local cs = {}
    local ds = {}
    local es = {}
    local fs = {}
    for i = 1, #zs do
        as[i], bs[i], cs[i], ds[i], es[i], fs[i] = table.unpack(zs[i])
    end
    return as, bs, cs, ds, es, fs
end

function L.unzip7(zs)
    local as = {}
    local bs = {}
    local cs = {}
    local ds = {}
    local es = {}
    local fs = {}
    local gs = {}
    for i = 1, #zs do
        as[i], bs[i], cs[i], ds[i], es[i], fs[i], gs[i] = table.unpack(zs[i])
    end
    return as, bs, cs, ds, es, fs, gs
end

mt.__index.unzip = L.unzip
mt.__index.unzip3 = L.unzip3
mt.__index.unzip4 = L.unzip4
mt.__index.unzip5 = L.unzip5
mt.__index.unzip6 = L.unzip6
mt.__index.unzip7 = L.unzip7

--[[------------------------------------------------------------------------@@@
## Special lists
@@@]]

--[[------------------------------------------------------------------------@@@
### Functions on strings
@@@]]

--[[@@@
```lua
L.lines(s)
```
> Splits the argument into a list of lines stripped of their terminating `\n` characters.
@@@]]
function L.lines(s)
    return L(s:lines())
end

--[[@@@
```lua
L.words(s)
```
> Breaks a string up into a list of words, which were delimited by white space.
@@@]]
function L.words(s)
    return L(s:words())
end

--[[@@@
```lua
L.unlines(s)
s:unlines()
```
> Appends a `\n` character to each input string, then concatenates the results.
@@@]]
function L.unlines(xs)
    local s = {}
    for i = 1, #xs do
        s[#s+1] = xs[i]
        s[#s+1] = "\n"
    end
    return table.concat(s)
end

mt.__index.unlines = L.unlines

--[[@@@
```lua
L.unwords(s)
s:unwords()
```
> Joins words with separating spaces.
@@@]]
function L.unwords(xs)
    return table.concat(xs, " ")
end

mt.__index.unwords = L.unwords

--[[------------------------------------------------------------------------@@@
### Set operations
@@@]]

--[[@@@
```lua
L.nub(xs)
xs:nub()
```
> Removes duplicate elements from a list. In particular, it keeps only the first occurrence of each element.
@@@]]
function L.nub(xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if x == ys[j] then found = true; break end
        end
        if not found then ys[#ys+1] = x end
    end
    return L(ys)
end

mt.__index.nub = L.nub

--[[@@@
```lua
L.delete(x, xs)
xs:delete(x)
```
> Removes the first occurrence of x from its list argument.
@@@]]
function L.delete(x, xs)
    local ys = {}
    local i = 1
    while i <= #xs do
        if xs[i] == x then break end
        ys[#ys+1] = xs[i]
        i = i+1
    end
    i = i+1
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return L(ys)
end

mt.__index.delete = function(xs, x) return L.delete(x, xs) end

--[[@@@
```lua
L.difference(xs, ys)
xs:difference(ys)
```
> Returns the list difference. In `difference(xs, ys)`{.lua} the first occurrence of each element of ys in turn (if any) has been removed from xs.
@@@]]
function L.difference(xs, ys)
    local zs = {}
    ys = {table.unpack(ys)}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if ys[j] == x then
                found = true
                table.remove(ys, j)
                break
            end
        end
        if not found then zs[#zs+1] = x end
    end
    return L(zs)
end

mt.__index.difference = L.difference

--[[@@@
```lua
L.union(xs, ys)
xs:union(ys)
```
> Returns the list union of the two lists. Duplicates, and elements of the first list, are removed from the the second list, but if the first list contains duplicates, so will the result.
@@@]]
function L.union(xs, ys)
    local zs = {table.unpack(xs)}
    for i = 1, #ys do
        local y = ys[i]
        local found = false
        for j = 1, #zs do
            if y == zs[j] then found = true; break end
        end
        if not found then zs[#zs+1] = y end
    end
    return L(zs)
end

mt.__index.union = L.union

--[[@@@
```lua
L.intersect(xs, ys)
xs:intersect(ys)
```
> Returns the list intersection of two lists. If the first list contains duplicates, so will the result.
@@@]]
function L.intersect(xs, ys)
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if x == ys[j] then found = true; break end
        end
        if found then zs[#zs+1] = x end
    end
    return L(zs)
end

mt.__index.intersect = L.intersect

--[[------------------------------------------------------------------------@@@
### Ordered lists
@@@]]

--[[@@@
```lua
L.sort(xs)
xs:sort()
```
> Sorts xs from lowest to highest.
@@@]]
function L.sort(xs)
    local ys = {}
    for i = 1, #xs do ys[i] = xs[i] end
    table.sort(ys)
    return L(ys)
end

mt.__index.sort = L.sort

--[[@@@
```lua
L.sortOn(f, xs)
xs:sortOn(f)
```
> Sorts a list by comparing the results of a key function applied to each element.
@@@]]
function L.sortOn(f, xs)
    local ys = {}
    for i = 1, #xs do ys[i] = {f(xs[i]), xs[i]} end
    table.sort(ys, function(a, b) return a[1] < b[1] end)
    local zs = {}
    for i = 1, #ys do zs[i] = ys[i][2] end
    return L(zs)
end

mt.__index.sortOn = function (xs, f) return L.sortOn(f, xs) end

--[[@@@
```lua
L.insert(x, xs)
xs:insert(x)
```
> Inserts the element into the list at the first position where it is less than or equal to the next element.
@@@]]
function L.insert(x, xs)
    local ys = {}
    local i = 1
    while i <= #xs and x > xs[i] do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    ys[#ys+1] = x
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return L(ys)
end

mt.__index.insert = function(xs, x) return L.insert(x, xs) end

--[[------------------------------------------------------------------------@@@
## Generalized functions
@@@]]

--[[@@@
```lua
L.nubBy(eq, xs)
xs:nubBy(eq)
```
> like nub, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.nubBy(eq, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if eq(x, ys[j]) then found = true; break end
        end
        if not found then ys[#ys+1] = x end
    end
    return L(ys)
end

mt.__index.nubBy = function(xs, eq) return L.nubBy(eq, xs) end

--[[@@@
```lua
L.deleteBy(eq, x, xs)
xs:deleteBy(eq, x)
```
> like delete, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.deleteBy(eq, x, xs)
    local ys = {}
    local i = 1
    while i <= #xs do
        if eq(xs[i], x) then break end
        ys[#ys+1] = xs[i]
        i = i+1
    end
    i = i+1
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return L(ys)
end

mt.__index.deleteBy = function(xs, eq, x) return L.deleteBy(eq, x, xs) end

--[[@@@
```lua
L.differenceBy(eq, xs, ys)
xs:differenceBy(eq, ys)
```
> like difference, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.differenceBy(eq, xs, ys)
    local zs = {}
    ys = {table.unpack(ys)}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if eq(ys[j], x) then
                found = true
                table.remove(ys, j)
                break
            end
        end
        if not found then zs[#zs+1] = x end
    end
    return L(zs)
end

mt.__index.differenceBy = function(xs, eq, ys) return L.differenceBy(eq, xs, ys) end

--[[@@@
```lua
L.unionBy(eq, xs, ys)
xs:unionBy(eq, ys)
```
> like union, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.unionBy(eq, xs, ys)
    local zs = {table.unpack(xs)}
    for i = 1, #ys do
        local y = ys[i]
        local found = false
        for j = 1, #zs do
            if eq(y, zs[j]) then found = true; break end
        end
        if not found then zs[#zs+1] = y end
    end
    return L(zs)
end

mt.__index.unionBy = function(xs, eq, ys) return L.unionBy(eq, xs, ys) end

--[[@@@
```lua
L.intersectBy(eq, xs, ys)
xs:intersectBy(eq, ys)
```
> like intersect, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.intersectBy(eq, xs, ys)
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if eq(x, ys[j]) then found = true; break end
        end
        if found then zs[#zs+1] = x end
    end
    return L(zs)
end

mt.__index.intersectBy = function(xs, eq, ys) return L.intersectBy(eq, xs, ys) end

--[[@@@
```lua
L.groupBy(eq, xs)
xs:groupBy(eq)
```
> like group, except it uses a user-supplied equality predicate instead of the overloaded == function.
@@@]]
function L.groupBy(eq, xs)
    local yss = {}
    if #xs == 0 then return L(yss) end
    local y = xs[1]
    local ys = {y}
    for i = 2, #xs do
        local x = xs[i]
        if eq(x, y) then
            ys[#ys+1] = x
        else
            yss[#yss+1] = ys
            y = x
            ys = {y}
        end
    end
    yss[#yss+1] = ys
    return L(yss)
end

mt.__index.groupBy = function(xs, eq) return L.groupBy(eq, xs) end

--[[@@@
```lua
L.sortBy(le, xs)
xs:sortBy(le)
```
> like sort, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]

function L.sortBy(le, xs)
    local ys = {}
    for i = 1, #xs do ys[i] = xs[i] end
    table.sort(ys, le)
    return L(ys)
end

mt.__index.sortBy = function(xs, le) return L.sortBy(le, xs) end

--[[@@@
```lua
L.insertBy(le, x, xs)
xs:insertBy(le, x)
```
> like insert, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function L.insertBy(le, x, xs)
    local ys = {}
    local i = 1
    while i <= #xs and not le(x, xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    ys[#ys+1] = x
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return L(ys)
end

mt.__index.insertBy = function(xs, eq, x) return L.insertBy(eq, x, xs) end

--[[@@@
```lua
L.maximumBy(le, xs)
xs:maximum(le)
```
> like maximum, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function L.maximumBy(le, xs)
    if #xs == 0 then return nil end
    local max = xs[1]
    for i = 2, #xs do
        if not le(xs[i], max) then max = xs[i] end
    end
    return max
end

mt.__index.maximumBy = function(xs, le) return L.maximumBy(le, xs) end

--[[@@@
```lua
L.minimumBy(le, xs)
xs:minimum(le)
```
> like minimum, except it uses a user-supplied equality predicate instead of the overloaded <= function.
@@@]]
function L.minimumBy(le, xs)
    if #xs == 0 then return nil end
    local min = xs[1]
    for i = 2, #xs do
        if le(xs[i], min) then min = xs[i] end
    end
    return min
end

mt.__index.minimumBy = function(xs, le) return L.minimumBy(le, xs) end

-------------------------------------------------------------------------------
-- List module
-------------------------------------------------------------------------------

return setmetatable(L, {
    __call = function(_, xs) return L.clone(xs) end,
})
