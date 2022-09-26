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

local L = require "List"

---------------------------------------------------------------------
-- Basic functions
---------------------------------------------------------------------

local function basic_functions()
    -- clone
    do
        local xs = L{"A", "B", "C"}
        local ys = L.clone(xs)
        eq(xs, ys)
        ne(tostring(xs), tostring(ys))
        local zs = xs:clone()
        eq(xs, zs)
        ne(tostring(xs), tostring(zs))
    end
    -- List creation
    do
        local empty = L{}
        eq(empty, {})
        local single = L{42}
        eq(single, {42})
        local t = L{1, 2, 3}
        eq(t, {1, 2, 3})
    end
    -- ipairs
    do
        local l = {}
        for i, v in L{"a", "b"}:ipairs() do
            table.insert(l, {i, v})
        end
        eq(l, {{1,"a"},{2,"b"}})
    end
    -- .. (concatenation)
    do
        eq(L.concat{{1, 2}, {}, {3, {4, 5}}}, {1, 2, 3, {4, 5}})
        eq(L{{1, 2}, {}, {3, {4, 5}}}:concat(), {1, 2, 3, {4, 5}})
        eq(L{1, 2}..{}..L{3, {4, 5}}, {1, 2, 3, {4, 5}})
        eq(L{1, 2}..L{}..{3, {4, 5}}, {1, 2, 3, {4, 5}})
    end
    -- head
    do
        eq(L.head{"a", "b", "c"}, "a")
        eq(L{"a", "b", "c"}:head(), "a")
        eq(L.head{}, nil)
        eq(L{}:head(), nil)
    end
    -- last
    do
        eq(L.last{"a", "b", "c"}, "c")
        eq(L{"a", "b", "c"}:last(), "c")
    end
    -- tail
    do
        eq(L.tail{4, 5, 6}, {5, 6})
        eq(L{4, 5, 6}:tail(), {5, 6})
        eq(L.tail{}, nil)
        eq(L{}:tail(), nil)
    end
    -- init
    do
        eq(L.init{4, 5, 6}, {4, 5})
        eq(L{4, 5, 6}:init(), {4, 5})
        eq(L.init{}, nil)
        eq(L{}:init(), nil)
    end
    -- init
    do
        eq({L.uncons{4, 5, 6}}, {4, {5, 6}})
        eq({L{4, 5, 6}:uncons()}, {4, {5, 6}})
        eq({L.uncons{}}, {nil, nil})
        eq({L{}:uncons()}, {nil, nil})
    end
    -- singleton
    do
        eq(L.singleton(42), {42})
    end
    -- null
    do
        eq(L.null{}, true)
        eq(L{}:null(), true)
        eq(L.null{4}, false)
        eq(L{4}:null(), false)
        eq(L.null{4,5}, false)
        eq(L{4,5}:null(), false)
    end
    -- length
    do
        eq(L.length{}, 0)
        eq(L{}:length(), 0)
        eq(L.length{4}, 1)
        eq(L{4}:length(), 1)
        eq(L.length{4,5}, 2)
        eq(L{4,5}:length(), 2)
    end
end

---------------------------------------------------------------------
-- List transformation
---------------------------------------------------------------------

local function list_transformations()
    -- map
    do
        -- map
        eq(L.map(function(x) return x*2 end, {1, 2, 3}), {2, 4, 6})
        eq(L{1, 2, 3}:map(function(x) return x*2 end), {2, 4, 6})
        -- mapWithIndex
        eq(L.mapWithIndex(function(i, x) return x+i end, {10, 20, 30}), {11, 22, 33})
        eq(L{10, 20, 30}:mapWithIndex(function(i, x) return x+i end), {11, 22, 33})
    end
    -- reverse
    do
        eq(L.reverse{}, {})
        eq(L{}:reverse(), {})
        eq(L.reverse{4, 5, 6}, {6, 5, 4})
        eq(L{4, 5, 6}:reverse(), {6, 5, 4})
    end
    -- intersperse
    do
        eq(L.intersperse(",", {"a", "b", "c"}), {"a", ",", "b", ",", "c"})
        eq(L{"a", "b", "c"}:intersperse",", {"a", ",", "b", ",", "c"})
        eq(L.intersperse(",", {"a"}), {"a"})
        eq(L{"a"}:intersperse",", {"a"})
        eq(L.intersperse(",", {}), {})
        eq(L{}:intersperse",", {})
    end
    -- intercalate
    do
        eq(L.intercalate({","}, {{"a", "b"}, {"c"}, {"d", "e"}}), {"a", "b", ",", "c", ",", "d", "e"})
        eq(L{{"a", "b"}, {"c"}, {"d", "e"}}:intercalate{","}, {"a", "b", ",", "c", ",", "d", "e"})
        eq(L.intercalate({","}, {{"a", "b"}}), {"a", "b"})
        eq(L{{"a", "b"}}:intercalate{","}, {"a", "b"})
    end
    -- transpose
    do
        eq(L.transpose{{1,2,3},{4,5,6}}, {{1,4},{2,5},{3,6}})
        eq(L{{1,2,3},{4,5,6}}:transpose(), {{1,4},{2,5},{3,6}})
        eq(L.transpose{{10,11},{20},{},{30,31,32}}, {{10,20,30},{11,31},{32}})
        eq(L{{10,11},{20},{},{30,31,32}}:transpose(), {{10,20,30},{11,31},{32}})
    end
    -- subsequences
    do
        eq(L.subsequences{"a", "b", "c"}, {{}, {"a"}, {"b"}, {"a","b"}, {"c"}, {"a","c"}, {"b","c"}, {"a","b","c"}})
        eq(L{"a", "b", "c"}:subsequences(), {{}, {"a"}, {"b"}, {"a","b"}, {"c"}, {"a","c"}, {"b","c"}, {"a","b","c"}})
    end
    -- permutations
    do
        eq(L.permutations{"a", "b", "c"}, { {"a","b","c"}, {"a","c","b"},
                                            {"b","a","c"}, {"b","c","a"},
                                            {"c","b","a"}, {"c","a","b"} })
        eq(L{"a", "b", "c"}:permutations(), { {"a","b","c"}, {"a","c","b"},
                                              {"b","a","c"}, {"b","c","a"},
                                              {"c","b","a"}, {"c","a","b"} })
    end
    -- flatten
    do
        eq(L.flatten{1,2,{},{{3,4,{5},6},{{{{7,8},9},10}}}}, {1,2,3,4,5,6,7,8,9,10})
        eq(L{1,2,{},{{3,4,{5},6},{{{{7,8},9},10}}}}:flatten(), {1,2,3,4,5,6,7,8,9,10})
    end
