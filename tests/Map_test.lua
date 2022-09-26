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

local M = require "Map"

---------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------

local function construction()
    -- clone
    do
        local t1 = M{a="A", b="B", c="C"}
        local t2 = M.clone(t1)
        eq(t1, t2)
        ne(tostring(t1), tostring(t2))
        local t3 = t1:clone()
        eq(t1, t3)
        ne(tostring(t1), tostring(t3))
    end
    -- empty
    do
        eq(M.empty(), {})
    end
    -- singleton
    do
        eq(M.singleton("answer", 42), {answer=42})
    end
    -- fromSet
    do
        eq(M.fromSet(function(k) return k:upper() end, {"a","b","c"}), {a="A", b="B", c="C"})
    end
    -- fromList
    do
        eq(M.fromList({{"a","A"},{"b","B"},{"c","C"}}), {a="A", b="B", c="C"})
    end
end

---------------------------------------------------------------------
-- Deletion / Update
---------------------------------------------------------------------

local function deletion_update()
    -- delete
    do
        eq(M.delete("b", {a="A", b="B", c="C"}), {a="A", c="C"})
        eq(M{a="A", b="B", c="C"}:delete"b", {a="A", c="C"})
    end
    -- adjust
    do
        eq(M.adjust(string.lower, "b", {a="A", b="B", c="C"}), {a="A", b="b", c="C"})
        eq(M.adjust(string.lower, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C"})
        eq(M{a="A", b="B", c="C"}:adjust(string.lower, "b"), {a="A", b="b", c="C"})
        eq(M{a="A", b="B", c="C"}:adjust(string.lower, "z"), {a="A", b="B", c="C"})
    end
    -- adjustWithKey
    do
        local function cat(x, y) return x..y end
        eq(M.adjustWithKey(cat, "b", {a="A", b="B", c="C"}), {a="A", b="bB", c="C"})
        eq(M.adjustWithKey(cat, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C"})
        eq(M{a="A", b="B", c="C"}:adjustWithKey(cat, "b"), {a="A", b="bB", c="C"})
        eq(M{a="A", b="B", c="C"}:adjustWithKey(cat, "z"), {a="A", b="B", c="C"})
    end
    -- update
    do
        local clean = function(_) return nil end
        eq(M.update(string.lower, "b", {a="A", b="B", c="C"}), {a="A", b="b", c="C"})
        eq(M.update(string.lower, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C"})
        eq(M.update(clean, "b", {a="A", b="B", c="C"}), {a="A", c="C"})
        eq(M{a="A", b="B", c="C"}:update(string.lower, "b"), {a="A", b="b", c="C"})
        eq(M{a="A", b="B", c="C"}:update(string.lower, "z"), {a="A", b="B", c="C"})
        eq(M{a="A", b="B", c="C"}:update(clean, "b"), {a="A", c="C"})
    end
    -- updateWithKey
    do
        local function cat(x, y) return x..y end
        local clean = function(_) return nil end
        eq({M.updateLookupWithKey(cat, "b", {a="A", b="B", c="C"})}, {"bB", {a="A", b="bB", c="C"}})
        eq({M.updateLookupWithKey(cat, "z", {a="A", b="B", c="C"})}, {nil, {a="A", b="B", c="C"}})
        eq({M.updateLookupWithKey(clean, "b", {a="A", b="B", c="C"})}, {"B", {a="A", c="C"}})
        eq({M{a="A", b="B", c="C"}:updateLookupWithKey(cat, "b")}, {"bB", {a="A", b="bB", c="C"}})
        eq({M{a="A", b="B", c="C"}:updateLookupWithKey(cat, "z")}, {nil, {a="A", b="B", c="C"}})
        eq({M{a="A", b="B", c="C"}:updateLookupWithKey(clean, "b")}, {"B", {a="A", c="C"}})
    end
    -- alter
    do
        local lower = function(s) return s and s:lower() or "?" end
        local clean = function(_) return nil end
        eq(M.alter(lower, "b", {a="A", b="B", c="C"}), {a="A", b="b", c="C"})
        eq(M.alter(lower, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C",z="?"})
        eq(M.alter(clean, "b", {a="A", b="B", c="C"}), {a="A", c="C"})
        eq(M{a="A", b="B", c="C"}:alter(lower, "b"), {a="A", b="b", c="C"})
        eq(M{a="A", b="B", c="C"}:alter(lower, "z"), {a="A", b="B", c="C",z="?"})
        eq(M{a="A", b="B", c="C"}:alter(clean, "b"), {a="A", c="C"})
    end
    -- alterWithKey
    do
        local function cat(x, y) return x..tostring(y) end
        local clean = function(_) return nil end
        eq(M.alterWithKey(cat, "b", {a="A", b="B", c="C"}), {a="A", b="bB", c="C"})
        eq(M.alterWithKey(cat, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C",z="znil"})
        eq(M.alterWithKey(clean, "b", {a="A", b="B", c="C"}), {a="A", c="C"})
        eq(M{a="A", b="B", c="C"}:alterWithKey(cat, "b"), {a="A", b="bB", c="C"})
        eq(M{a="A", b="B", c="C"}:alterWithKey(cat, "z"), {a="A", b="B", c="C",z="znil"})
        eq(M{a="A", b="B", c="C"}:alterWithKey(clean, "b"), {a="A", c="C"})
    end
end

---------------------------------------------------------------------
-- Lookup
---------------------------------------------------------------------

local function lookup()
    -- lookup
    do
        eq(M.lookup("b", {a="A", b="B", c="C"}), "B")
        eq(M.lookup("z", {a="A", b="B", c="C"}), nil)
        eq(M{a="A", b="B", c="C"}:lookup("b"), "B")
        eq(M{a="A", b="B", c="C"}:lookup("z"), nil)
    end
    -- findWithDefault
    do
        eq(M.findWithDefault("def", "b", {a="A", b="B", c="C"}), "B")
        eq(M.findWithDefault("def", "z", {a="A", b="B", c="C"}), "def")
        eq(M{a="A", b="B", c="C"}:findWithDefault("def", "b"), "B")
        eq(M{a="A", b="B", c="C"}:findWithDefault("def", "z"), "def")
    end
    -- member
    do
        eq(M.member("b", {a="A", b="B", c="C"}), true)
        eq(M.member("z", {a="A", b="B", c="C"}), false)
        eq(M{a="A", b="B", c="C"}:member("b"), true)
        eq(M{a="A", b="B", c="C"}:member("z"), false)
    end
    -- notMember
    do
        eq(M.notMember("b", {a="A", b="B", c="C"}), false)
        eq(M.notMember("z", {a="A", b="B", c="C"}), true)
        eq(M{a="A", b="B", c="C"}:notMember("b"), false)
        eq(M{a="A", b="B", c="C"}:notMember("z"), true)
    end
    -- lookupLT
    do
        eq({M.lookupLT("b", {a="A", b="B", c="C"})}, {"a","A"})
        eq({M.lookupLT("z", {a="A", b="B", c="C"})}, {"c","C"})
        eq({M.lookupLT("0", {a="A", b="B", c="C"})}, {})
        eq({M{a="A", b="B", c="C"}:lookupLT("b")}, {"a","A"})
        eq({M{a="A", b="B", c="C"}:lookupLT("z")}, {"c","C"})
        eq({M{a="A", b="B", c="C"}:lookupLT("0")}, {})
    end
    -- lookupGT
    do
        eq({M.lookupGT("b", {a="A", b="B", c="C"})}, {"c","C"})
        eq({M.lookupGT("z", {a="A", b="B", c="C"})}, {})
        eq({M.lookupGT("0", {a="A", b="B", c="C"})}, {"a","A"})
        eq({M{a="A", b="B", c="C"}:lookupGT("b")}, {"c","C"})
        eq({M{a="A", b="B", c="C"}:lookupGT("z")}, {})
        eq({M{a="A", b="B", c="C"}:lookupGT("0")}, {"a","A"})
    end
    -- lookupLE
    do
        eq({M.lookupLE("b", {a="A", b="B", c="C"})}, {"b","B"})
        eq({M.lookupLE("z", {a="A", b="B", c="C"})}, {"c","C"})
        eq({M.lookupLE("0", {a="A", b="B", c="C"})}, {})
        eq({M{a="A", b="B", c="C"}:lookupLE("b")}, {"b","B"})
        eq({M{a="A", b="B", c="C"}:lookupLE("z")}, {"c","C"})
        eq({M{a="A", b="B", c="C"}:lookupLE("0")}, {})
    end
    -- lookupGE
    do
        eq({M.lookupGE("b", {a="A", b="B", c="C"})}, {"b","B"})
        eq({M.lookupGE("z", {a="A", b="B", c="C"})}, {})
        eq({M.lookupGE("0", {a="A", b="B", c="C"})}, {"a","A"})
        eq({M{a="A", b="B", c="C"}:lookupGE("b")}, {"b","B"})
        eq({M{a="A", b="B", c="C"}:lookupGE("z")}, {})
        eq({M{a="A", b="B", c="C"}:lookupGE("0")}, {"a","A"})
    end
end

---------------------------------------------------------------------
-- Size
---------------------------------------------------------------------

local function size()
    -- null
    do
        eq(M.null{}, true)
        eq(M.null{x=nil}, true)
        eq(M.null{x=1}, false)
        eq(M{}:null(), true)
        eq(M{x=nil}:null(), true)
        eq(M{x=1}:null(), false)
    end
    -- size
    do
        eq(M.size{}, 0)
        eq(M.size{x=nil}, 0)
        eq(M.size{x=1}, 1)
        eq(M.size{x=1,y=2}, 2)
        eq(M{}:size(), 0)
        eq(M{x=nil}:size(), 0)
        eq(M{x=1}:size(), 1)
        eq(M{x=1,y=2}:size(), 2)
    end
end

---------------------------------------------------------------------
-- Union
---------------------------------------------------------------------

local function union()
    -- union
    do
        eq(M.union({x=1,y=2}, {y=3,z=4}), {x=1,y=2,z=4})
        eq(M{x=1,y=2}:union({y=3,z=4}), {x=1,y=2,z=4})
        eq(M{x=1,y=2}..M{y=3,z=4}, {x=1,y=2,z=4})
    end
    -- unionWith
    do
        local add = function(a, b) return a+b end
        eq(M.unionWith(add, {x=1,y=2}, {y=3,z=4}), {x=1,y=5,z=4})
        eq(M{x=1,y=2}:unionWith(add, {y=3,z=4}), {x=1,y=5,z=4})
    end
    -- unionWithKey
    do
        local add = function(k, a, b) return k..(a+b) end
        eq(M.unionWithKey(add, {x=1,y=2}, {y=3,z=4}), {x=1,y="y5",z=4})
        eq(M{x=1,y=2}:unionWithKey(add, {y=3,z=4}), {x=1,y="y5",z=4})
    end
    -- unions
    do
        eq(M.unions{{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}, {x=1,y=2,z=4,t=6})
        eq(M{{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}:unions(), {x=1,y=2,z=4,t=6})
    end
    -- unionsWith
    do
        local add = function(a, b) return a+b end
        eq(M.unionsWith(add, {{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}), {x=1,y=5,z=9,t=6})
        eq(M{{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}:unionsWith(add), {x=1,y=5,z=9,t=6})
    end
    -- unionsWithKey
    do
        local add = function(k, a, b) return k..(a+b) end
        eq(M.unionsWithKey(add, {{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}), {x=1,y="y5",z="z9",t=6})
        eq(M{{x=1,y=2}, {y=3,z=4}, {z=5,t=6}}:unionsWithKey(add), {x=1,y="y5",z="z9",t=6})
    end
end

---------------------------------------------------------------------
-- Difference
---------------------------------------------------------------------

local function difference()
    -- difference
    do
        eq(M.difference({x=1,y=2}, {y=3,z=4}), {x=1})
        eq(M{x=1,y=2}:difference({y=3,z=4}), {x=1})
    end
    -- differenceWith
    do
        local sub = function(a, b) return a-b end
        eq(M.differenceWith(sub, {x=1,y=2}, {y=3,z=4}), {x=1,y=-1})
        eq(M{x=1,y=2}:differenceWith(sub, {y=3,z=4}), {x=1,y=-1})
    end
    -- differenceWithKey
    do
        local sub = function(k, a, b) return k..(a-b) end
        eq(M.differenceWithKey(sub, {x=1,y=2}, {y=3,z=4}), {x=1,y="y-1"})
        eq(M{x=1,y=2}:differenceWithKey(sub, {y=3,z=4}), {x=1,y="y-1"})
    end
end

---------------------------------------------------------------------
-- Intersection
---------------------------------------------------------------------

local function intersection()
    -- intersection
    do
        eq(M.intersection({x=1,y=2}, {y=3,z=4}), {y=2})
        eq(M{x=1,y=2}:intersection({y=3,z=4}), {y=2})
    end
    -- intersectionWith
    do
        local add = function(a, b) return a+b end
        eq(M.intersectionWith(add, {x=1,y=2}, {y=3,z=4}), {y=5})
        eq(M{x=1,y=2}:intersectionWith(add, {y=3,z=4}), {y=5})
    end
    -- intersectionWithKey
    do
        local add = function(k, a, b) return k..(a+b) end
        eq(M.intersectionWithKey(add, {x=1,y=2}, {y=3,z=4}), {y="y5"})
        eq(M{x=1,y=2}:intersectionWithKey(add, {y=3,z=4}), {y="y5"})
    end
end

---------------------------------------------------------------------
-- Disjoint
---------------------------------------------------------------------

local function disjoint()
    -- disjoint
    do
        eq(M.disjoint({x=1,y=2}, {y=3,z=4}), false)
        eq(M{x=1,y=2}:disjoint({y=3,z=4}), false)
        eq(M.disjoint({x=1,y=2}, {t=3,z=4}), true)
        eq(M{x=1,y=2}:disjoint({t=3,z=4}), true)
    end
end

---------------------------------------------------------------------
-- Compose
---------------------------------------------------------------------

local function compose()
    -- compose
    do
        eq(M.compose({a=1,b=2}, {x="a", y="b", z="c"}), {x=1, y=2})
        eq(M{a=1,b=2}:compose{x="a", y="b", z="c"}, {x=1, y=2})
    end
end

---------------------------------------------------------------------
-- Map
---------------------------------------------------------------------

local function map()
    -- map
    do
        local inc = function(a) return a+1 end
        eq(M.map(inc, {x=1,y=2}), {x=2,y=3})
        eq(M{x=1,y=2}:map(inc), {x=2,y=3})
    end
    -- mapWithKey
    do
        local inc = function(k, a) return k..(a+1) end
        eq(M.mapWithKey(inc, {x=1,y=2}), {x="x2",y="y3"})
        eq(M{x=1,y=2}:mapWithKey(inc), {x="x2",y="y3"})
    end
end

---------------------------------------------------------------------
-- Folds
---------------------------------------------------------------------

local function folds()
    -- foldr
    do
        local function f(a, len) return len + #a end
        eq(M.foldr(f, 0, {x="a", y="bbb"}), 4)
        eq(M{x="a", y="bbb"}:foldr(f, 0), 4)
    end
    -- foldl
    do
        local function f(len, a) return len + #a end
        eq(M.foldl(f, 0, {x="a", y="bbb"}), 4)
        eq(M{x="a", y="bbb"}:foldl(f, 0), 4)
    end
    -- foldrWithKey
    do
        local function f(k, a, res) return res..k..a end
        eq(M.foldrWithKey(f, "Map:", {x="a", y="bbb"}), "Map:xaybbb")
        eq(M{x="a", y="bbb"}:foldrWithKey(f, "Map:"), "Map:xaybbb")
    end
    -- foldlWithKey
    do
        local function f(res, k, a) return res..k..a end
        eq(M.foldlWithKey(f, "Map:", {x="a", y="bbb"}), "Map:ybbbxa")
        eq(M{x="a", y="bbb"}:foldlWithKey(f, "Map:"), "Map:ybbbxa")
    end
end

---------------------------------------------------------------------
-- Conversion
---------------------------------------------------------------------

local function conversion()
    -- elems
    do
        eq(M.elems{x=1, y=2}, {1, 2})
        eq(M{x=1, y=2}:elems(), {1, 2})
        eq(M.values{x=1, y=2}, {1, 2})
        eq(M{x=1, y=2}:values(), {1, 2})
    end
    -- keys
    do
        eq(M.keys{x=1, y=2}, {"x", "y"})
        eq(M{x=1, y=2}:keys(), {"x", "y"})
    end
    -- assocs
    do
        eq(M.assocs{x=1, y=2}, {{"x",1}, {"y",2}})
        eq(M{x=1, y=2}:assocs(), {{"x",1}, {"y",2}})
    end
    -- pairs
    do
        local l = {}
        for k, v in M.pairs{x=1, y=2} do
            table.insert(l, {k, v})
        end
        eq(l, {{"x",1}, {"y",2}})
        local l = {}
        for k, v in M{x=1, y=2}:pairs() do
            table.insert(l, {k, v})
        end
        eq(l, {{"x",1}, {"y",2}})
    end
    -- toList
    do
        local function fst(kv) return kv[1] end
        eq(M.toList{x=1, y=2}:sortOn(fst), {{"x",1}, {"y",2}})
        eq(M{x=1, y=2}:toList():sortOn(fst), {{"x",1}, {"y",2}})
    end
    -- toAscList
    do
        eq(M.toAscList{x=1, y=2}, {{"x",1}, {"y",2}})
        eq(M{x=1, y=2}:toAscList(), {{"x",1}, {"y",2}})
    end
    -- toDescList
    do
        eq(M.toDescList{x=1, y=2}, {{"y",2}, {"x",1}})
        eq(M{x=1, y=2}:toDescList(), {{"y",2}, {"x",1}})
    end
end

---------------------------------------------------------------------
-- Filter
---------------------------------------------------------------------

local function filter()
    -- filter
    do
        local function gt(x) return function(y) return y > x end end
        eq(M.filter(gt"a", {x="a", y="b"}), {y="b"})
        eq(M.filter(gt"b", {x="a", y="b"}), {})
        eq(M{x="a", y="b"}:filter(gt"a"), {y="b"})
        eq(M{x="a", y="b"}:filter(gt"b"), {})
    end
    -- filterWithKey
    do
        local function gt(x) return function(k, v) return k > x end end
        eq(M.filterWithKey(gt"x", {x="a", y="b"}), {y="b"})
        eq(M.filterWithKey(gt"y", {x="a", y="b"}), {})
        eq(M{x="a", y="b"}:filterWithKey(gt"x"), {y="b"})
        eq(M{x="a", y="b"}:filterWithKey(gt"y"), {})
    end
    -- restrictKeys
    do
        eq(M.restrictKeys({x=1,y=2}, {"y", "z"}), {y=2})
        eq(M{x=1,y=2}:restrictKeys{"y", "z"}, {y=2})
    end
    -- withoutKeys
    do
        eq(M.withoutKeys({x=1,y=2}, {"y", "z"}), {x=1})
        eq(M{x=1,y=2}:withoutKeys{"y", "z"}, {x=1})
    end
    -- partition
    do
        local function gt(x) return function(y) return y > x end end
        eq({M.partition(gt(1), {x=1,y=2})}, {{y=2},{x=1}})
        eq({M{x=1,y=2}:partition(gt(1))}, {{y=2},{x=1}})
    end
    -- partitionWithKey
    do
        local function gt(x) return function(k, v) return k > x end end
        eq({M.partitionWithKey(gt"x", {x=1,y=2})}, {{y=2},{x=1}})
        eq({M{x=1,y=2}:partitionWithKey(gt"x")}, {{y=2},{x=1}})
    end
    -- mapEither
    do
        local function f(v) if v%2 == 0 then return v, nil else return nil, v end end
        eq({M.mapEither(f, {x=1,y=2})}, {{y=2},{x=1}})
        eq({M{x=1,y=2}:mapEither(f)}, {{y=2},{x=1}})
    end
    -- mapEitherWithKey
    do
        local function f(k, v) if v%2 == 0 then return k..v, nil else return nil, k..v end end
        eq({M.mapEitherWithKey(f, {x=1,y=2})}, {{y="y2"},{x="x1"}})
        eq({M{x=1,y=2}:mapEitherWithKey(f)}, {{y="y2"},{x="x1"}})
    end
    -- split
    do
        eq({M.split("y", {x=1,y=2,z=3})}, {{x=1},{z=3}})
        eq({M{x=1,y=2,z=3}:split"y"}, {{x=1},{z=3}})
    end
    -- splitLookup
    do
        eq({M.splitLookup("y", {x=1,y=2,z=3})}, {{x=1},2,{z=3}})
        eq({M{x=1,y=2,z=3}:splitLookup"y"}, {{x=1},2,{z=3}})
    end
end

---------------------------------------------------------------------
-- Submap
---------------------------------------------------------------------

local function submap()
    -- isSubmapOf
    do
        eq(M.isSubmapOf({x=1,y=2}, {x=1,y=2,z=3}), true)
        eq(M.isSubmapOf({x=1,y=3}, {x=1,y=2,z=3}), false)
        eq(M.isSubmapOf({x=1,y=2}, {x=1,z=3}), false)
        eq(M{x=1,y=2}:isSubmapOf{x=1,y=2,z=3}, true)
        eq(M{x=1,y=3}:isSubmapOf{x=1,y=2,z=3}, false)
        eq(M{x=1,y=2}:isSubmapOf{x=1,z=3}, false)
    end
    -- isSubmapOfBy
    do
        local eqmod2 = function(a, b) return a%2 == b%2 end
        eq(M.isSubmapOfBy(eqmod2, {x=1,y=2}, {x=1,y=4,z=3}), true)
        eq(M.isSubmapOfBy(eqmod2, {x=1,y=3}, {x=1,y=4,z=3}), false)
        eq(M.isSubmapOfBy(eqmod2, {x=1,y=2}, {x=1,z=3}), false)
        eq(M{x=1,y=2}:isSubmapOfBy(eqmod2, {x=1,y=4,z=3}), true)
        eq(M{x=1,y=3}:isSubmapOfBy(eqmod2, {x=1,y=4,z=3}), false)
        eq(M{x=1,y=2}:isSubmapOfBy(eqmod2, {x=1,z=3}), false)
    end
    -- isProperSubmapOf
    do
        eq(M.isProperSubmapOf({x=1,y=2}, {x=1,y=2,z=3}), true)
        eq(M.isProperSubmapOf({x=1,y=2}, {x=1,y=2}), false)
        eq(M.isProperSubmapOf({x=1,y=3}, {x=1,y=2,z=3}), false)
        eq(M.isProperSubmapOf({x=1,y=2}, {x=1,z=3}), false)
        eq(M{x=1,y=2}:isProperSubmapOf{x=1,y=2,z=3}, true)
        eq(M{x=1,y=2}:isProperSubmapOf{x=1,y=2}, false)
        eq(M{x=1,y=3}:isProperSubmapOf{x=1,y=2,z=3}, false)
        eq(M{x=1,y=2}:isProperSubmapOf{x=1,z=3}, false)
    end
    -- isProperSubmapOfBy
    do
        local eqmod2 = function(a, b) return a%2 == b%2 end
        eq(M.isProperSubmapOfBy(eqmod2, {x=1,y=2}, {x=1,y=4,z=3}), true)
        eq(M.isProperSubmapOfBy(eqmod2, {x=1,y=2}, {x=1,y=4}), false)
        eq(M.isProperSubmapOfBy(eqmod2, {x=1,y=3}, {x=1,y=2,z=3}), false)
        eq(M.isProperSubmapOfBy(eqmod2, {x=1,y=2}, {x=1,z=3}), false)
        eq(M{x=1,y=2}:isProperSubmapOfBy(eqmod2, {x=1,y=4,z=3}), true)
        eq(M{x=1,y=2}:isProperSubmapOfBy(eqmod2, {x=1,y=4}), false)
        eq(M{x=1,y=3}:isProperSubmapOfBy(eqmod2, {x=1,y=2,z=3}), false)
        eq(M{x=1,y=2}:isProperSubmapOfBy(eqmod2, {x=1,z=3}), false)
    end
end

---------------------------------------------------------------------
-- Min/Max
---------------------------------------------------------------------

local function minmax()
    -- lookupMin
    do
        eq({M.lookupMin({x=1,y=2})}, {"x",1})
        eq({M.lookupMin({})}, {nil,nil})
        eq({M{x=1,y=2}:lookupMin()}, {"x",1})
        eq({M{}:lookupMin()}, {nil,nil})
    end
    -- lookupMax
    do
        eq({M.lookupMax({x=1,y=2})}, {"y",2})
        eq({M.lookupMax({})}, {nil,nil})
        eq({M{x=1,y=2}:lookupMax()}, {"y",2})
        eq({M{}:lookupMax()}, {nil,nil})
    end
    -- deleteMin
    do
        eq(M.deleteMin({x=1,y=2}), {y=2})
        eq(M.deleteMin({}), {})
        eq(M{x=1,y=2}:deleteMin(), {y=2})
        eq(M{}:deleteMin(), {})
    end
    -- deleteMax
    do
        eq(M.deleteMax({x=1,y=2}), {x=1})
        eq(M.deleteMax({}), {})
        eq(M{x=1,y=2}:deleteMax(), {x=1})
        eq(M{}:deleteMax(), {})
    end
    -- deleteFindMin
    do
        eq({M.deleteFindMin({x=1,y=2})}, {"x", 1, {y=2}})
        eq({M.deleteFindMin({})}, {nil, nil, {}})
        eq({M{x=1,y=2}:deleteFindMin()}, {"x", 1, {y=2}})
        eq({M{}:deleteFindMin()}, {nil, nil, {}})
    end
    -- deleteFindMax
    do
        eq({M.deleteFindMax({x=1,y=2})}, {"y", 2, {x=1}})
        eq({M.deleteFindMax({})}, {nil, nil, {}})
        eq({M{x=1,y=2}:deleteFindMax()}, {"y", 2, {x=1}})
        eq({M{}:deleteFindMax()}, {nil, nil, {}})
    end
    -- updateMin
    do
        local m10 = function(v) return 10*v end
        eq(M.updateMin(m10, {x=1,y=2}), {x=10,y=2})
        eq(M.updateMin(m10, {}), {})
        eq(M{x=1,y=2}:updateMin(m10), {x=10,y=2})
        eq(M{}:updateMin(m10), {})
    end
    -- updateMax
    do
        local m10 = function(v) return 10*v end
        eq(M.updateMax(m10, {x=1,y=2}), {x=1,y=20})
        eq(M.updateMax(m10, {}), {})
        eq(M{x=1,y=2}:updateMax(m10), {x=1,y=20})
        eq(M{}:updateMax(m10), {})
    end
    -- updateMinWithKey
    do
        local m10 = function(k, v) return k..(10*v) end
        eq(M.updateMinWithKey(m10, {x=1,y=2}), {x="x10",y=2})
        eq(M.updateMinWithKey(m10, {}), {})
        eq(M{x=1,y=2}:updateMinWithKey(m10), {x="x10",y=2})
        eq(M{}:updateMinWithKey(m10), {})
    end
    -- updateMaxWithKey
    do
        local m10 = function(k, v) return k..(10*v) end
        eq(M.updateMaxWithKey(m10, {x=1,y=2}), {x=1,y="y20"})
        eq(M.updateMaxWithKey(m10, {}), {})
        eq(M{x=1,y=2}:updateMaxWithKey(m10), {x=1,y="y20"})
        eq(M{}:updateMaxWithKey(m10), {})
    end
    -- minView
    do
        eq({M.minView{x=1,y=2}}, {1, {y=2}})
        eq({M.minView{}}, {nil})
        eq({M{x=1,y=2}:minView()}, {1, {y=2}})
        eq({M{}:minView()}, {nil})
    end
    -- maxView
    do
        eq({M.maxView{x=1,y=2}}, {2, {x=1}})
        eq({M.maxView{}}, {nil})
        eq({M{x=1,y=2}:maxView()}, {2, {x=1}})
        eq({M{}:maxView()}, {nil})
    end
    -- minViewWithKey
    do
        eq({M.minViewWithKey{x=1,y=2}}, {"x", 1, {y=2}})
        eq({M.minViewWithKey{}}, {nil})
        eq({M{x=1,y=2}:minViewWithKey()}, {"x", 1, {y=2}})
        eq({M{}:minViewWithKey()}, {nil})
    end
    -- maxView
    do
        eq({M.maxViewWithKey{x=1,y=2}}, {"y", 2, {x=1}})
        eq({M.maxViewWithKey{}}, {nil})
        eq({M{x=1,y=2}:maxViewWithKey()}, {"y", 2, {x=1}})
        eq({M{}:maxViewWithKey()}, {nil})
    end
end

---------------------------------------------------------------------
-- Run all tests
---------------------------------------------------------------------

return function()
    construction()
    deletion_update()
    lookup()
    size()
    union()
    difference()
    intersection()
    disjoint()
    compose()
    map()
    folds()
    conversion()
    filter()
    submap()
    minmax()
end
