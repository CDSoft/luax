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

[`Data.Map`]: https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html

`Map` is a module inspired by the Haskell module [`Data.Map`].

Note: contrary to the original Haskell modules, all these functions are evaluated strictly
(i.e. no lazy evaluation, no infinite table, ...).

```lua
local M = require "Map"
```
@@@]]

local M = {}

local mt = {
    __index = {},
}

local L = require "List"

--[[------------------------------------------------------------------------@@@
## Construction
@@@]]

--[[@@@
```lua
M.clone(t)
t:clone()
```
> Clone a table
@@@]]

function M.clone(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return setmetatable(t2, mt)
end

mt.__index.clone = M.clone

--[[@@@
```lua
t1 .. t2
```
> Merge two tables
@@@]]
function mt.__concat(t1, t2)
    return M.union(t1, t2)
end

--[[@@@
```lua
M.empty()
```
> The empty map
@@@]]

function M.empty()
    return M{}
end

--[[@@@
```lua
M.singleton(k, v)
```
> A map with a single element.
@@@]]

function M.singleton(k, v)
    return M{[k]=v}
end

--[[@@@
```lua
M.fromSet(f, ks)
```
> Build a map from a set of keys and a function which for each key computes its value.
@@@]]

function M.fromSet(f, ks)
    local t = {}
    for i = 1, #ks do
        local k = ks[i]
        t[k] = f(k)
    end
    return M(t)
end

--[[@@@
```lua
M.fromList(kvs)
```
> Build a map from a list of key/value pairs.
@@@]]

function M.fromList(kvs)
    local t = {}
    for i = 1, #kvs do
        local k, v = table.unpack(kvs[i])
        t[k] = v
    end
    return M(t)
end

--[[------------------------------------------------------------------------@@@
## Deletion / Update
@@@]]

--[[@@@
```lua
M.delete(k, t)
t:delete(k)
```
> Delete a key and its value from the map.
@@@]]

function M.delete(k, t)
    t = M.clone(t)
    t[k] = nil
    return t
end

mt.__index.delete = function(t, k) return M.delete(k, t) end

--[[@@@
```lua
M.adjust(f, k, t)
t:adjust(f, k)
```
> Update a value at a specific key with the result of the provided function. When the key is not a member of the map, the original map is returned.
@@@]]

function M.adjust(f, k, t)
    t = M.clone(t)
    local v = t[k]
    if v ~= nil then t[k] = f(v) end
    return t
end

mt.__index.adjust = function(t, f, k) return M.adjust(f, k, t) end

--[[@@@
```lua
M.adjustWithKey(f, k, t)
t:adjustWithKey(f, k)
```
> Adjust a value at a specific key. When the key is not a member of the map, the original map is returned.
@@@]]

function M.adjustWithKey(f, k, t)
    t = M.clone(t)
    local v = t[k]
    if v ~= nil then t[k] = f(k, v) end
    return t
end

mt.__index.adjustWithKey = function(t, f, k) return M.adjustWithKey(f, k, t) end

--[[@@@
```lua
M.update(f, k, t)
t:update(f, k)
```
> Updates the value x at k (if it is in the map). If f(x) is nil, the element is deleted. Otherwise the key k is bound to the value f(x).
@@@]]

function M.update(f, k, t)
    t = M.clone(t)
    local v = t[k]
    if v ~= nil then t[k] = f(v) end
    return t
end

mt.__index.update = function(t, f, k) return M.update(f, k, t) end

--[[@@@
```lua
M.updateWithKey(f, k, t)
t:updateWithKey(f, k)
```
> Updates the value x at k (if it is in the map). If f(k, x) is nil, the element is deleted. Otherwise the key k is bound to the value f(k, x).
@@@]]

function M.updateWithKey(f, k, t)
    t = M.clone(t)
    local v = t[k]
    if v ~= nil then t[k] = f(k, v) end
    return t
end

mt.__index.updateWithKey = function(t, f, k) return M.updateWithKey(f, k, t) end

--[[@@@
```lua
M.updateLookupWithKey(f, k, t)
t:updateLookupWithKey(f, k)
```
> Lookup and update. See also updateWithKey. The function returns changed value, if it is updated. Returns the original key value if the map entry is deleted.
@@@]]

function M.updateLookupWithKey(f, k, t)
    t = M.clone(t)
    local v = t[k]
    if v ~= nil then
        local new_v = f(k, v)
        t[k] = new_v
        if new_v ~= nil then v = new_v end
    end
    return v, t
end

mt.__index.updateLookupWithKey = function(t, f, k) return M.updateLookupWithKey(f, k, t) end

--[[@@@
```lua
M.alter(f, k, t)
t:alter(f, k)
```
> The expression alter(f, k, t) alters the value x at k, or absence thereof. alter can be used to insert, delete, or update a value in a Map.
@@@]]

function M.alter(f, k, t)
    t = M.clone(t)
    t[k] = f(t[k])
    return t
end

mt.__index.alter = function(t, f, k) return M.alter(f, k, t) end

--[[@@@
```lua
M.alterWithKey(f, k, t)
t:alterWithKey(f, k)
```
> The expression alterWithKey(f, k, t) alters the value x at k, or absence thereof. alterWithKey can be used to insert, delete, or update a value in a Map.
@@@]]

function M.alterWithKey(f, k, t)
    t = M.clone(t)
    t[k] = f(k, t[k])
    return t
end

mt.__index.alterWithKey = function(t, f, k) return M.alterWithKey(f, k, t) end

--[[------------------------------------------------------------------------@@@
## Query
@@@]]

--[[------------------------------------------------------------------------@@@
### Lookup
@@@]]

--[[@@@
```lua
M.lookup(k, t)
t:lookup(k)
```
>  Lookup the value at a key in the map.
@@@]]

function M.lookup(k, t)
    return t[k]
end

mt.__index.lookup = function(t, k) return M.lookup(k, t) end

--[[@@@
```lua
M.findWithDefault(def, k, t)
t:findWithDefault(def, k)
```
> Returns the value at key k or returns default value def when the key is not in the map.
@@@]]

function M.findWithDefault(def, k, t)
    local v = t[k]
    if v == nil then v = def end
    return v
end

mt.__index.findWithDefault = function(t, def, k) return M.findWithDefault(def, k, t) end

--[[@@@
```lua
M.member(k, t)
t:member(k)
```
>  Lookup the value at a key in the map.
@@@]]

function M.member(k, t)
    return t[k] ~= nil
end

mt.__index.member = function(t, k) return M.member(k, t) end

--[[@@@
```lua
M.notMember(k, t)
t:notMember(k)
```
>  Lookup the value at a key in the map.
@@@]]

function M.notMember(k, t)
    return t[k] == nil
end

mt.__index.notMember = function(t, k) return M.notMember(k, t) end

--[[@@@
```lua
M.lookupLT(k, t)
t:lookupLT(k)
```
> Find largest key smaller than the given one and return the corresponding (key, value) pair.
@@@]]

function M.lookupLT(k, t)
    local kmax, vmax = nil, nil
    for ki, vi in pairs(t) do
        if ki < k and (not kmax or ki > kmax) then
            kmax, vmax = ki, vi
        end
    end
    return kmax, vmax
end

mt.__index.lookupLT = function(t, k) return M.lookupLT(k, t) end

--[[@@@
```lua
M.lookupGT(k, t)
t:lookupGT(k)
```
> Find smallest key greater than the given one and return the corresponding (key, value) pair.
@@@]]

function M.lookupGT(k, t)
    local kmin, vmin = nil, nil
    for ki, vi in pairs(t) do
        if ki > k and (not kmin or ki < kmin) then
            kmin, vmin = ki, vi
        end
    end
    return kmin, vmin
end

mt.__index.lookupGT = function(t, k) return M.lookupGT(k, t) end

--[[@@@
```lua
M.lookupLE(k, t)
t:lookupLE(k)
```
> Find largest key smaller or equal to the given one and return the corresponding (key, value) pair.
@@@]]

function M.lookupLE(k, t)
    local kmax, vmax = nil, nil
    for ki, vi in pairs(t) do
        if ki <= k and (not kmax or ki > kmax) then
            kmax, vmax = ki, vi
        end
    end
    return kmax, vmax
end

mt.__index.lookupLE = function(t, k) return M.lookupLE(k, t) end

--[[@@@
```lua
M.lookupGE(k, t)
t:lookupGE(k)
```
> Find smallest key greater or equal to the given one and return the corresponding (key, value) pair.
@@@]]

function M.lookupGE(k, t)
    local kmin, vmin = nil, nil
    for ki, vi in pairs(t) do
        if ki >= k and (not kmin or ki < kmin) then
            kmin, vmin = ki, vi
        end
    end
    return kmin, vmin
end

mt.__index.lookupGE = function(t, k) return M.lookupGE(k, t) end

--[[------------------------------------------------------------------------@@@
### Size
@@@]]

--[[@@@
```lua
M.null(t)
t:null()
```
> Is the map empty?
@@@]]

function M.null(t)
    return next(t) == nil
end

mt.__index.null = M.null

--[[@@@
```lua
M.size(t)
t:size()
```
> The number of elements in the map.
@@@]]

function M.size(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n+1
    end
    return n
end

mt.__index.size = M.size

--[[------------------------------------------------------------------------@@@
## Combine
@@@]]

--[[------------------------------------------------------------------------@@@
### Union
@@@]]

--[[@@@
```lua
M.union(t1, t2)
t1:union(t2)
```
> Left-biased union of t1 and t2. It prefers t1 when duplicate keys are encountered.
@@@]]

function M.union(t1, t2)
    local t = {}
    for k, v in pairs(t1) do t[k] = v end
    for k, v in pairs(t2) do if t1[k] == nil then t[k] = v end end
    return M(t)
end

mt.__index.union = M.union

--[[@@@
```lua
M.unionWith(f, t1, t2)
t1:unionWith(f, t2)
```
> Union with a combining function.
@@@]]

function M.unionWith(f, t1, t2)
    local t = {}
    for k, v in pairs(t1) do t[k] = v end
    for k, v in pairs(t2) do
        if t1[k] == nil then
            t[k] = v
        else
            t[k] = f(t1[k], t2[k])
        end
    end
    return M(t)
end

mt.__index.unionWith = function(t1, f, t2) return M.unionWith(f, t1, t2) end

--[[@@@
```lua
M.unionWithKey(f, t1, t2)
t1:unionWithKey(f, t2)
```
> Union with a combining function.
@@@]]

function M.unionWithKey(f, t1, t2)
    local t = {}
    for k, v in pairs(t1) do t[k] = v end
    for k, v in pairs(t2) do
        if t1[k] == nil then
            t[k] = v
        else
            t[k] = f(k, t1[k], t2[k])
        end
    end
    return M(t)
end

mt.__index.unionWithKey = function(t1, f, t2) return M.unionWithKey(f, t1, t2) end

--[[@@@
```lua
M.unions(ts)
ts:unions()
```
> The union of a list of maps.
@@@]]

function M.unions(ts)
    return L.foldl(M.union, M.empty(), ts)
end

mt.__index.unions = M.unions

--[[@@@
```lua
M.unionsWith(f, ts)
ts:unionsWith(f)
```
> The union of a list of maps, with a combining operation.
@@@]]

function M.unionsWith(f, ts)
    return L.foldl(function(a, b) return M.unionWith(f, a, b) end, M.empty(), ts)
end

mt.__index.unionsWith = function(ts, f) return M.unionsWith(f, ts) end

--[[@@@
```lua
M.unionsWithKey(f, ts)
ts:unionsWithKey(f)
```
> The union of a list of maps, with a combining operation.
@@@]]

function M.unionsWithKey(f, ts)
    return L.foldl(function(a, b) return M.unionWithKey(f, a, b) end, M.empty(), ts)
end

mt.__index.unionsWithKey = function(ts, f) return M.unionsWithKey(f, ts) end

--[[------------------------------------------------------------------------@@@
### Difference
@@@]]

--[[@@@
```lua
M.difference(t1, t2)
t1:difference(t2)
```
> Difference of two maps. Return elements of the first map not existing in the second map.
@@@]]

function M.difference(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] == nil then t[k] = v end end
    return M(t)
end

mt.__index.difference = M.difference

--[[@@@
```lua
M.differenceWith(f, t1, t2)
t1:differenceWith(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

function M.differenceWith(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(v1, v2)
        end
    end
    return M(t)
end

mt.__index.differenceWith = function(t1, f, t2) return M.differenceWith(f, t1, t2) end

--[[@@@
```lua
M.differenceWithKey(f, t1, t2)
t1:differenceWithKey(f, t2)
```
> Union with a combining function.
@@@]]

function M.differenceWithKey(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(k, v1, v2)
        end
    end
    return M(t)
end

mt.__index.differenceWithKey = function(t1, f, t2) return M.differenceWithKey(f, t1, t2) end

--[[------------------------------------------------------------------------@@@
### Intersection
@@@]]

--[[@@@
```lua
M.intersection(t1, t2)
t1:intersection(t2)
```
> Intersection of two maps. Return data in the first map for the keys existing in both maps.
@@@]]

function M.intersection(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] ~= nil then t[k] = v end end
    return M(t)
end

mt.__index.intersection = M.intersection

--[[@@@
```lua
M.intersectionWith(f, t1, t2)
t1:intersectionWith(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

function M.intersectionWith(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(v1, v2)
        end
    end
    return M(t)
end

mt.__index.intersectionWith = function(t1, f, t2) return M.intersectionWith(f, t1, t2) end

--[[@@@
```lua
M.intersectionWithKey(f, t1, t2)
t1:intersectionWithKey(f, t2)
```
> Union with a combining function.
@@@]]

function M.intersectionWithKey(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(k, v1, v2)
        end
    end
    return M(t)
end

mt.__index.intersectionWithKey = function(t1, f, t2) return M.intersectionWithKey(f, t1, t2) end

--[[------------------------------------------------------------------------@@@
### Disjoint
@@@]]

--[[@@@
```lua
M.disjoint(t1, t2)
t1:disjoint(t2)
```
> Intersection of two maps. Return data in the first map for the keys existing in both maps.
@@@]]

function M.disjoint(t1, t2)
    for k, v in pairs(t1) do if t2[k] ~= nil then return false end end
    return true
end

mt.__index.disjoint = M.disjoint

--[[------------------------------------------------------------------------@@@
### Compose
@@@]]

--[[@@@
```lua
M.compose(t1, t2)
t1:compose(t2)
```
> Relate the keys of one map to the values of the other, by using the values of the former as keys for lookups in the latter.
@@@]]

function M.compose(t1, t2)
    local t = {}
    for k2, v2 in pairs(t2) do
        local v1 = t1[v2]
        t[k2] = v1
    end
    return M(t)
end

mt.__index.compose = M.compose

--[[------------------------------------------------------------------------@@@
## Traversal
@@@]]

--[[------------------------------------------------------------------------@@@
### Map
@@@]]

--[[@@@
```lua
M.map(f, t)
t:map(f)
```
> Map a function over all values in the map.
@@@]]

function M.map(f, t)
    local ft = {}
    for k, v in pairs(t) do
        ft[k] = f(v)
    end
    return M(ft)
end

mt.__index.map = function(t, f) return M.map(f, t) end

--[[@@@
```lua
M.mapWithKey(f, t)
t:mapWithKey(f)
```
> Map a function over all values in the map.
@@@]]

function M.mapWithKey(f, t)
    local ft = {}
    for k, v in pairs(t) do
        ft[k] = f(k, v)
    end
    return M(ft)
end

mt.__index.mapWithKey = function(t, f) return M.mapWithKey(f, t) end

--[[------------------------------------------------------------------------@@@
## Folds
@@@]]

--[[@@@
```lua
M.foldr(f, b, t)
t:foldr(f, b)
```
> Fold the values in the map using the given right-associative binary operator.
@@@]]

function M.foldr(fab, b, t)
    local vs = M.elems(t)
    for i = 1, #vs do
        b = fab(vs[i], b)
    end
    return b
end

mt.__index.foldr = function(t, fab, b) return M.foldr(fab, b, t) end

--[[@@@
```lua
M.foldl(f, b, t)
t:foldl(f, b)
```
> Fold the values in the map using the given right-associative binary operator.
@@@]]

function M.foldl(fba, b, t)
    local vs = M.elems(t)
    for i = #vs, 1, -1 do
        b = fba(b, vs[i])
    end
    return b
end

mt.__index.foldl = function(t, fba, b) return M.foldl(fba, b, t) end

--[[@@@
```lua
M.foldrWithKey(f, b, t)
t:foldrWithKey(f, b)
```
> Fold the keys and values in the map using the given right-associative binary operator.
@@@]]

function M.foldrWithKey(fab, b, t)
    local kvs = M.assocs(t)
    for i = 1, #kvs do
        b = fab(kvs[i][1], kvs[i][2], b)
    end
    return b
end

mt.__index.foldrWithKey = function(t, fab, b) return M.foldrWithKey(fab, b, t) end

--[[@@@
```lua
M.foldlWithKey(f, b, t)
t:foldlWithKey(f, b)
```
> Fold the keys and values in the map using the given left-associative binary operator.
@@@]]

function M.foldlWithKey(fba, b, t)
    local kvs = M.assocs(t)
    for i = #kvs, 1, -1 do
        b = fba(b, kvs[i][1], kvs[i][2])
    end
    return b
end

mt.__index.foldlWithKey = function(t, fba, b) return M.foldlWithKey(fba, b, t) end

--[[------------------------------------------------------------------------@@@
## Conversion
@@@]]

--[[@@@
```lua
M.elems(t)
t:elems()
M.values(t)
t:values()
```
> Return all elements of the map in the ascending order of their keys (values is an alias for elems).
@@@]]

function M.elems(t)
    local kvs = M.toAscList(t)
    local vs = {}
    for i = 1, #kvs do vs[#vs+1] = kvs[i][2] end
    return L(vs)
end

mt.__index.elems = M.elems

M.values = M.elems

mt.__index.values = M.values

--[[@@@
```lua
M.keys(t)
t:keys()
```
> Return all keys of the map in ascending order.
@@@]]

function M.keys(t)
    local kvs = M.toAscList(t)
    local ks = {}
    for i = 1, #kvs do ks[#ks+1] = kvs[i][1] end
    return L(ks)
end

mt.__index.keys = M.keys

--[[@@@
```lua
M.assocs(t)
t:assocs()
```
> Return all key/value pairs in the map in ascending key order.
@@@]]

function M.assocs(t)
    return M.toAscList(t)
end

mt.__index.assocs = M.assocs

--[[@@@
```lua
P.pairs(t)
t:pairs()
```
> Like Lua pairs function but iterating on ascending keys
@@@]]

function M.pairs(t)
    local kvs = M.toAscList(t)
    local i = 0
    return function()
        if i < #kvs then
            i = i + 1
            return table.unpack(kvs[i])
        end
    end
end

mt.__index.pairs = M.pairs

--[[------------------------------------------------------------------------@@@
### Lists
@@@]]

--[[@@@
```lua
M.toList(t)
t:toList()
```
> Convert the map to a list of key/value pairs.
@@@]]

function M.toList(t)
    local kvs = {}
    for k, v in pairs(t) do kvs[#kvs+1] = {k, v} end
    return L(kvs)
end

mt.__index.toList = M.toList

--[[------------------------------------------------------------------------@@@
### Ordered lists
@@@]]

--[[@@@
```lua
M.toAscList(t)
t:toAscList()
```
> Convert the map to a list of key/value pairs where the keys are in ascending order.
@@@]]

function M.toAscList(t)
    local kvs = {}
    for k, v in pairs(t) do kvs[#kvs+1] = {k, v} end
    table.sort(kvs, function(kv1, kv2)
        local tk1, tk2 = type(kv1[1]), type(kv2[1])
        if tk1 == tk2 then return kv1[1] < kv2[1] else return tk1 < tk2 end
    end)
    return L(kvs)
end

mt.__index.toAscList = M.toAscList

--[[@@@
```lua
M.toDescList(t)
t:toDescList()
```
> Convert the map to a list of key/value pairs where the keys are in descending order.
@@@]]

function M.toDescList(t)
    local kvs = {}
    for k, v in pairs(t) do kvs[#kvs+1] = {k, v} end
    table.sort(kvs, function(kv1, kv2)
        local tk1, tk2 = type(kv1[1]), type(kv2[1])
        if tk1 == tk2 then return kv2[1] < kv1[1] else return tk2 < tk1 end
    end)
    return L(kvs)
end

mt.__index.toDescList = M.toDescList

--[[------------------------------------------------------------------------@@@
## Filter
@@@]]

--[[@@@
```lua
M.filter(p, t)
t:filter(p)
```
> Filter all values that satisfy the predicate.
@@@]]

function M.filter(p, t)
    local ft = {}
    for k, v in pairs(t) do
        if p(v) then ft[k] = v end
    end
    return M(ft)
end

mt.__index.filter = function(t, p) return M.filter(p, t) end

--[[@@@
```lua
M.filterWithKey(p, t)
t:filterWithKey(p)
```
> Filter all values that satisfy the predicate.
@@@]]

function M.filterWithKey(p, t)
    local ft = {}
    for k, v in pairs(t) do
        if p(k, v) then ft[k] = v end
    end
    return M(ft)
end

mt.__index.filterWithKey = function(t, p) return M.filterWithKey(p, t) end

--[[@@@
```lua
M.restrictKeys(t, ks)
t:restrictKeys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

function M.restrictKeys(t, ks)
    local kset = M.fromSet(function(k) return true end, ks)
    local function p(k, v) return kset[k] end
    return M.filterWithKey(p, t)
end

mt.__index.restrictKeys = M.restrictKeys

--[[@@@
```lua
M.withoutKeys(t, ks)
t:withoutKeys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

function M.withoutKeys(t, ks)
    local kset = M.fromSet(function(k) return true end, ks)
    local function p(k, v) return not kset[k] end
    return M.filterWithKey(p, t)
end

mt.__index.withoutKeys = M.withoutKeys

--[[@@@
```lua
M.partition(p, t)
t:partition(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

function M.partition(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(v) then t1[k] = v else t2[k] = v end
    end
    return M(t1), M(t2)
end

mt.__index.partition = function(t, p) return M.partition(p, t) end

--[[@@@
```lua
M.partitionWithKey(p, t)
t:partitionWithKey(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

function M.partitionWithKey(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(k, v) then t1[k] = v else t2[k] = v end
    end
    return M(t1), M(t2)
end

mt.__index.partitionWithKey = function(t, p) return M.partitionWithKey(p, t) end

--[[@@@
```lua
M.mapEither(f, t)
t:mapEither(f)
```
> Map values and separate the left and right results.
@@@]]

function M.mapEither(f, t)
    local left, right = {}, {}
    for k, v in pairs(t) do
        left[k], right[k] = f(v)
    end
    return M(left), M(right)
end

mt.__index.mapEither = function(t, f) return M.mapEither(f, t) end

--[[@@@
```lua
M.mapEitherWithKey(f, t)
t:mapEitherWithKey(f)
```
> Map keys/values and separate the left and right results.
@@@]]

function M.mapEitherWithKey(f, t)
    local left, right = {}, {}
    for k, v in pairs(t) do
        left[k], right[k] = f(k, v)
    end
    return M(left), M(right)
end

mt.__index.mapEitherWithKey = function(t, f) return M.mapEitherWithKey(f, t) end

--[[@@@
```lua
M.split(k, t)
t:split(k)
```
> pair (map1,map2) where the keys in map1 are smaller than k and the keys in map2 larger than k. Any key equal to k is found in neither map1 nor map2.
@@@]]

function M.split(k0, t)
    local function f(k, v)
        if k < k0 then return v, nil end
        if k > k0 then return nil, v end
    end
    return M.mapEitherWithKey(f, t)
end

mt.__index.split = function(t, k) return M.split(k, t) end

--[[@@@
```lua
M.splitLookup(k, t)
t:splitLookup(k)
```
> splits a map just like split but also returns lookup(k, t).
@@@]]

function M.splitLookup(k0, t)
    local function f(k, v)
        if k < k0 then return v, nil end
        if k > k0 then return nil, v end
    end
    local smaller, larger = M.mapEitherWithKey(f, t)
    return smaller, M.lookup(k0, t), larger
end

mt.__index.splitLookup = function(t, k) return M.splitLookup(k, t) end

--[[------------------------------------------------------------------------@@@
## Submap
@@@]]

--[[@@@
```lua
M.isSubmapOf(t1, t2)
t1:isSubmapOf(t2)
```
> returns true if all keys in t1 are in t2.
@@@]]

function M.isSubmapOf(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    return true
end

mt.__index.isSubmapOf = M.isSubmapOf

--[[@@@
```lua
M.isSubmapOfBy(f, t1, t2)
t1:isSubmapOfBy(f, t2)
```
> returns true if all keys in t1 are in t2, and when f returns frue when applied to their respective values.
@@@]]

function M.isSubmapOfBy(f, t1, t2)
    for k, v in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil or not f(v, v2) then return false end
    end
    return true
end

mt.__index.isSubmapOfBy = function(t1, f, t2) return M.isSubmapOfBy(f, t1, t2) end

--[[@@@
```lua
M.isProperSubmapOf(t1, t2)
t1:isProperSubmapOf(t2)
```
> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are different.
@@@]]

function M.isProperSubmapOf(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] == nil then return true end
    end
    return false
end

mt.__index.isProperSubmapOf = M.isProperSubmapOf

--[[@@@
```lua
M.isProperSubmapOfBy(f, t1, t2)
t1:isProperSubmapOfBy(f, t2)
```
> returns true when t1 and t2 keys are not equal, all keys in t1 are in t2, and when f returns true when applied to their respective values.
@@@]]

function M.isProperSubmapOfBy(f, t1, t2)
    for k, v in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil or not f(v, v2) then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] == nil then return true end
    end
    return false
end

mt.__index.isProperSubmapOfBy = function(t1, f, t2) return M.isProperSubmapOfBy(f, t1, t2) end

--[[------------------------------------------------------------------------@@@
## Min/Max
@@@]]

--[[@@@
```lua
M.lookupMin(t)
t:lookupMin()
```
> The minimal key of the map and its value.
@@@]]

function M.lookupMin(t)
    local kmin, vmin = nil, nil
    for k, v in pairs(t) do
        if kmin == nil or k < kmin then
            kmin, vmin = k, v
        end
    end
    return kmin, vmin
end

mt.__index.lookupMin = M.lookupMin

--[[@@@
```lua
M.lookupMax(t)
t:lookupMax()
```
> The maximal key of the map and its value.
@@@]]

function M.lookupMax(t)
    local kmax, vmax = nil, nil
    for k, v in pairs(t) do
        if kmax == nil or k > kmax then
            kmax, vmax = k, v
        end
    end
    return kmax, vmax
end

mt.__index.lookupMax = M.lookupMax

--[[@@@
```lua
M.deleteMin(t)
t:deleteMin()
```
> Delete the minimal key. Returns an empty map if the map is empty.
@@@]]

function M.deleteMin(t)
    local t2 = M.clone(t)
    local kmin = M.lookupMin(t)
    if kmin ~= nil then t2[kmin] = nil end
    return t2
end

mt.__index.deleteMin = M.deleteMin

--[[@@@
```lua
M.deleteMax(t)
t:deleteMax()
```
> Delete the maximal key. Returns an empty map if the map is empty.
@@@]]

function M.deleteMax(t)
    local t2 = M.clone(t)
    local kmax = M.lookupMax(t)
    if kmax ~= nil then t2[kmax] = nil end
    return t2
end

mt.__index.deleteMax = M.deleteMax

--[[@@@
```lua
M.deleteFindMin(t)
t:deleteFindMin()
```
> Delete and find the minimal element.
@@@]]

function M.deleteFindMin(t)
    local t2 = M.clone(t)
    local kmin, vmin = M.lookupMin(t)
    if kmin ~= nil then t2[kmin] = nil end
    return kmin, vmin, t2
end

mt.__index.deleteFindMin = M.deleteFindMin

--[[@@@
```lua
M.deleteFindMax(t)
t:deleteFindMax()
```
> Delete and find the maximal element.
@@@]]

function M.deleteFindMax(t)
    local t2 = M.clone(t)
    local kmax, vmax = M.lookupMax(t)
    if kmax ~= nil then t2[kmax] = nil end
    return kmax, vmax, t2
end

mt.__index.deleteFindMax = M.deleteFindMax

--[[@@@
```lua
M.updateMin(f, t)
t:updateMin(f)
```
> Update the value at the minimal key.
@@@]]

function M.updateMin(f, t)
    local t2 = M.clone(t)
    local kmin, vmin = M.lookupMin(t)
    if kmin ~= nil then t2[kmin] = f(vmin) end
    return t2
end

mt.__index.updateMin = function(t, f) return M.updateMin(f, t) end

--[[@@@
```lua
M.updateMax(f, t)
t:updateMax(f)
```
> Update the value at the maximal key.
@@@]]

function M.updateMax(f, t)
    local t2 = M.clone(t)
    local kmax, vmax = M.lookupMax(t)
    if kmax ~= nil then t2[kmax] = f(vmax) end
    return t2
end

mt.__index.updateMax = function(t, f) return M.updateMax(f, t) end

--[[@@@
```lua
M.updateMinWithKey(f, t)
t:updateMinWithKey(f)
```
> Update the value at the minimal key.
@@@]]

function M.updateMinWithKey(f, t)
    local t2 = M.clone(t)
    local kmin, vmin = M.lookupMin(t)
    if kmin ~= nil then t2[kmin] = f(kmin, vmin) end
    return t2
end

mt.__index.updateMinWithKey = function(t, f) return M.updateMinWithKey(f, t) end

--[[@@@
```lua
M.updateMaxWithKey(f, t)
t:updateMaxWithKey(f)
```
> Update the value at the maximal key.
@@@]]

function M.updateMaxWithKey(f, t)
    local t2 = M.clone(t)
    local kmax, vmax = M.lookupMax(t)
    if kmax ~= nil then t2[kmax] = f(kmax, vmax) end
    return t2
end

mt.__index.updateMaxWithKey = function(t, f) return M.updateMaxWithKey(f, t) end

--[[@@@
```lua
M.minView(t)
t:minView()
```
> Retrieves the value associated with minimal key of the map, and the map stripped of that element, or nil if passed an empty map.
@@@]]

function M.minView(t)
    local k, v, t2 = M.deleteFindMin(t)
    if k == nil then return nil end
    return v, t2
end

mt.__index.minView = M.minView

--[[@@@
```lua
M.maxView(t)
t:maxView()
```
> Retrieves the value associated with maximal key of the map, and the map stripped of that element, or nil if passed an empty map.
@@@]]

function M.maxView(t)
    local k, v, t2 = M.deleteFindMax(t)
    if k == nil then return nil end
    return v, t2
end

mt.__index.maxView = M.maxView

--[[@@@
```lua
M.minViewWithKey(t)
t:minViewWithKey()
```
> Retrieves the minimal (key,value) pair of the map, and the map stripped of that element, or Nothing if passed an empty map.
@@@]]

function M.minViewWithKey(t)
    local k, v, t2 = M.deleteFindMin(t)
    if k == nil then return nil end
    return k, v, t2
end

mt.__index.minViewWithKey = M.minViewWithKey

--[[@@@
```lua
M.maxViewWithKey(t)
t:maxViewWithKey()
```
> Retrieves the maximal (key,value) pair of the map, and the map stripped of that element, or Nothing if passed an empty map.
@@@]]

function M.maxViewWithKey(t)
    local k, v, t2 = M.deleteFindMax(t)
    if k == nil then return nil end
    return k, v, t2
end

mt.__index.maxViewWithKey = M.maxViewWithKey

-------------------------------------------------------------------------------
-- Map module
-------------------------------------------------------------------------------

return setmetatable(M, {
    __call = function(_, t) return M.clone(t) end,
})