end

---------------------------------------------------------------------
-- Reducing lists (folds)
---------------------------------------------------------------------

local function reducing_lists()
    -- foldl
    do
        eq(L.foldl(function(z, x) return x+z end, 0, {1, 2, 3, 4, 5}), 0+1+2+3+4+5)
        eq(L{1, 2, 3, 4, 5}:foldl(function(z, x) return x+z end, 0), 0+1+2+3+4+5)
        eq(L.foldl(function(z, x) return x+z end, 0, {}), 0)
        eq(L{}:foldl(function(z, x) return x+z end, 0), 0)
    end
    -- foldl1
    do
        eq(L.foldl1(function(z, x) return x+z end, {1, 2, 3, 4, 5}), 1+2+3+4+5)
        eq(L{1, 2, 3, 4, 5}:foldl1(function(z, x) return x+z end), 1+2+3+4+5)
        eq(L.foldl1(function(z, x) return x+z end, {}), nil)
        eq(L{}:foldl1(function(z, x) return x+z end), nil)
    end
    -- foldr
    do
        eq(L.foldr(function(x, z) return x+z end, 0, {1, 2, 3, 4, 5}), 0+1+2+3+4+5)
        eq(L{1, 2, 3, 4, 5}:foldr(function(x, z) return x+z end, 0), 0+1+2+3+4+5)
        eq(L.foldr(function(x, z) return x+z end, 0, {}), 0)
        eq(L{}:foldr(function(x, z) return x+z end, 0), 0)
    end
    -- foldr1
    do
        eq(L.foldr1(function(x, z) return x+z end, {1, 2, 3, 4, 5}), 1+2+3+4+5)
        eq(L{1, 2, 3, 4, 5}:foldr1(function(x, z) return x+z end), 1+2+3+4+5)
        eq(L.foldr1(function(x, z) return x+z end, {}), nil)
        eq(L{}:foldr1(function(x, z) return x+z end), nil)
    end
end

---------------------------------------------------------------------
-- Special folds
---------------------------------------------------------------------

local function special_folds()
    -- concat
    do
        eq(L.concat{{1, 2}, {}, {3, {4, 5}}}, {1, 2, 3, {4, 5}})
        eq(L{{1, 2}, {}, {3, {4, 5}}}:concat(), {1, 2, 3, {4, 5}})
    end
    -- concatMap
    do
        eq(L.concatMap(function(s) return L(s)..{"!"} end, {{"one"}, {"two"}, {"three"}}), {"one", "!", "two", "!", "three", "!"})
        eq(L{{"one"}, {"two"}, {"three"}}:concatMap(function(s) return L(s)..{"!"} end), {"one", "!", "two", "!", "three", "!"})
    end
    -- and
    do
        eq(L.and_{true,  true,  true},  true)
        eq(L.and_{false, true,  true},  false)
        eq(L.and_{true,  false, true},  false)
        eq(L.and_{true,  true,  false}, false)
        eq(L.and_{}, true)
        eq(L{true,  true,  true}:and_(),  true)
        eq(L{false, true,  true}:and_(),  false)
        eq(L{true,  false, true}:and_(),  false)
        eq(L{true,  true,  false}:and_(), false)
        eq(L{}:and_(), true)
    end
    -- or
    do
        eq(L.or_{false, false, false}, false)
        eq(L.or_{true,  false, false}, true)
        eq(L.or_{false, true,  false}, true)
        eq(L.or_{false, false, true},  true)
        eq(L.or_{}, false)
        eq(L{false, false, false}:or_(), false)
        eq(L{true,  false, false}:or_(), true)
        eq(L{false, true,  false}:or_(), true)
        eq(L{false, false, true}:or_(),  true)
        eq(L{}:or_(), false)
    end
    -- any
    do
        eq(L.any(function(x) return x > 3 end, {}), false)
        eq(L.any(function(x) return x > 3 end, {1,2}), false)
        eq(L.any(function(x) return x > 3 end, {1,2,3,4}), true)
        eq(L.any(function(_) return true end, {}), false)
        eq(L{}:any(function(x) return x > 3 end), false)
        eq(L{1,2}:any(function(x) return x > 3 end), false)
        eq(L{1,2,3,4}:any(function(x) return x > 3 end), true)
        eq(L{}:any(function(_) return true end), false)
    end
    -- all
    do
        eq(L.all(function(x) return x < 3 end, {}), true)
        eq(L.all(function(x) return x < 3 end, {1,2}), true)
        eq(L.all(function(x) return x < 3 end, {1,2,3,4}), false)
        eq(L.all(function(_) return true end, {}), true)
        eq(L{}:all(function(x) return x < 3 end), true)
        eq(L{1,2}:all(function(x) return x < 3 end), true)
        eq(L{1,2,3,4}:all(function(x) return x < 3 end), false)
        eq(L{}:all(function(_) return true end), true)
    end
    -- sum
    do
        eq(L.sum{1,2,3,4,5}, 1+2+3+4+5)
        eq(L.sum{}, 0)
        eq(L{1,2,3,4,5}:sum(), 1+2+3+4+5)
        eq(L{}:sum(), 0)
    end
    -- product
    do
        eq(L.product{1,2,3,4,5}, 1*2*3*4*5)
        eq(L.product{}, 1)
        eq(L{1,2,3,4,5}:product(), 1*2*3*4*5)
        eq(L{}:product(), 1)
    end
    -- maximum
    do
        eq(L.maximum{1,2,3,4,5,3,0,-1,-2,-3,2,1}, 5)
        eq(L.maximum{}, nil)
        eq(L{1,2,3,4,5,3,0,-1,-2,-3,2,1}:maximum(), 5)
        eq(L{}:maximum(), nil)
    end
    -- minimum
    do
        eq(L.minimum{1,2,3,4,5,3,0,-1,-2,-3,2,1}, -3)
        eq(L.minimum{}, nil)
        eq(L{1,2,3,4,5,3,0,-1,-2,-3,2,1}:minimum(), -3)
        eq(L{}:minimum(), nil)
    end
end

---------------------------------------------------------------------
-- Building lists
---------------------------------------------------------------------

