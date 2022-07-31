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

---------------------------------------------------------------------
-- fun
---------------------------------------------------------------------
local fun = require "fun"

return function()

    do
        local k = fun.const(42, 43)
        local x, y = k(1000)
        eq({x, y}, {42, 43})

        local x, y = fun.id(44, 45)
        eq({x, y}, {44, 45})
    end

    do
        local t = {z=1, y=2, x=3, c=4, b=5, a=6}
        eq(fun.keys(t), {"a", "b", "c", "x", "y", "z"})
        eq(fun.values(t), {6, 5, 4, 3, 2, 1})
        local ks = fun.keys(t)
        local vs = fun.values(t)
        for k, v in fun.pairs(t) do
            eq(k, table.remove(ks, 1))
            eq(v, table.remove(vs, 1))
        end
    end

    eq(fun.concat({1,2,3}, {4}, {5, 6}), {1, 2, 3, 4, 5, 6})
    eq(fun.merge({a=1, b=2}, {c=3}, {b=4, d=5}), {a=1, b=4, c=3, d=5})
    eq(fun.flatten({1,{2},{{3,4},5},{{{{6}}}}}), {1,2,3,4,5,6})
    eq(fun.replicate(3, 42), {42, 42, 42})

    eq(fun.compose(function(x) return x+1 end, function(x) return 2*x end)(42), 85)

    eq(fun.map(function(x) return x+10 end, {1,2,3,4}), {11, 12, 13, 14})
    eq(fun.map({1,2,3,4}, function(x) return x+10 end), {11, 12, 13, 14})
    eq(fun.filter(function(x) return x%2==0 end, {1,2,3,4}), {2, 4})
    eq(fun.filter({1,2,3,4}, function(x) return x%2==0 end), {2, 4})
    do
        local t = {}
        fun.foreach({1,2,3,4}, function(x) table.insert(t, "test 1 iteration "..x) end)
        fun.foreach(function(x) table.insert(t, "test 2 iteration "..x) end, {1,2,3,4})
        eq(t, {
            "test 1 iteration 1", "test 1 iteration 2", "test 1 iteration 3", "test 1 iteration 4",
            "test 2 iteration 1", "test 2 iteration 2", "test 2 iteration 3", "test 2 iteration 4",
        })
    end

    eq(fun.tmap(function(x) return x+10 end, {a=1,b=2,c=3,d=4}), {a=11,b=12,c=13,d=14})
    eq(fun.tmap({a=1,b=2,c=3,d=4}, function(x) return x+10 end), {a=11,b=12,c=13,d=14})
    eq(fun.tfilter(function(x) return x%2==0 end, {a=1,b=2,c=3,d=4}), {b=2,d=4})
    eq(fun.tfilter({a=1,b=2,c=3,d=4}, function(x) return x%2==0 end), {b=2,d=4})
    do
        local t = {}
        fun.tforeach({a=1,b=2,c=3,d=4}, function(x) table.insert(t, "test 1 iteration "..x) end)
        fun.tforeach(function(x) table.insert(t, "test 2 iteration "..x) end, {1,2,3,4})
        eq(t, {
            "test 1 iteration 1", "test 1 iteration 2", "test 1 iteration 3", "test 1 iteration 4",
            "test 2 iteration 1", "test 2 iteration 2", "test 2 iteration 3", "test 2 iteration 4",
        })
    end

    eq(fun.prefix"xxx"("foo"), "xxxfoo")
    eq(fun.suffix"xxx"("foo"), "fooxxx")

    eq(fun.range(3, 6), {3,4,5,6})
    eq(fun.range(3, 6, 1), {3,4,5,6})
    eq(fun.range(3, 6, 2), {3,5})
    eq(fun.range(3, 7, 2), {3,5,7})
    eq(fun.range(3, 6, 0.5), {3,3.5,4,4.5,5,5.5,6})
    eq(fun.range(6, 3), {6,5,4,3})
    eq(fun.range(6, 3, -1), {6,5,4,3})
    eq(fun.range(6, 3, -2), {6,4})
    eq(fun.range(7, 3, -2), {7,5,3})
    eq(fun.range(6, 3, -0.5), {6,5.5,5,4.5,4,3.5,3})

    eq(fun.I{}"foo = $(foo); 1 + 1 = $(1+1)", "foo = $(foo); 1 + 1 = 2")
    eq(fun.I{bar="aaa"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = $(foo); 1 + 1 = 2")
    eq(fun.I{foo="aaa"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = aaa; 1 + 1 = 2")
    eq(fun.I{foo="aaa", bar="bbb"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = aaa; 1 + 1 = 2")
    eq(fun.I{foo="aaa"}{bar="bbb"}"foo = $(foo); 1 + 1 = $(1+1); bar = $(bar)", "foo = aaa; 1 + 1 = 2; bar = bbb")

end