local function building_lists()
    -- scanl
    do
        eq(L.scanl(function(z, x) return z+x end, 0, {1, 2, 3, 4}), {0, 1, 3, 6, 10})
        eq(L{1, 2, 3, 4}:scanl(function(z, x) return z+x end, 0), {0, 1, 3, 6, 10})
        eq(L.scanl(function(z, x) return z+x end, 0, {}), {0})
        eq(L{}:scanl(function(z, x) return z+x end, 0), {0})
    end
    -- scanl1
    do
        eq(L.scanl1(function(z, x) return z+x end, {1, 2, 3, 4}), {1, 3, 6, 10})
        eq(L{1, 2, 3, 4}:scanl1(function(z, x) return z+x end), {1, 3, 6, 10})
        eq(L.scanl1(function(z, x) return z+x end, {}), {})
        eq(L{}:scanl1(function(z, x) return z+x end), {})
    end
    -- scanr
    do
        eq(L.scanr(function(x, z) return x+z end, 0, {1, 2, 3, 4}), {10, 9, 7, 4, 0})
        eq(L{1, 2, 3, 4}:scanr(function(x, z) return x+z end, 0), {10, 9, 7, 4, 0})
        eq(L.scanr(function(x, z) return x+z end, 0, {}), {0})
        eq(L{}:scanr(function(x, z) return x+z end, 0), {0})
    end
    -- scanr1
    do
        eq(L.scanr1(function(x, z) return x+z end, {1, 2, 3, 4}), {10, 9, 7, 4})
        eq(L{1, 2, 3, 4}:scanr1(function(x, z) return x+z end), {10, 9, 7, 4})
        eq(L.scanr1(function(x, z) return x+z end, {}), {})
        eq(L{}:scanr1(function(x, z) return x+z end), {})
    end
    -- replicate
    do
        eq(L.replicate(0, 42), {})
        eq(L.replicate(-1, 42), {})
        eq(L.replicate(1, 42), {42})
        eq(L.replicate(4, 42), {42,42,42,42})
    end
    -- unfoldr
    do
        eq(L.unfoldr(function(z) if z > 0 then return z, z-1 end end, 10), {10, 9, 8, 7, 6, 5, 4, 3, 2, 1})
        eq(L.unfoldr(function(z) if z > 0 then return z, z-1 end end, 1), {1})
        eq(L.unfoldr(function(z) if z > 0 then return z, z-1 end end, 0), {})
    end
    -- range
    do
        eq(L.range(5), {1,2,3,4,5})
        eq(L.range(5, 9), {5,6,7,8,9})
        eq(L.range(5, 9, 2), {5,7,9})
        eq(L.range(9, 5), {9,8,7,6,5})
        eq(L.range(9, 5, -2), {9,7,5})
    end
end

---------------------------------------------------------------------
-- Sublists
---------------------------------------------------------------------

local function sublists()
    -- take
    do
        eq(L.take(3, {1, 2, 3, 4, 5}), {1, 2, 3})
        eq(L.take(3, {1, 2}), {1, 2})
        eq(L.take(3, {}), {})
        eq(L.take(-1, {1, 2}), {})
        eq(L.take(0, {1, 2}), {})
        eq(L{1, 2, 3, 4, 5}:take(3), {1, 2, 3})
        eq(L{1, 2}:take(3), {1, 2})
        eq(L{}:take(3), {})
        eq(L{1, 2}:take(-1), {})
        eq(L{1, 2}:take(0), {})
    end
    -- drop
    do
        eq(L.drop(3, {1, 2, 3, 4, 5}), {4, 5})
        eq(L.drop(3, {1, 2}), {})
        eq(L.drop(3, {}), {})
        eq(L.drop(-1, {1, 2}), {1, 2})
        eq(L.drop(0, {1, 2}), {1, 2})
        eq(L{1, 2, 3, 4, 5}:drop(3), {4, 5})
        eq(L{1, 2}:drop(3), {})
        eq(L{}:drop(3), {})
        eq(L{1, 2}:drop(-1), {1, 2})
        eq(L{1, 2}:drop(0), {1, 2})
    end
    -- splitAt
    do
        eq({L.splitAt(3, {1, 2, 3, 4, 5})}, {{1, 2, 3}, {4, 5}})
        eq({L.splitAt(1, {1, 2, 3})}, {{1}, {2, 3}})
        eq({L.splitAt(3, {1, 2, 3})}, {{1, 2, 3}, {}})
        eq({L.splitAt(4, {1, 2, 3})}, {{1, 2, 3}, {}})
        eq({L.splitAt(0, {1, 2, 3})}, {{}, {1, 2, 3}})
        eq({L.splitAt(-1, {1, 2, 3})}, {{}, {1, 2, 3}})
        eq({L{1, 2, 3, 4, 5}:splitAt(3, {1, 2, 3, 4, 5})}, {{1, 2, 3}, {4, 5}})
        eq({L{1, 2, 3}:splitAt(1)}, {{1}, {2, 3}})
        eq({L{1, 2, 3}:splitAt(3)}, {{1, 2, 3}, {}})
        eq({L{1, 2, 3}:splitAt(4)}, {{1, 2, 3}, {}})
        eq({L{1, 2, 3}:splitAt(0)}, {{}, {1, 2, 3}})
        eq({L{1, 2, 3}:splitAt(-1)}, {{}, {1, 2, 3}})
    end
    -- takeWhile
    do
        eq(L.takeWhile(function(x) return x < 3 end, {1,2,3,4,1,2,3,4}), {1,2})
        eq(L.takeWhile(function(x) return x < 9 end, {1,2,3}), {1,2,3})
        eq(L.takeWhile(function(x) return x < 0 end, {1,2,3}), {})
        eq(L{1,2,3,4,1,2,3,4}:takeWhile(function(x) return x < 3 end), {1,2})
        eq(L{1,2,3}:takeWhile(function(x) return x < 9 end), {1,2,3})
        eq(L{1,2,3}:takeWhile(function(x) return x < 0 end), {})
    end
    -- dropWhile
    do
        eq(L.dropWhile(function(x) return x < 3 end, {1,2,3,4,5,1,2,3}), {3,4,5,1,2,3})
        eq(L.dropWhile(function(x) return x < 9 end, {1,2,3}), {})
        eq(L.dropWhile(function(x) return x < 0 end, {1,2,3}), {1,2,3})
        eq(L{1,2,3,4,5,1,2,3}:dropWhile(function(x) return x < 3 end), {3,4,5,1,2,3})
        eq(L{1,2,3}:dropWhile(function(x) return x < 9 end), {})
        eq(L{1,2,3}:dropWhile(function(x) return x < 0 end), {1,2,3})
    end
    -- dropWhileEnd
    do
        eq(L.dropWhileEnd(function(x) return x < 4 end, {1,2,3,4,5,1,2,3}), {1,2,3,4,5})
        eq(L.dropWhileEnd(function(x) return x < 9 end, {1,2,3}), {})
        eq(L.dropWhileEnd(function(x) return x < 0 end, {1,2,3}), {1,2,3})
        eq(L{1,2,3,4,5,1,2,3}:dropWhileEnd(function(x) return x < 4 end), {1,2,3,4,5})
        eq(L{1,2,3}:dropWhileEnd(function(x) return x < 9 end), {})
        eq(L{1,2,3}:dropWhileEnd(function(x) return x < 0 end), {1,2,3})
    end
    -- span
    do
        eq({L.span(function(x) return x < 3 end, {1,2,3,4,1,2,3,4})}, {{1,2},{3,4,1,2,3,4}})
        eq({L.span(function(x) return x < 9 end, {1,2,3})}, {{1,2,3},{}})
        eq({L.span(function(x) return x < 0 end, {1,2,3})}, {{},{1,2,3}})
        eq({L{1,2,3,4,1,2,3,4}:span(function(x) return x < 3 end)}, {{1,2},{3,4,1,2,3,4}})
        eq({L{1,2,3}:span(function(x) return x < 9 end)}, {{1,2,3},{}})
        eq({L{1,2,3}:span(function(x) return x < 0 end)}, {{},{1,2,3}})
    end
    -- break_
    do
        eq({L.break_(function(x) return x > 3 end, {1,2,3,4,1,2,3,4})}, {{1,2,3},{4,1,2,3,4}})
        eq({L.break_(function(x) return x > 9 end, {1,2,3})}, {{1,2,3},{}})
        eq({L.break_(function(x) return x < 9 end, {1,2,3})}, {{},{1,2,3}})
        eq({L{1,2,3,4,1,2,3,4}:break_(function(x) return x > 3 end)}, {{1,2,3},{4,1,2,3,4}})
        eq({L{1,2,3}:break_(function(x) return x > 9 end)}, {{1,2,3},{}})
        eq({L{1,2,3}:break_(function(x) return x < 9 end)}, {{},{1,2,3}})
    end
    -- stripPrefix
    do
        eq(L.stripPrefix({1,2}, {1,2,3,4}), {3,4})
        eq(L.stripPrefix({1,2}, {1,2}), {})
        eq(L.stripPrefix({3,2}, {1,2,3,4}), nil)
        eq(L.stripPrefix({}, {1,2,3,4}), {1,2,3,4})
        eq(L{1,2,3,4}:stripPrefix({1,2}), {3,4})
        eq(L{1,2}:stripPrefix({1,2}), {})
        eq(L{1,2,3,4}:stripPrefix({3,2}), nil)
        eq(L{1,2,3,4}:stripPrefix({}), {1,2,3,4})
    end
    -- group
    do
        eq(L.group({1,2,3,3,2,3,3,2,4,4,2}), {{1},{2},{3,3},{2},{3,3},{2},{4,4},{2}})
        eq(L.group({1,2,3,3,2,3,3,2,4,4,2,2}), {{1},{2},{3,3},{2},{3,3},{2},{4,4},{2,2}})
        eq(L.group({}), {})
        eq(L.group({1}), {{1}})
        eq(L{1,2,3,3,2,3,3,2,4,4,2}:group(), {{1},{2},{3,3},{2},{3,3},{2},{4,4},{2}})
        eq(L{1,2,3,3,2,3,3,2,4,4,2,2}:group(), {{1},{2},{3,3},{2},{3,3},{2},{4,4},{2,2}})
        eq(L{}:group(), {})
        eq(L{1}:group(), {{1}})
    end
    -- inits
    do
        eq(L.inits({1,2,3}), {{}, {1}, {1,2}, {1,2,3}})
        eq(L{1,2,3}:inits(), {{}, {1}, {1,2}, {1,2,3}})
        eq(L.inits({}), {{}})
        eq(L{}:inits(), {{}})
    end
    -- tails
    do
        eq(L.tails({1,2,3}), {{1,2,3},{2,3},{3},{}})
        eq(L{1,2,3}:tails(), {{1,2,3},{2,3},{3},{}})
        eq(L.tails({}), {{}})
        eq(L{}:tails(), {{}})
    end
end

---------------------------------------------------------------------
-- Predicates
---------------------------------------------------------------------

local function predicates()
    -- isPrefixOf
    do
        eq(L.isPrefixOf({1,2}, {1,2,3}), true)
        eq(L.isPrefixOf({1,2}, {1,3,2}), false)
        eq(L.isPrefixOf({}, {1,2,3}), true)
        eq(L.isPrefixOf({1,2}, {}), false)
        eq(L{1,2}:isPrefixOf({1,2,3}), true)
        eq(L{1,2}:isPrefixOf({1,3,2}), false)
        eq(L{}:isPrefixOf({1,2,3}), true)
        eq(L{1,2}:isPrefixOf({}), false)
    end
    -- isSuffixOf
    do
        eq(L.isSuffixOf({1,2}, {3,1,2}), true)
        eq(L.isSuffixOf({1,2}, {3,2,1}), false)
        eq(L.isSuffixOf({}, {1,2,3}), true)
        eq(L.isSuffixOf({1,2}, {}), false)
        eq(L{1,2}:isSuffixOf({3,1,2}), true)
        eq(L{1,2}:isSuffixOf({3,2,1}), false)
        eq(L{}:isSuffixOf({1,2,3}), true)
        eq(L{1,2}:isSuffixOf({}), false)
    end
    -- isInfixOf
    do
        eq(L.isInfixOf({1,2}, {1,2,3,4}), true)
        eq(L.isInfixOf({1,2}, {3,1,2,4}), true)
        eq(L.isInfixOf({1,2}, {3,4,1,2}), true)
        eq(L.isInfixOf({2,1}, {1,2,3,4}), false)
        eq(L.isInfixOf({2,1}, {3,1,2,4}), false)
        eq(L.isInfixOf({2,1}, {3,4,1,2}), false)
        eq(L.isInfixOf({}, {1,2,3,4}), true)
        eq(L.isInfixOf({1,2}, {}), false)
        eq(L{1,2}:isInfixOf({1,2,3,4}), true)
        eq(L{1,2}:isInfixOf({3,1,2,4}), true)
        eq(L{1,2}:isInfixOf({3,4,1,2}), true)
        eq(L{2,1}:isInfixOf({1,2,3,4}), false)
        eq(L{2,1}:isInfixOf({3,1,2,4}), false)
        eq(L{2,1}:isInfixOf({3,4,1,2}), false)
        eq(L{}:isInfixOf({1,2,3,4}), true)
        eq(L{1,2}:isInfixOf({}), false)
    end
    -- isSubsequenceOf
    do
        eq(L.isSubsequenceOf({1,2,3}, {0,1,4,2,5,3,6}), true)
        eq(L.isSubsequenceOf({1,2,3}, {0,1,4,3,5,2,6}), false)
        eq(L{1,2,3}:isSubsequenceOf({0,1,4,2,5,3,6}), true)
        eq(L{1,2,3}:isSubsequenceOf({0,1,4,3,5,2,6}), false)
    end
end

---------------------------------------------------------------------
-- Searching lists
---------------------------------------------------------------------

local function searching_lists()
    -- elem
    do
        eq(L.elem(1, {1,2,3}), true)
        eq(L.elem(2, {1,2,3}), true)
        eq(L.elem(3, {1,2,3}), true)
        eq(L.elem(4, {1,2,3}), false)
        eq(L.elem(4, {}), false)
        eq(L{1,2,3}:elem(1), true)
        eq(L{1,2,3}:elem(2), true)
        eq(L{1,2,3}:elem(3), true)
        eq(L{1,2,3}:elem(4), false)
        eq(L{}:elem(4), false)
    end
    -- notElem
    do
        eq(L.notElem(1, {1,2,3}), false)
        eq(L.notElem(2, {1,2,3}), false)
        eq(L.notElem(3, {1,2,3}), false)
        eq(L.notElem(4, {1,2,3}), true)
        eq(L.notElem(4, {}), true)
        eq(L{1,2,3}:notElem(1), false)
        eq(L{1,2,3}:notElem(2), false)
        eq(L{1,2,3}:notElem(3), false)
        eq(L{1,2,3}:notElem(4), true)
        eq(L{}:notElem(4), true)
    end
    -- lookup
    do
        eq(L.lookup(2, {}), nil)
        eq(L.lookup(2, {{1, "first"}}), nil)
        eq(L.lookup(2, {{1, "first"}, {2, "second"}, {3, "third"}}), "second")
        eq(L.lookup(4, {{1, "first"}, {2, "second"}, {3, "third"}}), nil)
        eq(L{}:lookup(2), nil)
        eq(L{{1, "first"}}:lookup(2), nil)
        eq(L{{1, "first"}, {2, "second"}, {3, "third"}}:lookup(2), "second")
        eq(L{{1, "first"}, {2, "second"}, {3, "third"}}:lookup(4), nil)
    end
    -- find
    do
        eq(L.find(function(x) return x > 3 end, {1,2,3,4,5}), 4)
        eq(L.find(function(x) return x > 6 end, {1,2,3,4,5}), nil)
        eq(L.find(function(_) return true end, {}), nil)
        eq(L{1,2,3,4,5}:find(function(x) return x > 3 end), 4)
        eq(L{1,2,3,4,5}:find(function(x) return x > 6 end), nil)
        eq(L{}:find(function(_) return true end), nil)
    end
    -- filter
    do
        eq(L.filter(function(x) return x%2==0 end, {1,2,3,4,5}), {2,4})
        eq(L.filter(function(x) return x%2==0 end, {}), {})
        eq(L{1,2,3,4,5}:filter(function(x) return x%2==0 end), {2,4})
        eq(L{}:filter(function(x) return x%2==0 end), {})
    end
    -- partition
    do
        eq({L.partition(function(x) return x%2==0 end, {1,2,3,4,5})}, {{2,4},{1,3,5}})
        eq({L.partition(function(_) return true end, {1,2,3,4,5})}, {{1,2,3,4,5},{}})
        eq({L.partition(function(_) return false end, {1,2,3,4,5})}, {{},{1,2,3,4,5}})
        eq({L.partition(function(_) return true end, {})}, {{},{}})
        eq({L{1,2,3,4,5}:partition(function(x) return x%2==0 end)}, {{2,4},{1,3,5}})
        eq({L{1,2,3,4,5}:partition(function(_) return true end)}, {{1,2,3,4,5},{}})
        eq({L{1,2,3,4,5}:partition(function(_) return false end)}, {{},{1,2,3,4,5}})
        eq({L{}:partition(function(_) return true end)}, {{},{}})
    end
end

---------------------------------------------------------------------
-- Indexing lists
---------------------------------------------------------------------

local function indexing_lists()
    -- elemIndex
    do
        eq(L.elemIndex(2, {0,1,2,3,1,2,3}), 3)
        eq(L{0,1,2,3,1,2,3}:elemIndex(2), 3)
        eq(L.elemIndex(4, {0,1,2,3,1,2,3}), nil)
        eq(L{0,1,2,3,1,2,3}:elemIndex(4), nil)
    end
    -- elemIndices
    do
        eq(L.elemIndices(2, {0,1,2,3,1,2,3}), {3, 6})
        eq(L{0,1,2,3,1,2,3}:elemIndices(2), {3, 6})
        eq(L.elemIndices(4, {0,1,2,3,1,2,3}), {})
        eq(L{0,1,2,3,1,2,3}:elemIndices(4), {})
    end
    -- findIndex
    do
        eq(L.findIndex(function(x) return x==2 end, {0,1,2,3,1,2,3}), 3)
        eq(L{0,1,2,3,1,2,3}:findIndex(function(x) return x==2 end), 3)
        eq(L.findIndex(function(x) return x==4 end, {0,1,2,3,1,2,3}), nil)
        eq(L{0,1,2,3,1,2,3}:findIndex(function(x) return x==4 end), nil)
    end
    -- findIndices
    do
        eq(L.findIndices(function(x) return x==2 end, {0,1,2,3,1,2,3}), {3, 6})
        eq(L{0,1,2,3,1,2,3}:findIndices(function(x) return x==2 end), {3, 6})
        eq(L.findIndices(function(x) return x==4 end, {0,1,2,3,1,2,3}), {})
        eq(L{0,1,2,3,1,2,3}:findIndices(function(x) return x==4 end), {})
    end
end

---------------------------------------------------------------------
-- Zipping and unzipping lists
---------------------------------------------------------------------

local function zipping_and_unzipping_lists()
    -- zip
    do
        eq(L.zip({1,2,3}, {4,5}), {{1,4},{2,5}})
        eq(L.zip3({1,2,3}, {4,5}, {6,7,8}), {{1,4,6},{2,5,7}})
        eq(L.zip4({1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}), {{1,4,6,9},{2,5,7,10}})
        eq(L.zip5({1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}), {{1,4,6,9,13},{2,5,7,10,14}})
        eq(L.zip6({1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}), {{1,4,6,9,13,15},{2,5,7,10,14,16}})
        eq(L.zip7({1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}, {17,18,19}), {{1,4,6,9,13,15,17},{2,5,7,10,14,16,18}})
        eq(L{1,2,3}:zip({4,5}), {{1,4},{2,5}})
        eq(L{1,2,3}:zip3({4,5}, {6,7,8}), {{1,4,6},{2,5,7}})
        eq(L{1,2,3}:zip4({4,5}, {6,7,8}, {9,10,11,12}), {{1,4,6,9},{2,5,7,10}})
        eq(L{1,2,3}:zip5({4,5}, {6,7,8}, {9,10,11,12}, {13,14}), {{1,4,6,9,13},{2,5,7,10,14}})
        eq(L{1,2,3}:zip6({4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}), {{1,4,6,9,13,15},{2,5,7,10,14,16}})
        eq(L{1,2,3}:zip7({4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}, {17,18,19}), {{1,4,6,9,13,15,17},{2,5,7,10,14,16,18}})
    end
    -- zipWith
    do
        local function tuple(...) return {...} end
        eq(L.zipWith(tuple, {1,2,3}, {4,5}), {{1,4},{2,5}})
        eq(L.zipWith3(tuple, {1,2,3}, {4,5}, {6,7,8}), {{1,4,6},{2,5,7}})
        eq(L.zipWith4(tuple, {1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}), {{1,4,6,9},{2,5,7,10}})
        eq(L.zipWith5(tuple, {1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}), {{1,4,6,9,13},{2,5,7,10,14}})
        eq(L.zipWith6(tuple, {1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}), {{1,4,6,9,13,15},{2,5,7,10,14,16}})
        eq(L.zipWith7(tuple, {1,2,3}, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}, {17,18,19}), {{1,4,6,9,13,15,17},{2,5,7,10,14,16,18}})
        eq(L{1,2,3}:zipWith(tuple, {4,5}), {{1,4},{2,5}})
        eq(L{1,2,3}:zipWith3(tuple, {4,5}, {6,7,8}), {{1,4,6},{2,5,7}})
        eq(L{1,2,3}:zipWith4(tuple, {4,5}, {6,7,8}, {9,10,11,12}), {{1,4,6,9},{2,5,7,10}})
        eq(L{1,2,3}:zipWith5(tuple, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}), {{1,4,6,9,13},{2,5,7,10,14}})
        eq(L{1,2,3}:zipWith6(tuple, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}), {{1,4,6,9,13,15},{2,5,7,10,14,16}})
        eq(L{1,2,3}:zipWith7(tuple, {4,5}, {6,7,8}, {9,10,11,12}, {13,14}, {15,16}, {17,18,19}), {{1,4,6,9,13,15,17},{2,5,7,10,14,16,18}})
    end
    -- unzip
    do
        eq({L.unzip{{1,2},{3,4},{5,6}}}, {{1,3,5},{2,4,6}})
        eq({L.unzip3{{1,2,3},{4,5,6},{7,8,9}}}, {{1,4,7},{2,5,8},{3,6,9}})
        eq({L.unzip4{{1,2,3,"a"},{4,5,6,"b"},{7,8,9,"c"}}}, {{1,4,7},{2,5,8},{3,6,9},{"a","b","c"}})
        eq({L.unzip5{{1,2,3,"a","b"},{4,5,6,"c","d"},{7,8,9,"e","f"}}}, {{1,4,7},{2,5,8},{3,6,9},{"a","c","e"},{"b","d","f"}})
        eq({L.unzip6{{1,2,3,"a","b","c"},{4,5,6,"d","e","f"},{7,8,9,"g","h","i"}}}, {{1,4,7},{2,5,8},{3,6,9},{"a","d","g"},{"b","e","h"},{"c","f","i"}})
        eq({L.unzip7{{1,2,3,"a","b","c","x"},{4,5,6,"d","e","f","y"},{7,8,9,"g","h","i","z"}}}, {{1,4,7},{2,5,8},{3,6,9},{"a","d","g"},{"b","e","h"},{"c","f","i"},{"x","y","z"}})
        eq({L{{1,2},{3,4},{5,6}}:unzip()}, {{1,3,5},{2,4,6}})
        eq({L{{1,2,3},{4,5,6},{7,8,9}}:unzip3()}, {{1,4,7},{2,5,8},{3,6,9}})
        eq({L{{1,2,3,"a"},{4,5,6,"b"},{7,8,9,"c"}}:unzip4()}, {{1,4,7},{2,5,8},{3,6,9},{"a","b","c"}})
        eq({L{{1,2,3,"a","b"},{4,5,6,"c","d"},{7,8,9,"e","f"}}:unzip5()}, {{1,4,7},{2,5,8},{3,6,9},{"a","c","e"},{"b","d","f"}})
        eq({L{{1,2,3,"a","b","c"},{4,5,6,"d","e","f"},{7,8,9,"g","h","i"}}:unzip6()}, {{1,4,7},{2,5,8},{3,6,9},{"a","d","g"},{"b","e","h"},{"c","f","i"}})
        eq({L{{1,2,3,"a","b","c","x"},{4,5,6,"d","e","f","y"},{7,8,9,"g","h","i","z"}}:unzip7()}, {{1,4,7},{2,5,8},{3,6,9},{"a","d","g"},{"b","e","h"},{"c","f","i"},{"x","y","z"}})
    end
end

---------------------------------------------------------------------
-- Functions on strings
---------------------------------------------------------------------

local function functions_on_strings()
    -- lines
    do
        eq(L.lines(""), {})
        eq(L.lines("\n"), {""})
        eq(L.lines("one"), {"one"})
        eq(L.lines("one\n"), {"one"})
        eq(L.lines("one\n\n"), {"one",""})
        eq(L.lines("one\ntwo"), {"one","two"})
        eq(L.lines("one\n\ntwo"), {"one","","two"})
        eq(L.lines("one\ntwo\n"), {"one","two"})
    end
    -- words
    do
        eq(L.words(""), {})
        eq(L.words("\n"), {})
        eq(L.words("one"), {"one"})
        eq(L.words("one\n"), {"one"})
        eq(L.words("one\n\n"), {"one"})
        eq(L.words("one\ntwo"), {"one","two"})
        eq(L.words("one\n\ntwo"), {"one","two"})
        eq(L.words("one\ntwo\n"), {"one","two"})
        eq(L.words(" Lorem ipsum\ndolor "), {"Lorem","ipsum","dolor"})
    end
    -- unlines
    do
        eq(L.unlines{}, "")
        eq(L.unlines{""}, "\n")
        eq(L.unlines{"one"}, "one\n")
        eq(L.unlines{"one",""}, "one\n\n")
        eq(L.unlines{"one","two"}, "one\ntwo\n")
        eq(L.unlines{"one","","two"}, "one\n\ntwo\n")
        eq(L{}:unlines(), "")
        eq(L{""}:unlines(), "\n")
        eq(L{"one"}:unlines(), "one\n")
        eq(L{"one",""}:unlines(), "one\n\n")
        eq(L{"one","two"}:unlines(), "one\ntwo\n")
        eq(L{"one","","two"}:unlines(), "one\n\ntwo\n")
    end
    -- unwords
    do
        eq(L.unwords{}, "")
        eq(L.unwords{""}, "")
        eq(L.unwords{"one"}, "one")
        eq(L.unwords{"one","two"}, "one two")
        eq(L{}:unwords(), "")
        eq(L{"one"}:unwords(), "one")
        eq(L{"one","two"}:unwords(), "one two")
    end
end

---------------------------------------------------------------------
-- Set operations
---------------------------------------------------------------------

local function set_operations()
    -- nub
    do
        eq(L.nub{1,2,3,4,3,2,1,2,4,3,5}, {1,2,3,4,5})
        eq(L{1,2,3,4,3,2,1,2,4,3,5}:nub(), {1,2,3,4,5})
    end
    -- delete
    do
        eq(L.delete('a', {'b','a','n','a','n','a'}), {'b','n','a','n','a'})
        eq(L.delete('c', {'b','a','n','a','n','a'}), {'b','a','n','a','n','a'})
        eq(L.delete('c', {}), {})
        eq(L{'b','a','n','a','n','a'}:delete('a'), {'b','n','a','n','a'})
        eq(L{'b','a','n','a','n','a'}:delete('c'), {'b','a','n','a','n','a'})
        eq(L{}:delete('c'), {})
    end
    -- difference
    do
        eq(L.difference({1,2,3,1,2,3}, {1,2}), {3,1,2,3})
        eq(L.difference({1,2,3,1,2,3}, {2,1}), {3,1,2,3})
        eq(L.difference({1,2,3,1,2,3}, {2,3}), {1,1,2,3})
        eq(L.difference({1,2,3,1,2,3}, {2,3}), {1,1,2,3})
        eq(L{1,2,3,1,2,3}:difference{1,2}, {3,1,2,3})
        eq(L{1,2,3,1,2,3}:difference{2,1}, {3,1,2,3})
        eq(L{1,2,3,1,2,3}:difference{2,3}, {1,1,2,3})
        eq(L{1,2,3,1,2,3}:difference{2,3}, {1,1,2,3})
    end
    -- union
    do
        eq(L.union({1,2,3,1},{2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1,4,5})
        eq(L.union({1,2,3,1},{}), {1,2,3,1})
        eq(L.union({},{2,3,4,2,3,5,2,3,4,2,3,5}), {2,3,4,5})
        eq(L{1,2,3,1}:union{2,3,4,2,3,5,2,3,4,2,3,5}, {1,2,3,1,4,5})
        eq(L{1,2,3,1}:union{}, {1,2,3,1})
        eq(L{}:union{2,3,4,2,3,5,2,3,4,2,3,5}, {2,3,4,5})
    end
    -- intersect
    do
        eq(L.intersect({1,2,3,1,3,2},{2,3,4,2,3,5,2,3,4,2,3,5}), {2,3,3,2})
        eq(L.intersect({1,2,3,1},{}), {})
        eq(L.intersect({},{2,3,4,2,3,5,2,3,4,2,3,5}), {})
        eq(L{1,2,3,1,3,2}:intersect{2,3,4,2,3,5,2,3,4,2,3,5}, {2,3,3,2})
        eq(L{1,2,3,1}:intersect{}, {})
        eq(L{}:intersect{2,3,4,2,3,5,2,3,4,2,3,5}, {})
    end
end

---------------------------------------------------------------------
-- Ordered lists
---------------------------------------------------------------------

local function ordered_lists()
    -- sort
    do
        eq(L.sort{1,6,4,3,2,5}, {1,2,3,4,5,6})
        eq(L{1,6,4,3,2,5}:sort(), {1,2,3,4,5,6})
    end
    -- sortOn
    do
        local function fst(xs) return xs[1] end
        eq(L.sortOn(fst, {{2,"world"},{4,"!"},{1,"Hello"}}), {{1,"Hello"},{2,"world"},{4,"!"}})
        eq(L{{2,"world"},{4,"!"},{1,"Hello"}}:sortOn(fst), {{1,"Hello"},{2,"world"},{4,"!"}})
    end
    -- insert
    do
        eq(L.insert(4, {1,2,3,5,6,7}), {1,2,3,4,5,6,7})
        eq(L.insert(0, {1,2,3,5,6,7}), {0,1,2,3,5,6,7})
        eq(L.insert(8, {1,2,3,5,6,7}), {1,2,3,5,6,7,8})
        eq(L{1,2,3,5,6,7}:insert(4), {1,2,3,4,5,6,7})
        eq(L{1,2,3,5,6,7}:insert(0), {0,1,2,3,5,6,7})
        eq(L{1,2,3,5,6,7}:insert(8), {1,2,3,5,6,7,8})
    end
end

---------------------------------------------------------------------
-- Generalized functions
---------------------------------------------------------------------

local function generalized_functions()
    -- nubBy
    do
        local function eqmod3(a, b) return a%3 == b%3 end
        eq(L.nubBy(eqmod3, {1,2,3,4,3,2,1,2,4,3,5}), {1,2,3})
        eq(L{1,2,3,4,3,2,1,2,4,3,5}:nubBy(eqmod3), {1,2,3})
    end
    -- deleteBy
    do
        local function eqchar(a, b) return a:lower() == b:lower() end
        eq(L.deleteBy(eqchar, 'A', {'b','A','n','a','n','a'}), {'b','n','a','n','a'})
        eq(L.deleteBy(eqchar, 'C', {'b','A','n','a','n','a'}), {'b','A','n','a','n','a'})
        eq(L.deleteBy(eqchar, 'C', {}), {})
        eq(L{'b','A','n','a','n','a'}:deleteBy(eqchar, 'A'), {'b','n','a','n','a'})
        eq(L{'b','A','n','a','n','a'}:deleteBy(eqchar, 'C'), {'b','A','n','a','n','a'})
        eq(L{}:deleteBy(eqchar, 'C'), {})
    end
    -- differenceBy
    do
        local function eqmod2(a, b) return a%2 == b%2 end
        eq(L.differenceBy(eqmod2, {1,2,3,1,2,3}, {1,2}), {3,1,2,3})
        eq(L.differenceBy(eqmod2, {1,2,3,1,2,3}, {2,1}), {3,1,2,3})
        eq(L.differenceBy(eqmod2, {1,2,3,1,2,3}, {2,3}), {3,1,2,3})
        eq(L.differenceBy(eqmod2, {1,2,3,1,2,3}, {2,3}), {3,1,2,3})
        eq(L{1,2,3,1,2,3}:differenceBy(eqmod2, {1,2}), {3,1,2,3})
        eq(L{1,2,3,1,2,3}:differenceBy(eqmod2, {2,1}), {3,1,2,3})
        eq(L{1,2,3,1,2,3}:differenceBy(eqmod2, {2,3}), {3,1,2,3})
        eq(L{1,2,3,1,2,3}:differenceBy(eqmod2, {2,3}), {3,1,2,3})
    end
    -- unionBy
    do
        local function eqmod2(a, b) return a%2 == b%2 end
        eq(L.unionBy(eqmod2, {1,2,3,1},{2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1})
        eq(L.unionBy(eqmod2, {1,2,3,1},{}), {1,2,3,1})
        eq(L.unionBy(eqmod2, {},{2,3,4,2,3,5,2,3,4,2,3,5}), {2,3})
        eq(L{1,2,3,1}:unionBy(eqmod2, {2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1})
        eq(L{1,2,3,1}:unionBy(eqmod2, {}), {1,2,3,1})
        eq(L{}:unionBy(eqmod2, {2,3,4,2,3,5,2,3,4,2,3,5}), {2,3})
    end
    -- intersectBy
    do
        local function eqmod2(a, b) return a%2 == b%2 end
        eq(L.intersectBy(eqmod2, {1,2,3,1,3,2},{2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1,3,2})
        eq(L.intersectBy(eqmod2, {1,2,3,1},{}), {})
        eq(L.intersectBy(eqmod2, {},{2,3,4,2,3,5,2,3,4,2,3,5}), {})
        eq(L{1,2,3,1,3,2}:intersectBy(eqmod2, {2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1,3,2})
        eq(L{1,2,3,1}:intersectBy(eqmod2, {}), {})
        eq(L{}:intersectBy(eqmod2, {2,3,4,2,3,5,2,3,4,2,3,5}), {})
    end
    -- groupBy
    do
        local function eqmod2(a, b) return a%2 == b%2 end
        eq(L.groupBy(eqmod2, {1,2,3,3,2,3,3,2,4,4,2}), {{1},{2},{3,3},{2},{3,3},{2,4,4,2}})
        eq(L.groupBy(eqmod2, {1,2,3,3,2,3,3,2,4,4,2,2}), {{1},{2},{3,3},{2},{3,3},{2,4,4,2,2}})
        eq(L.groupBy(eqmod2, {}), {})
        eq(L.groupBy(eqmod2, {1}), {{1}})
        eq(L{1,2,3,3,2,3,3,2,4,4,2}:groupBy(eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2}})
        eq(L{1,2,3,3,2,3,3,2,4,4,2,2}:groupBy(eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2,2}})
        eq(L{}:groupBy(eqmod2), {})
        eq(L{1}:groupBy(eqmod2), {{1}})
    end
    -- sortBy
    do
        local function ge(a, b) return a >= b end
        eq(L.sortBy(ge, {1,6,4,3,2,5}), {6,5,4,3,2,1})
        eq(L{1,6,4,3,2,5}:sortBy(ge), {6,5,4,3,2,1})
    end
    -- insertBy
    do
        local function le(a, b) return a <= b end
        eq(L.insertBy(le, 4, {1,2,3,5,6,7}), {1,2,3,4,5,6,7})
        eq(L.insertBy(le, 0, {1,2,3,5,6,7}), {0,1,2,3,5,6,7})
        eq(L.insertBy(le, 8, {1,2,3,5,6,7}), {1,2,3,5,6,7,8})
        eq(L{1,2,3,5,6,7}:insertBy(le, 4), {1,2,3,4,5,6,7})
        eq(L{1,2,3,5,6,7}:insertBy(le, 0), {0,1,2,3,5,6,7})
        eq(L{1,2,3,5,6,7}:insertBy(le, 8), {1,2,3,5,6,7,8})
    end
    -- maximumBy
    do
        local function le(a, b) return a <= b end
        eq(L.maximumBy(le, {1,2,3,4,5,3,0,-1,-2,-3,2,1}), 5)
        eq(L.maximumBy(le, {}), nil)
        eq(L{1,2,3,4,5,3,0,-1,-2,-3,2,1}:maximumBy(le), 5)
        eq(L{}:maximumBy(le), nil)
    end
    -- minimumBy
    do
        local function le(a, b) return a <= b end
        eq(L.minimumBy(le, {1,2,3,4,5,3,0,-1,-2,-3,2,1}), -3)
        eq(L.minimumBy(le, {}), nil)
        eq(L{1,2,3,4,5,3,0,-1,-2,-3,2,1}:minimumBy(le), -3)
        eq(L{}:minimumBy(le), nil)
    end
end

---------------------------------------------------------------------
-- Run all tests
---------------------------------------------------------------------

return function()
    basic_functions()
    list_transformations()
    reducing_lists()
    special_folds()
    building_lists()
    sublists()
    predicates()
    searching_lists()
    indexing_lists()
    zipping_and_unzipping_lists()
    functions_on_strings()
    set_operations()
    ordered_lists()
    generalized_functions()
end
