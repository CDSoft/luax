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

local F = require "fun"

require "test"

---------------------------------------------------------------------
-- Basic data types
---------------------------------------------------------------------

local function basic_data_types()

    eq(F.op.land(false, false), false)
    eq(F.op.land(false, true), false)
    eq(F.op.land(true, false), false)
    eq(F.op.land(true, true), true)

    eq(F.op.lor(false, false), false)
    eq(F.op.lor(false, true), true)
    eq(F.op.lor(true, false), true)
    eq(F.op.lor(true, true), true)

    eq(F.op.lxor(false, false), false)
    eq(F.op.lxor(false, true), true)
    eq(F.op.lxor(true, false), true)
    eq(F.op.lxor(true, true), false)

    eq(F.op.lnot(false), true)
    eq(F.op.lnot(true), false)

    for a = 0, 255 do
        for b = 0, 255 do
            eq(F.op.band(a, b), a & b)
            eq(F.op.bor(a, b), a | b)
            eq(F.op.bxor(a, b), a ~ b)
            eq(F.op.bnot(a), ~a)
            eq(F.op.shl(a, b), a << b)
            eq(F.op.shr(a, b), a >> b)
        end
    end

    local function odd(x) if x%2 == 1 then return x end end
    eq(F.maybe(42, odd, 0), 42)
    eq(F.maybe(42, odd, 1), 1)
    eq(F.maybe(42, odd, 2), 42)
    eq(F.maybe(42, odd, 3), 3)

    eq(F.default(42, nil), 42)
    eq(F.default(42, 43), 43)

    eq(F.fst{4,5,6}, 4)
    eq(F.snd{4,5,6}, 5)
    eq(F.trd{4,5,6}, 6)

end

---------------------------------------------------------------------
-- Basic type classes
---------------------------------------------------------------------

local function basic_type_classes()

    eq(F.op.eq(1,1), true)
    eq(F.op.eq(1,2), false)

    eq(F.op.ne(1,1), false)
    eq(F.op.ne(1,2), true)

    eq(F.comp(1, 0), 1)
    eq(F.comp(1, 1), 0)
    eq(F.comp(1, 2), -1)

    eq(F.op.lt(1, 0), false)
    eq(F.op.lt(1, 1), false)
    eq(F.op.lt(1, 2), true)

    eq(F.op.le(1, 0), false)
    eq(F.op.le(1, 1), true)
    eq(F.op.le(1, 2), true)

    eq(F.op.gt(1, 0), true)
    eq(F.op.gt(1, 1), false)
    eq(F.op.gt(1, 2), false)

    eq(F.op.ge(1, 0), true)
    eq(F.op.ge(1, 1), true)
    eq(F.op.ge(1, 2), false)

    eq(F.max(1, 0), 1)
    eq(F.max(1, 1), 1)
    eq(F.max(1, 2), 2)

    eq(F.min(1, 0), 0)
    eq(F.min(1, 1), 1)
    eq(F.min(1, 2), 1)

    eq(F.succ(42), 43)
    eq(F.pred(42), 41)

    eq(F.op.ueq({1,2}, {1,2}), true)
    eq(F.op.ueq({1,2}, {1,3}), false)

    eq(F.op.une({1,2}, {1,2}), false)
    eq(F.op.une({1,2}, {1,3}), true)

    eq(F.op.ult({1,2}, {1,1}), false)
    eq(F.op.ult({1,2}, {1,2}), false)
    eq(F.op.ult({1,2}, {1,3}), true)

    eq(F.op.ule({1,2}, {1,1}), false)
    eq(F.op.ule({1,2}, {1,2}), true)
    eq(F.op.ule({1,2}, {1,3}), true)

    eq(F.op.ugt({1,2}, {1,1}), true)
    eq(F.op.ugt({1,2}, {1,2}), false)
    eq(F.op.ugt({1,2}, {1,3}), false)

    eq(F.op.uge({1,2}, {1,1}), true)
    eq(F.op.uge({1,2}, {1,2}), true)
    eq(F.op.uge({1,2}, {1,3}), false)

    eq(F.ucomp({1,2}, {1,1}), 1)
    eq(F.ucomp({1,2}, {1,2}), 0)
    eq(F.ucomp({1,2}, {1,3}), -1)

end

---------------------------------------------------------------------
-- Numeric type classes
---------------------------------------------------------------------

local function numeric_type_classes()

    local mathx = require "mathx"

    eq(F.op.add(3, 4), 7)
    eq(F.op.sub(3, 4), -1)
    eq(F.op.mul(3, 4), 12)
    eq(F.op.div(3, 4), 3/4)
    eq(F.op.idiv(3, 4), 0)
    eq(F.op.idiv(13, 4), 3)
    eq(F.op.mod(12, 4), 0)
    eq(F.op.mod(13, 4), 1)
    eq(F.op.mod(14, 4), 2)
    eq(F.op.mod(15, 4), 3)
    eq(F.op.mod(16, 4), 0)
    eq(F.op.neg(-10), 10)
    eq(F.op.neg(10), -10)
    eq(F.negate(-10), 10)
    eq(F.negate(10), -10)

    eq(F.abs(-10), 10)
    eq(F.abs(0), 0)
    eq(F.abs(10), 10)
    eq(F.signum(-10), -1)
    eq(F.signum(0), 0)
    eq(F.signum(10), 1)

    eq({F.quot_rem(17, 3)}, {5, 2})
    eq({F.quot_rem(17, -3)}, {-5, 2})
    eq({F.quot_rem(-17, 3)}, {-5, -2})
    eq({F.quot_rem(-17, -3)}, {5, -2})
    for a = -20, 20 do
        for b = -10, 10 do
            if b ~= 0 then
                local q, r = F.quot_rem(a, b)
                eq(b*q + r, a)
                assert(math.abs(r) < math.abs(b))
                assert(F.signum(q)*F.signum(a*b) >= 0)
                assert(F.signum(r)*F.signum(a) >= 0)
                eq(F.quot(a, b), q)
                eq(F.rem(a, b), r)
            end
        end
    end

    eq({F.div_mod(17, 3)}, {5, 2})
    eq({F.div_mod(17, -3)}, {-6, -1})
    eq({F.div_mod(-17, 3)}, {-6, 1})
    eq({F.div_mod(-17, -3)}, {5, -2})
    for a = -20, 20 do
        for b = -10, 10 do
            if b ~= 0 then
                local q, r = F.div_mod(a, b)
                eq(b*q + r, a)
                assert(math.abs(r) < math.abs(b))
                assert(F.signum(q)*F.signum(a*b) >= 0)
                assert(F.signum(r)*F.signum(b) >= 0)
                eq(F.div(a, b), q)
                eq(F.mod(a, b), r)
            end
        end
    end

    eq(F.recip(16), 1/16)
    eq(F.recip(1/16), 16)
    eq(F.recip(0), 1/0) -- inf

    eq(F.pi, math.pi)
    for i = -100, 100 do
        local x = 0.1*i
        eq(F.exp(x), math.exp(x))
        if x > 0 then eq(F.log(x), math.log(x)) end
        if x > 0 then eq(F.log(x, 42), math.log(x, 42)) end
        if x > 0 then eq(F.log10(x), math.log(x, 10)) end
        if x > 0 then eq(F.log2(x), math.log(x, 2)) end
        if x >= 0 then eq(F.sqrt(x), math.sqrt(x)) end
        for y = -10, 10 do
            eq(F.op.pow(x, y), x^y)
        end
        if x > 0 then
            for b = 0.1, 10, 0.1 do
                eq(F.log(x, b), math.log(x, b))
            end
        end
        eq(F.sin(x), math.sin(x))
        eq(F.cos(x), math.cos(x))
        eq(F.tan(x), math.tan(x))
        if -1 <= x and x <= 1 then
            eq(F.asin(x), math.asin(x))
            eq(F.acos(x), math.acos(x))
        end
        eq(F.atan(x), math.atan(x))
        eq(F.sinh(x), mathx.sinh(x))
        eq(F.cosh(x), mathx.cosh(x))
        eq(F.tanh(x), mathx.tanh(x))
        eq(F.asinh(x), mathx.asinh(x))
        if x >= 1 then eq(F.acosh(x), mathx.acosh(x)) end
        if -1 <= x and x <= 1 then eq(F.atanh(x), mathx.atanh(x)) end
    end

    eq({F.proper_fraction(10.25)}, {10, 0.25})
    eq({F.proper_fraction(-10.25)}, {-10, -0.25})
    eq(F.truncate(10.25), 10)
    eq(F.truncate(-10.25), -10)
    eq(F.round(10.25), 10)
    eq(F.round(-10.25), -10)
    eq(F.round(10.75), 11)
    eq(F.round(-10.75), -11)
    eq(F.round(10.5), 11)
    eq(F.round(-10.5), -11)
    eq(F.round(11.5), 12)
    eq(F.round(-11.5), -12)
    eq(F.ceiling(10.25), 11)
    eq(F.ceiling(-10.25), -10)
    eq(F.ceiling(10.75), 11)
    eq(F.ceiling(-10.75), -10)
    eq(F.ceiling(10.5), 11)
    eq(F.ceiling(-10.5), -10)
    eq(F.ceiling(11.5), 12)
    eq(F.ceiling(-11.5), -11)
    eq(F.floor(10.25), 10)
    eq(F.floor(-10.25), -11)
    eq(F.floor(10.75), 10)
    eq(F.floor(-10.75), -11)
    eq(F.floor(10.5), 10)
    eq(F.floor(-10.5), -11)
    eq(F.floor(11.5), 11)
    eq(F.floor(-11.5), -12)

    eq(F.is_nan(42), false)
    eq(F.is_nan(0/0), true)
    eq(F.is_nan(1/0), false)
    eq(F.is_infinite(42), false)
    eq(F.is_infinite(0/0), false)
    eq(F.is_infinite(1/0), true)
    eq(F.is_normalized(1), true)
    eq(F.is_normalized(0x1p-1024), false)           assert(0x1p-1024 > 0)
    eq(F.is_denormalized(1), false)
    eq(F.is_denormalized(0x1p-1024), true)
    eq(F.is_negative_zero(-0x0p0), true)
    eq(F.is_negative_zero(0x0p0), false)

    eq(F.even(12), true)
    eq(F.even(13), false)
    eq(F.odd(12), false)
    eq(F.odd(13), true)

    eq(F.gcd(12, 8), 4)
    eq(F.gcd(-12, 8), 4)
    eq(F.gcd(12, -8), 4)
    eq(F.gcd(-12, -8), 4)
    eq(F.lcm(12, 8), 24)
    eq(F.lcm(-12, 8), 24)
    eq(F.lcm(12, -8), 24)
    eq(F.lcm(-12, -8), 24)

end

---------------------------------------------------------------------
-- Miscellaneous functions
---------------------------------------------------------------------

local function miscellaneous_functions()

    eq({F.id(10, 20, 30)}, {10, 20, 30})
    eq({F.const(11, 22, 33)("ignored")}, {11, 22, 33})

    local function h(x, y) return x+1, y+2 end
    local function g(x, y) return x*10, y*20 end
    local function f(x, y) return {x,x}, {y,y,y} end
    eq({F.compose{f, g, h}(100, 200)}, {{1010,1010},{4040,4040,4040}})

    eq(F.flip(function(a, b, c, d) return table.concat({a, b, c, d}, "-") end)(1,2,3,4), "2-1-3-4")

    local s3 = function(a, b, c) return a+b+c end
    eq(F.curry(s3)(1)(2, 3), 6)
    eq(F.curry(F.curry(s3)(1))(2)(3), 6)
    local s2 = function(a) return function(b) return a+b end end
    eq(F.uncurry(s2)(1, 2), 3)

    eq({F.call(s3, 10, 11, 12)}, {33})
    eq({F.call(h, 10, 11)}, {11, 13})

    local p = function(x) return x > 1000 end
    local d = function(x) return x*2 end
    eq(F.until_(p, d, 1), 1024)

    eq(F.op.concat("ab", "cd"), "abcd")
    eq(F.op.concat(F{1,2}, F{3,4}), {1,2,3,4})

    eq(F.op.len("abcd"), 4)
    eq(F.op.len({1,2,3,4,5,6}), 6)

    eq(F.prefix("ab")("cd"), "abcd")
    eq(F.suffix("ab")("cd"), "cdab")

    local imath = require "imath"
    local ps = require "ps"

    local function fib(n) return n <= 1 and imath.new(n) or fib(n-1) + fib(n-2) end
    fib = F.memo1(fib)

    eq(fib(0), imath.new"0")
    eq(fib(1), imath.new"1")
    eq(fib(2), imath.new"1")
    eq(fib(3), imath.new"2")
    eq(fib(4), imath.new"3")
    eq(fib(5), imath.new"5")
    eq(fib(6), imath.new"8")

    local fib100
    local dt = ps.profile(function() fib100 = fib(100) end) -- this should be fast because of memoization
    assert(dt < 1.0, "the memoized fibonacci suite takes too much time")
    eq(fib100, imath.new"354224848179261915075")

end

---------------------------------------------------------------------
-- Convert to and from string
---------------------------------------------------------------------

local function convert_to_and_from_string()

    eq(F.show(42), "42")
    eq(F.show({1, x=2, 3}), "{1, 3, x=2}")
    eq(F.show({1, x=2, 3, p={x=1.5, y=2.5}}), "{1, 3, p={x=1.5, y=2.5}, x=2}")

    eq(F.read("42"), 42)
    eq(F.read("{1, 3, x=2}"), {1, x=2, 3})
    eq(F.read("{1, 3, p={x=1.5, y=2.5}, x=2}"), {1, 3, p={x=1.5, y=2.5}, x=2})

    local t = {
        [{1,1}]   = 1,
        [{1,2}]   = 2,
        [{1,2,3}] = 3,
        [{2,1}]   = 4,
        [{2,2}]   = 5,
    }
    eq(F.show(t), "{[{1, 1}]=1, [{1, 2}]=2, [{1, 2, 3}]=3, [{2, 1}]=4, [{2, 2}]=5}")

end

---------------------------------------------------------------------
-- Table construction
---------------------------------------------------------------------

local function clone()

    local t1 = {1,2,x=3,y=4,p={a=10,b=20}}

    local t2 = F.clone(t1)
    local t3 = F(t1):clone()
    eq(t2, t1) assert(t2 ~= t1) assert(t2.p == t1.p)
    eq(t3, t1) assert(t3 ~= t1) assert(t3.p == t1.p)

    local t4 = F.deep_clone(t1)
    local t5 = F(t1):deep_clone()
    eq(t4, t1) assert(t4 ~= t1) assert(t4.p ~= t1.p)
    eq(t5, t1) assert(t5 ~= t1) assert(t5.p ~= t1.p)

end

local function table_construction()

    clone()

    eq(F.rep(5, 42), {42,42,42,42,42})

    eq(F.range(5), {1,2,3,4,5})
    eq(F.range(5, 9), {5,6,7,8,9})
    eq(F.range(5, 9, 2), {5,7,9})
    eq(F.range(9, 5), {9,8,7,6,5})
    eq(F.range(9, 5, -2), {9,7,5})

    eq(F.concat{{1,2},{3,4},{5,6}}, {1,2,3,4,5,6})
    eq(F{{1,2},{3,4},{5,6}}:concat(), {1,2,3,4,5,6})
    eq(F{1,2}..F{3,4}..F{5,6}, {1,2,3,4,5,6})

    local xss = F{1,{2,3,{{4,5,6},7},8},{{}},9}
    eq(F.flatten(xss), {1,2,3,4,5,6,7,8,9})
    eq(xss:flatten(), {1,2,3,4,5,6,7,8,9})

    eq(F.str{"ab", "cd", "ef"}, "abcdef")
    eq(F{"ab", "cd", "ef"}:str(), "abcdef")
    eq(F.str({"ab", "cd", "ef"}, "/"), "ab/cd/ef")
    eq(F{"ab", "cd", "ef"}:str"/", "ab/cd/ef")

    eq(F{"a", "b", "c"}:from_set(string.upper), {a="A", b="B", c="C"})

    eq(F{{"a","aa"}, {"b","bb"}}:from_list(), {a="aa", b="bb"})

end

---------------------------------------------------------------------
-- Table iterators
---------------------------------------------------------------------

local function table_iterators()

    local t = {"a", "b", "c", x=1, y=2}

    local array1 = {}
    for i, v in F.ipairs(t) do table.insert(array1, {i, v}) end
    eq(array1, {{1,"a"},{2,"b"},{3,"c"}})
    local array2 = {}
    for i, v in F(t):ipairs() do table.insert(array2, {i, v}) end
    eq(array2, {{1,"a"},{2,"b"},{3,"c"}})

    local table1 = {}
    for k, v in F.pairs(t) do table1[k] = v end
    eq(table1, t)
    local table2 = {}
    for k, v in F(t):pairs() do table2[k] = v end
    eq(table2, t)

    eq(F.keys(t), {1,2,3,"x","y"})
    eq(F(t):keys(), {1,2,3,"x","y"})
    eq(F.values(t), {"a","b","c",1,2})
    eq(F(t):values(), {"a","b","c",1,2})
    eq(F.items(t), {{1,"a"},{2,"b"},{3,"c"},{"x",1},{"y",2}})
    eq(F(t):items(), {{1,"a"},{2,"b"},{3,"c"},{"x",1},{"y",2}})

end

---------------------------------------------------------------------
-- Table extraction
---------------------------------------------------------------------

local function table_extraction()

    local t = {"a","b","c"}

    eq(F.head(t), "a")
    eq(F(t):head(), "a")
    eq(F.last(t), "c")
    eq(F(t):last(), "c")
    eq(F.tail(t), {"b", "c"})
    eq(F(t):tail(), {"b", "c"})
    eq(F.init(t), {"a", "b"})
    eq(F(t):init(), {"a", "b"})
    eq({F.uncons(t)}, {"a", {"b","c"}})
    eq({F(t):uncons()}, {"a", {"b","c"}})

    local xs = F{10, 20, 30, 40}

    eq(F.take(0, xs), {})
    eq(xs:take(0), {})
    eq(F.take(2, xs), {10, 20})
    eq(xs:take(2), {10, 20})
    eq(F.take(#xs, xs), xs)
    eq(xs:take(#xs), xs)
    eq(F.take(#xs+1, xs), xs)
    eq(xs:take(#xs+1), xs)

    eq(F.drop(0, xs), xs)
    eq(xs:drop(0), xs)
    eq(F.drop(2, xs), {30, 40})
    eq(xs:drop(2), {30, 40})
    eq(F.drop(#xs, xs), {})
    eq(xs:drop(#xs), {})
    eq(F.drop(#xs+1, xs), {})
    eq(xs:drop(#xs+1), {})

    eq({F.split_at(0, xs)}, {{}, xs})
    eq({xs:split_at(0)}, {{}, xs})
    eq({F.split_at(2, xs)}, {{10, 20}, {30, 40}})
    eq({xs:split_at(2)}, {{10, 20}, {30, 40}})
    eq({F.split_at(#xs, xs)}, {xs, {}})
    eq({xs:split_at(#xs)}, {xs, {}})

    local function le(n) return function(k) return k <= n end end
    local function ge(n) return function(k) return k >= n end end

    eq(F.take_while(le(20), xs), {10, 20})
    eq(xs:take_while(le(20)), {10, 20})

    eq(F.drop_while(le(20), xs), {30, 40})
    eq(xs:drop_while(le(20)), {30, 40})

    eq(F.drop_while_end(ge(30), xs), {10, 20})
    eq(xs:drop_while_end(ge(30)), {10, 20})

    eq({F.span(le(20), xs)}, {{10, 20}, {30, 40}})
    eq({xs:span(le(20))}, {{10, 20}, {30, 40}})

    eq({F.break_(ge(30), xs)}, {{10, 20}, {30, 40}})
    eq({xs:break_(ge(30))}, {{10, 20}, {30, 40}})

    eq(F.strip_prefix({10, 20}, xs), {30, 40})
    eq(xs:strip_prefix({10, 20}), {30, 40})
    eq(F.strip_prefix({10, 21}, xs), nil)
    eq(xs:strip_prefix({10, 21}), nil)

    eq(F.strip_suffix({30, 40}, xs), {10, 20})
    eq(xs:strip_suffix({30, 40}), {10, 20})
    eq(F.strip_suffix({30, 41}, xs), nil)
    eq(xs:strip_suffix({30, 41}), nil)

    eq(F.group{1,2,2,3,4,4,4,5,6,7,7,7,7,7,8}, {{1},{2,2},{3},{4,4,4},{5},{6},{7,7,7,7,7},{8}})
    eq(F{1,2,2,3,4,4,4,5,6,7,7,7,7,7,8}:group(), {{1},{2,2},{3},{4,4,4},{5},{6},{7,7,7,7,7},{8}})

    eq(F.inits(xs), {{},{10},{10,20},{10,20,30},{10,20,30,40}})
    eq(xs:inits(), {{},{10},{10,20},{10,20,30},{10,20,30,40}})

    eq(F.tails(xs), {{10,20,30,40},{20,30,40},{30,40},{40},{}})
    eq(xs:tails(), {{10,20,30,40},{20,30,40},{30,40},{40},{}})

end

---------------------------------------------------------------------
-- Table predicates
---------------------------------------------------------------------

local function table_predicates()

    local xs = {1,2,3,4}

    eq(F.is_prefix_of({}, xs), true)
    eq(F.is_prefix_of({1,2}, xs), true)
    eq(F.is_prefix_of({1,2,3,4}, xs), true)
    eq(F.is_prefix_of({1,3}, xs), false)
    eq(F.is_prefix_of({1,2,3,5}, xs), false)
    eq(F.is_prefix_of({1,2,3,4,5}, xs), false)
    eq((F{}):is_prefix_of(xs), true)
    eq((F{1,2}):is_prefix_of(xs), true)
    eq((F{1,2,3,4}):is_prefix_of(xs), true)
    eq((F{1,3}):is_prefix_of(xs), false)
    eq((F{1,2,3,5}):is_prefix_of(xs), false)
    eq((F{1,2,3,4,5}):is_prefix_of(xs), false)

    eq(F.is_suffix_of({}, xs), true)
    eq(F.is_suffix_of({3,4}, xs), true)
    eq(F.is_suffix_of({1,2,3,4}, xs), true)
    eq(F.is_suffix_of({2,4}, xs), false)
    eq(F.is_suffix_of({0,2,3,4}, xs), false)
    eq(F.is_suffix_of({1,2,3,4,5}, xs), false)
    eq((F{}):is_suffix_of(xs), true)
    eq((F{3,4}):is_suffix_of(xs), true)
    eq((F{1,2,3,4}):is_suffix_of(xs), true)
    eq((F{2,4}):is_suffix_of(xs), false)
    eq((F{0,2,3,4}):is_suffix_of(xs), false)
    eq((F{1,2,3,4,5}):is_suffix_of(xs), false)

    eq(F.is_infix_of({}, xs), true)
    eq(F.is_infix_of({2,3}, xs), true)
    eq(F.is_infix_of({1,2,3,4}, xs), true)
    eq(F.is_infix_of({1,2,3,4,5}, xs), false)
    eq(F.is_infix_of({2,4}, xs), false)
    eq((F{}):is_infix_of(xs), true)
    eq((F{2,3}):is_infix_of(xs), true)
    eq((F{1,2,3,4}):is_infix_of(xs), true)
    eq((F{1,2,3,4,5}):is_infix_of(xs), false)
    eq((F{2,4}):is_infix_of(xs), false)

    eq(F.is_subsequence_of({1,2,3}, {0,1,4,2,5,3,6}), true)
    eq(F.is_subsequence_of({1,2,3}, {0,1,4,3,5,2,6}), false)
    eq(F{1,2,3}:is_subsequence_of({0,1,4,2,5,3,6}), true)
    eq(F{1,2,3}:is_subsequence_of({0,1,4,3,5,2,6}), false)

    eq(F{x=1,y=2}:is_submap_of{x=3,y=4}, true)
    eq(F{x=1,y=2}:is_submap_of{x=3,y=4,z=5}, true)
    eq(F{x=1,y=2}:is_submap_of{x=3}, false)
    eq(F{x=1,y=2}:is_submap_of{x=3,z=5}, false)

    eq(F{x=1,y=2}:is_proper_submap_of{x=3,y=4}, false)
    eq(F{x=1,y=2}:is_proper_submap_of{x=3,y=4,z=5}, true)
    eq(F{x=1,y=2}:is_proper_submap_of{x=3}, false)
    eq(F{x=1,y=2}:is_proper_submap_of{x=3,z=5}, false)

end

---------------------------------------------------------------------
-- Table searching
---------------------------------------------------------------------

local function table_searching()

    eq(F.elem(1, {1,2,3}), true)
    eq(F.elem(2, {1,2,3}), true)
    eq(F.elem(3, {1,2,3}), true)
    eq(F.elem(4, {1,2,3}), false)
    eq(F.elem(4, {}), false)
    eq(F{1,2,3}:elem(1), true)
    eq(F{1,2,3}:elem(2), true)
    eq(F{1,2,3}:elem(3), true)
    eq(F{1,2,3}:elem(4), false)
    eq(F{}:elem(4), false)

    eq(F.not_elem(1, {1,2,3}), false)
    eq(F.not_elem(2, {1,2,3}), false)
    eq(F.not_elem(3, {1,2,3}), false)
    eq(F.not_elem(4, {1,2,3}), true)
    eq(F.not_elem(4, {}), true)
    eq(F{1,2,3}:not_elem(1), false)
    eq(F{1,2,3}:not_elem(2), false)
    eq(F{1,2,3}:not_elem(3), false)
    eq(F{1,2,3}:not_elem(4), true)
    eq(F{}:not_elem(4), true)

    eq(F.lookup(2, {}), nil)
    eq(F.lookup(2, {{1, "first"}}), nil)
    eq(F.lookup(2, {{1, "first"}, {2, "second"}, {3, "third"}}), "second")
    eq(F.lookup(4, {{1, "first"}, {2, "second"}, {3, "third"}}), nil)
    eq(F{}:lookup(2), nil)
    eq(F{{1, "first"}}:lookup(2), nil)
    eq(F{{1, "first"}, {2, "second"}, {3, "third"}}:lookup(2), "second")
    eq(F{{1, "first"}, {2, "second"}, {3, "third"}}:lookup(4), nil)

    eq(F.find(function(x) return x > 3 end, {1,2,3,4,5}), 4)
    eq(F.find(function(x) return x > 6 end, {1,2,3,4,5}), nil)
    eq(F.find(function(_) return true end, {}), nil)
    eq(F{1,2,3,4,5}:find(function(x) return x > 3 end), 4)
    eq(F{1,2,3,4,5}:find(function(x) return x > 6 end), nil)
    eq(F{}:find(function(_) return true end), nil)

    eq(F.filter(function(x) return x%2==0 end, {1,2,3,4,5}), {2,4})
    eq(F.filter(function(x) return x%2==0 end, {}), {})
    eq(F{1,2,3,4,5}:filter(function(x) return x%2==0 end), {2,4})
    eq(F{}:filter(function(x) return x%2==0 end), {})

    eq(F.filteri(function(i, x) return i%2==0 end, {11,21,31,41,51}), {21,41})
    eq(F.filteri(function(i, x) return i%2==0 end, {}), {})
    eq(F{11,21,31,41,51}:filteri(function(i, x) return i%2==0 end), {21,41})
    eq(F{}:filteri(function(i, x) return i%2==0 end), {})

    eq(F.filtert(function(x) return x%2==0 end, {x=1,y=2,z=3,t=4}), {y=2,t=4})
    eq(F{x=1,y=2,z=3,t=4}:filtert(function(x) return x%2==0 end), {y=2,t=4})
    eq(F.filtert(function(x) return x%2==0 end, {}), {})
    eq(F{}:filtert(function(x) return x%2==0 end), {})

    eq(F.filterk(function(k, x) return k=="y" and x%2==0 end, {x=1,y=2,z=3,t=4}), {y=2})
    eq(F{x=1,y=2,z=3,t=4}:filterk(function(k, x) return k=="y" and x%2==0 end), {y=2})
    eq(F.filterk(function(k, x) return k=="y" and x%2==0 end, {}), {})
    eq(F{}:filterk(function(k, x) return k=="y" and x%2==0 end), {})

    eq(F.restrict_keys({x=1,y=2}, {"y", "z"}), {y=2})
    eq(F{x=1,y=2}:restrict_keys{"y", "z"}, {y=2})

    eq(F.without_keys({x=1,y=2}, {"y", "z"}), {x=1})
    eq(F{x=1,y=2}:without_keys{"y", "z"}, {x=1})

    eq({F.partition(function(x) return x%2==0 end, {1,2,3,4,5})}, {{2,4},{1,3,5}})
    eq({F.partition(function(_) return true end, {1,2,3,4,5})}, {{1,2,3,4,5},{}})
    eq({F.partition(function(_) return false end, {1,2,3,4,5})}, {{},{1,2,3,4,5}})
    eq({F.partition(function(_) return true end, {})}, {{},{}})
    eq({F{1,2,3,4,5}:partition(function(x) return x%2==0 end)}, {{2,4},{1,3,5}})
    eq({F{1,2,3,4,5}:partition(function(_) return true end)}, {{1,2,3,4,5},{}})
    eq({F{1,2,3,4,5}:partition(function(_) return false end)}, {{},{1,2,3,4,5}})
    eq({F{}:partition(function(_) return true end)}, {{},{}})

    eq({F.table_partition(function(v) return v%2==0 end, {x=1,y=2,z=3,t=4})}, {{y=2,t=4},{x=1,z=3}})
    eq({F{x=1,y=2,z=3,t=4}:table_partition(function(v) return v%2==0 end)}, {{y=2,t=4},{x=1,z=3}})

    eq({F.table_partition_with_key(function(k, v) return k=="y" and v==2 end, {x=1,y=2,z=3,t=4})}, {{y=2},{x=1,t=4,z=3}})
    eq({F{x=1,y=2,z=3,t=4}:table_partition_with_key(function(k, v) return k=="y" and v==2 end)}, {{y=2},{x=1,t=4,z=3}})

    eq(F.elem_index(2, {0,1,2,3,1,2,3}), 3)
    eq(F{0,1,2,3,1,2,3}:elem_index(2), 3)
    eq(F.elem_index(4, {0,1,2,3,1,2,3}), nil)
    eq(F{0,1,2,3,1,2,3}:elem_index(4), nil)

    eq(F.elem_indices(2, {0,1,2,3,1,2,3}), {3, 6})
    eq(F{0,1,2,3,1,2,3}:elem_indices(2), {3, 6})
    eq(F.elem_indices(4, {0,1,2,3,1,2,3}), {})
    eq(F{0,1,2,3,1,2,3}:elem_indices(4), {})

    eq(F.find_index(function(x) return x==2 end, {0,1,2,3,1,2,3}), 3)
    eq(F{0,1,2,3,1,2,3}:find_index(function(x) return x==2 end), 3)
    eq(F.find_index(function(x) return x==4 end, {0,1,2,3,1,2,3}), nil)
    eq(F{0,1,2,3,1,2,3}:find_index(function(x) return x==4 end), nil)

    eq(F.find_indices(function(x) return x==2 end, {0,1,2,3,1,2,3}), {3, 6})
    eq(F{0,1,2,3,1,2,3}:find_indices(function(x) return x==2 end), {3, 6})
    eq(F.find_indices(function(x) return x==4 end, {0,1,2,3,1,2,3}), {})
    eq(F{0,1,2,3,1,2,3}:find_indices(function(x) return x==4 end), {})

end

---------------------------------------------------------------------
-- Table size
---------------------------------------------------------------------

local function table_size()

    local empty_list = {x=1, y=2}
    local empty_table = {}
    local non_empty_list = {1}
    local non_empty_table = {x=1}
    local large_table = {"a","b","c", x="x", y="y", z="y", t="t"}

    eq(F.null(empty_list), false)
    eq(F(empty_list):null(), false)
    eq(F.null(non_empty_list), false)
    eq(F(non_empty_list):null(), false)
    eq(F.null(empty_table), true)
    eq(F(empty_table):null(), true)
    eq(F.null(non_empty_table), false)
    eq(F(non_empty_table):null(), false)

    eq(F.length(large_table), 3)
    eq(F(large_table):length(), 3)

    eq(F.size(large_table), 7)
    eq(F(large_table):size(), 7)

end

---------------------------------------------------------------------
-- Table transformations
---------------------------------------------------------------------

local function table_transformations()

    local xs = F{10,20,30}
    local function f(x) return 2*x end
    local function g(i, x) return f(x) + i end
    local function h(k, x) return k..":"..f(x) end

    eq(F.map(f, xs), {20,40,60})
    eq(xs:map(f), {20,40,60})

    eq(F.mapi(g, xs), {21,42,63})
    eq(xs:mapi(g), {21,42,63})

    local t = F{x=10, y=20, z=30}

    eq(F.mapt(f, t), {x=20,y=40,z=60})
    eq(t:mapt(f), {x=20,y=40,z=60})

    eq(F.mapk(h, t), {x="x:20",y="y:40",z="z:60"})
    eq(t:mapk(h), {x="x:20",y="y:40",z="z:60"})

    eq(F.reverse(xs), {30,20,10})
    eq(xs:reverse(), {30,20,10})

    local m = F{{1,2,3},{4,5,6}}
    eq(F.transpose(m), {{1,4},{2,5},{3,6}})
    eq(m:transpose(), {{1,4},{2,5},{3,6}})
    eq(m:transpose():transpose(), m)

    local clean = function(_) return nil end
    local lower = function(s) return s and s:lower() or "N/A" end
    eq(F.update(lower, "b", {a="A", b="B", c="C"}), {a="A", b="b", c="C"})
    eq(F.update(lower, "z", {a="A", b="B", c="C"}), {a="A", b="B", c="C", z="N/A"})
    eq(F.update(clean, "b", {a="A", b="B", c="C"}), {a="A", c="C"})
    eq(F{a="A", b="B", c="C"}:update(lower, "b"), {a="A", b="b", c="C"})
    eq(F{a="A", b="B", c="C"}:update(lower, "z"), {a="A", b="B", c="C", z="N/A"})
    eq(F{a="A", b="B", c="C"}:update(clean, "b"), {a="A", c="C"})

end

---------------------------------------------------------------------
-- Table reductions (folds)
---------------------------------------------------------------------

local function table_reductions()

    local xs = F{10, 20, 30, 40}
    local function f(a, b) return a+b end
    local function fi(a, i, b) return i+a+b end

    eq(F.fold(f, 1, xs), 101)
    eq(xs:fold(f, 1), 101)

    eq(F.foldi(fi, 1, xs), 111)
    eq(xs:foldi(fi, 1), 111)

    eq(F.fold1(f, xs), 100)
    eq(xs:fold1(f), 100)

    local function g(len, a) return len + #a end

    eq(F.foldt(g, 0, {x="a", y="bbb"}), 4)
    eq(F{x="a", y="bbb"}:foldt(g, 0), 4)

    local function h(res, k, a) return res..k..a end

    eq(F.foldk(h, "Map:", {x="a", y="bbb"}), "Map:xaybbb")
    eq(F{x="a", y="bbb"}:foldk(h, "Map:"), "Map:xaybbb")

    eq(F.land{true,  true,  true }, true)
    eq(F.land{false, true,  true }, false)
    eq(F.land{true,  false, true }, false)
    eq(F.land{true,  false, false}, false)

    eq(F{true,  true,  true }:land(), true)
    eq(F{false, true,  true }:land(), false)
    eq(F{true,  false, true }:land(), false)
    eq(F{true,  false, false}:land(), false)

    eq(F.lor{false, false, false}, false)
    eq(F.lor{true,  false, false}, true)
    eq(F.lor{false, true,  false}, true)
    eq(F.lor{false, false, true }, true)

    eq(F{false, false, false}:lor(), false)
    eq(F{true,  false, false}:lor(), true)
    eq(F{false, true,  false}:lor(), true)
    eq(F{false, false, true }:lor(), true)

    local function le(n) return function(k) return k <= n end end
    local function ge(n) return function(k) return k >= n end end

    eq(F.any(ge(40), xs), true)
    eq(F.any(ge(41), xs), false)
    eq(xs:any(ge(40)), true)
    eq(xs:any(ge(41)), false)

    eq(F.all(ge(10), xs), true)
    eq(F.all(ge(11), xs), false)
    eq(xs:all(ge(10)), true)
    eq(xs:all(ge(11)), false)

    eq(F.sum(xs), 100)
    eq(xs:sum(), 100)

    eq(F.product(xs), 240000)
    eq(xs:product(), 240000)

    eq(F.maximum(xs), 40)
    eq(xs:maximum(), 40)

    eq(F.minimum(xs), 10)
    eq(xs:minimum(), 10)

    eq(F.scan(f, 1, xs), {1,11,31,61,101})
    eq(xs:scan(f, 1), {1,11,31,61,101})

    eq(F.scan1(f, xs), {10,30,60,100})
    eq(xs:scan1(f), {10,30,60,100})

    local numbers = F{"one", "two", "three"}
    local function bang(n) return {n,"!"} end
    eq(F.concat_map(bang, numbers), {"one","!","two","!","three","!"})
    eq(numbers:concat_map(bang), {"one","!","two","!","three","!"})

end

---------------------------------------------------------------------
-- Table zipping
---------------------------------------------------------------------

local function table_zipping()

    eq(F.zip{
        {1,2,3},
        {4,5},
        {6,7,8},
        {9,10,11,12},
        {13,14},
        {15,16},
        {17,18,19},
    }, {
        {1,4,6,9,13,15,17},
        {2,5,7,10,14,16,18},
    })

    eq(F{
        {1,2,3},
        {4,5},
        {6,7,8},
        {9,10,11,12},
        {13,14},
        {15,16},
        {17,18,19},
    }:zip(), {
        {1,4,6,9,13,15,17},
        {2,5,7,10,14,16,18},
    })

    eq({F.unzip{
        {1,2,3,"a","b","c","x"},
        {4,5,6,"d","e","f","y"},
        {7,8,9,"g","h","i","z"},
    }}, {
        {1,4,7},
        {2,5,8},
        {3,6,9},
        {"a","d","g"},
        {"b","e","h"},
        {"c","f","i"},
        {"x","y","z"},
    })

    eq({F{
        {1,2,3,"a","b","c","x"},
        {4,5,6,"d","e","f","y"},
        {7,8,9,"g","h","i","z"},
    }:unzip()}, {
        {1,4,7},
        {2,5,8},
        {3,6,9},
        {"a","d","g"},
        {"b","e","h"},
        {"c","f","i"},
        {"x","y","z"},
    })

    local function rev(...) return F{...}:reverse() end
    eq(F.zip_with(rev, {
        {1,2,3},
        {4,5},
        {6,7,8},
        {9,10,11,12},
        {13,14},
        {15,16},
        {17,18,19},
    }), {
        F{1,4,6,9,13,15,17}:reverse(),
        F{2,5,7,10,14,16,18}:reverse(),
    })
    eq(F{
        {1,2,3},
        {4,5},
        {6,7,8},
        {9,10,11,12},
        {13,14},
        {15,16},
        {17,18,19},
    }:zip_with(rev), {
        F{1,4,6,9,13,15,17}:reverse(),
        F{2,5,7,10,14,16,18}:reverse(),
    })
    eq(F{
        {1,2,3},
        {4,5},
        {6,7,8},
        {9,10,11,12},
        {13,14},
        {15,16},
        {17,18,19},
    }:zip(rev), {
        F{1,4,6,9,13,15,17}:reverse(),
        F{2,5,7,10,14,16,18}:reverse(),
    })

end

---------------------------------------------------------------------
-- Set operations
---------------------------------------------------------------------

local function set_operations()

    eq(F.nub{1,2,3,4,3,2,1,2,4,3,5}, {1,2,3,4,5})
    eq(F{1,2,3,4,3,2,1,2,4,3,5}:nub(), {1,2,3,4,5})

    eq(F.delete('a', {'b','a','n','a','n','a'}), {'b','n','a','n','a'})
    eq(F.delete('c', {'b','a','n','a','n','a'}), {'b','a','n','a','n','a'})
    eq(F.delete('c', {}), {})
    eq(F{'b','a','n','a','n','a'}:delete('a'), {'b','n','a','n','a'})
    eq(F{'b','a','n','a','n','a'}:delete('c'), {'b','a','n','a','n','a'})
    eq(F{}:delete('c'), {})

    eq(F.difference({1,2,3,1,2,3}, {1,2}), {3,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,1}), {3,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,3}), {1,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,3}), {1,1,2,3})
    eq(F{1,2,3,1,2,3}:difference{1,2}, {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference{2,1}, {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference{2,3}, {1,1,2,3})
    eq(F{1,2,3,1,2,3}:difference{2,3}, {1,1,2,3})

    eq(F.union({1,2,3,1},{2,3,4,2,3,5,2,3,4,2,3,5}), {1,2,3,1,4,5})
    eq(F.union({1,2,3,1},{}), {1,2,3,1})
    eq(F.union({},{2,3,4,2,3,5,2,3,4,2,3,5}), {2,3,4,5})
    eq(F{1,2,3,1}:union{2,3,4,2,3,5,2,3,4,2,3,5}, {1,2,3,1,4,5})
    eq(F{1,2,3,1}:union{}, {1,2,3,1})
    eq(F{}:union{2,3,4,2,3,5,2,3,4,2,3,5}, {2,3,4,5})

    eq(F.intersection({1,2,3,1,3,2},{2,3,4,2,3,5,2,3,4,2,3,5}), {2,3,3,2})
    eq(F.intersection({1,2,3,1},{}), {})
    eq(F.intersection({},{2,3,4,2,3,5,2,3,4,2,3,5}), {})
    eq(F{1,2,3,1,3,2}:intersection{2,3,4,2,3,5,2,3,4,2,3,5}, {2,3,3,2})
    eq(F{1,2,3,1}:intersection{}, {})
    eq(F{}:intersection{2,3,4,2,3,5,2,3,4,2,3,5}, {})

end

---------------------------------------------------------------------
-- Table operations
---------------------------------------------------------------------

local function table_operations()

    eq(F.merge{{x=1,y=2},{y=3,z=4}}, {x=1,y=3,z=4})
    eq(F{{x=1,y=2},{y=3,z=4}}:merge(), {x=1,y=3,z=4})

    assert(F.table_union == F.merge)

    local add = function(a, b) return a+b end

    eq(F.merge_with(add, {{x=1,y=2},{y=3,z=4}}), {x=1,y=5,z=4})
    eq(F{{x=1,y=2},{y=3,z=4}}:merge_with(add), {x=1,y=5,z=4})

    assert(F.table_union_with == F.merge_with)

    local addk = function(k, a, b) return k..(a+b) end

    eq(F.merge_with_key(addk, {{x=1,y=2},{y=3,z=4}}), {x=1,y="y5",z=4})
    eq(F{{x=1,y=2},{y=3,z=4}}:merge_with_key(addk), {x=1,y="y5",z=4})

    assert(F.table_union_with_key == F.merge_with_key)

    eq(F.table_difference({x=1,y=2}, {y=3,z=4}), {x=1})
    eq(F{x=1,y=2}:table_difference{y=3,z=4}, {x=1})

    local sub = function(a, b) return a-b end

    eq(F.table_difference_with(sub, {x=1,y=2}, {y=3,z=4}), {x=1,y=-1})
    eq(F{x=1,y=2}:table_difference_with(sub, {y=3,z=4}), {x=1,y=-1})

    local subk = function(k, a, b) return k..(a-b) end

    eq(F.table_difference_with_key(subk, {x=1,y=2}, {y=3,z=4}), {x=1,y="y-1"})
    eq(F{x=1,y=2}:table_difference_with_key(subk, {y=3,z=4}), {x=1,y="y-1"})

    eq(F.table_intersection({x=1,y=2}, {y=3,z=4}), {y=2})
    eq(F{x=1,y=2}:table_intersection{y=3,z=4}, {y=2})

    eq(F.table_intersection_with(sub, {x=1,y=2}, {y=3,z=4}), {y=-1})
    eq(F{x=1,y=2}:table_intersection_with(sub, {y=3,z=4}), {y=-1})

    eq(F.table_intersection_with_key(subk, {x=1,y=2}, {y=3,z=4}), {y="y-1"})
    eq(F{x=1,y=2}:table_intersection_with_key(subk, {y=3,z=4}), {y="y-1"})

    eq(F.disjoint({x=1,y=2}, {y=3,z=4}), false)
    eq(F{x=1,y=2}:disjoint({y=3,z=4}), false)
    eq(F.disjoint({x=1,y=2}, {t=3,z=4}), true)
    eq(F{x=1,y=2}:disjoint({t=3,z=4}), true)

    eq(F.table_compose({a=1,b=2}, {x="a", y="b", z="c"}), {x=1, y=2})
    eq(F{a=1,b=2}:table_compose{x="a", y="b", z="c"}, {x=1, y=2})

end

---------------------------------------------------------------------
-- Ordered_lists
---------------------------------------------------------------------

local function ordered_lists()

    eq(F.sort{1,6,4,3,2,5}, {1,2,3,4,5,6})
    eq(F{1,6,4,3,2,5}:sort(), {1,2,3,4,5,6})

    local function fst(xs) return xs[1] end
    eq(F.sort_on(fst, {{2,"world"},{4,"!"},{1,"Hello"}}), {{1,"Hello"},{2,"world"},{4,"!"}})
    eq(F{{2,"world"},{4,"!"},{1,"Hello"}}:sort_on(fst), {{1,"Hello"},{2,"world"},{4,"!"}})

    eq(F.insert(4, {1,2,3,5,6,7}), {1,2,3,4,5,6,7})
    eq(F.insert(0, {1,2,3,5,6,7}), {0,1,2,3,5,6,7})
    eq(F.insert(8, {1,2,3,5,6,7}), {1,2,3,5,6,7,8})
    eq(F{1,2,3,5,6,7}:insert(4), {1,2,3,4,5,6,7})
    eq(F{1,2,3,5,6,7}:insert(0), {0,1,2,3,5,6,7})
    eq(F{1,2,3,5,6,7}:insert(8), {1,2,3,5,6,7,8})

end

---------------------------------------------------------------------
-- Generalized functions
---------------------------------------------------------------------

local function generalized_functions()

    local function eqmod3(a, b) return a%3 == b%3 end
    eq(F.nub({1,2,3,4,3,2,1,2,4,3,5}, eqmod3), {1,2,3})
    eq(F{1,2,3,4,3,2,1,2,4,3,5}:nub(eqmod3), {1,2,3})

    local function eqchar(a, b) return a:lower() == b:lower() end
    eq(F.delete('A', {'b','A','n','a','n','a'}, eqchar), {'b','n','a','n','a'})
    eq(F.delete('C', {'b','A','n','a','n','a'}, eqchar), {'b','A','n','a','n','a'})
    eq(F.delete('C', {}, eqchar), {})
    eq(F{'b','A','n','a','n','a'}:delete('A', eqchar), {'b','n','a','n','a'})
    eq(F{'b','A','n','a','n','a'}:delete('C', eqchar), {'b','A','n','a','n','a'})
    eq(F{}:delete('C', eqchar), {})

    local function eqmod2(a, b) return a%2 == b%2 end
    eq(F.difference({1,2,3,1,2,3}, {1,2}, eqmod2), {3,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,1}, eqmod2), {3,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,3}, eqmod2), {3,1,2,3})
    eq(F.difference({1,2,3,1,2,3}, {2,3}, eqmod2), {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference({1,2}, eqmod2), {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference({2,1}, eqmod2), {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference({2,3}, eqmod2), {3,1,2,3})
    eq(F{1,2,3,1,2,3}:difference({2,3}, eqmod2), {3,1,2,3})

    eq(F.union({1,2,3,1},{2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {1,2,3,1})
    eq(F.union({1,2,3,1},{}, eqmod2), {1,2,3,1})
    eq(F.union({},{2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {2,3})
    eq(F{1,2,3,1}:union({2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {1,2,3,1})
    eq(F{1,2,3,1}:union({}, eqmod2), {1,2,3,1})
    eq(F{}:union({2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {2,3})

    eq(F.intersection({1,2,3,1,3,2},{2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {1,2,3,1,3,2})
    eq(F.intersection({1,2,3,1},{}, eqmod2), {})
    eq(F.intersection({},{2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {})
    eq(F{1,2,3,1,3,2}:intersection({2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {1,2,3,1,3,2})
    eq(F{1,2,3,1}:intersection({}, eqmod2), {})
    eq(F{}:intersection({2,3,4,2,3,5,2,3,4,2,3,5}, eqmod2), {})

    eq(F.group({1,2,3,3,2,3,3,2,4,4,2}, eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2}})
    eq(F.group({1,2,3,3,2,3,3,2,4,4,2,2}, eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2,2}})
    eq(F.group({}, eqmod2), {})
    eq(F.group({1}, eqmod2), {{1}})
    eq(F{1,2,3,3,2,3,3,2,4,4,2}:group(eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2}})
    eq(F{1,2,3,3,2,3,3,2,4,4,2,2}:group(eqmod2), {{1},{2},{3,3},{2},{3,3},{2,4,4,2,2}})
    eq(F{}:group(eqmod2), {})
    eq(F{1}:group(eqmod2), {{1}})

    local function ge(a, b) return a >= b end
    eq(F.sort({1,6,4,3,2,5}, ge), {6,5,4,3,2,1})
    eq(F{1,6,4,3,2,5}:sort(ge), {6,5,4,3,2,1})

    local function le(a, b) return a <= b end
    eq(F.insert(4, {1,2,3,5,6,7}, le), {1,2,3,4,5,6,7})
    eq(F.insert(0, {1,2,3,5,6,7}, le), {0,1,2,3,5,6,7})
    eq(F.insert(8, {1,2,3,5,6,7}, le), {1,2,3,5,6,7,8})
    eq(F{1,2,3,5,6,7}:insert(4, le), {1,2,3,4,5,6,7})
    eq(F{1,2,3,5,6,7}:insert(0, le), {0,1,2,3,5,6,7})
    eq(F{1,2,3,5,6,7}:insert(8, le), {1,2,3,5,6,7,8})

    eq(F.maximum({1,2,3,4,5,3,0,-1,-2,-3,2,1}, le), 5)
    eq(F.maximum({}, le), nil)
    eq(F{1,2,3,4,5,3,0,-1,-2,-3,2,1}:maximum(le), 5)
    eq(F{}:maximum(le), nil)

    eq(F.minimum({1,2,3,4,5,3,0,-1,-2,-3,2,1}, le), -3)
    eq(F.minimum({}, le), nil)
    eq(F{1,2,3,4,5,3,0,-1,-2,-3,2,1}:minimum(le), -3)
    eq(F{}:minimum(le), nil)

end

---------------------------------------------------------------------
-- Miscellaneous table functions
---------------------------------------------------------------------

local function miscellaneous_table_functions()

    local xs = F{10,20,30}

    eq(F.subsequences(xs), {{}, {10}, {20}, {10,20}, {30}, {10,30}, {20,30}, {10,20,30}})
    eq(xs:subsequences(), {{}, {10}, {20}, {10,20}, {30}, {10,30}, {20,30}, {10,20,30}})

    eq(F.permutations(xs), {{10,20,30},{10,30,20},{20,10,30},{20,30,10},{30,20,10},{30,10,20}})
    eq(xs:permutations(), {{10,20,30},{10,30,20},{20,10,30},{20,30,10},{30,20,10},{30,10,20}})

end

---------------------------------------------------------------------
-- String functions
---------------------------------------------------------------------

local function string_functions()

    local s = "Lua is great"

    eq(s:chars(), {"L","u","a"," ","i","s"," ","g","r","e","a","t"})
    eq(s:chars(5), {"i","s"," ","g","r","e","a","t"})
    eq(s:chars(5, 7), {"i","s"," "})

    eq(s:head(), "L")
    eq(s:last(), "t")
    eq(s:tail(), "ua is great")
    eq(s:init(), "Lua is grea")
    eq({s:uncons()}, {"L", "ua is great"})

    eq(s:null(), false)
    eq((""):null(), true)
    eq(s:length(), #s)

    eq((","):intersperse("abc"), "a,b,c")
    eq((","):intersperse("a"), "a")
    eq((""):intersperse(""), "")

    eq((","):intercalate{"ab", "c", "de"}, "ab,c,de")
    eq((","):intercalate{"ab"}, "ab")

    eq(("abc"):subsequences(), {"", "a", "b", "ab", "c", "ac", "bc", "abc"})
    eq(("abc"):permutations(), {"abc", "acb", "bac", "bca", "cba", "cab"})

    eq(F.str{"abc", "def"}, "abcdef")
    eq(F.str({"abc", "def"}, "-"), "abc-def")
    eq(F{"abc", "def"}:str(), "abcdef")
    eq(F{"abc", "def"}:str"-", "abc-def")

    eq(("12345"):take(3), "123")
    eq(("12"):take(3), "12")
    eq((""):take(3), "")
    eq(("12"):take(-1), "")
    eq(("12"):take(0), "")

    eq(("12345"):drop(3), "45")
    eq(("12"):drop(3), "")
    eq((""):drop(3), "")
    eq(("12"):drop(-1), "12")
    eq(("12"):drop(0), "12")

    eq({("12345"):split_at(3)}, {"123", "45"})
    eq({("123"):split_at(1)}, {"1", "23"})
    eq({("123"):split_at(3)}, {"123", ""})
    eq({("123"):split_at(4)}, {"123", ""})
    eq({("123"):split_at(0)}, {"", "123"})
    eq({("123"):split_at(-1)}, {"", "123"})

    eq(("12341234"):take_while(function(x) return x < "3" end), "12")
    eq(("123"):take_while(function(x) return x < "9" end), "123")
    eq(("123"):take_while(function(x) return x < "0" end), "")

    eq(("12345123"):drop_while(function(x) return x < "3" end), "345123")
    eq(("123"):drop_while(function(x) return x < "9" end), "")
    eq(("123"):drop_while(function(x) return x < "0" end), "123")

    eq(("12345123"):drop_while_end(function(x) return x < "4" end), "12345")
    eq(("123"):drop_while_end(function(x) return x < "9" end), "")
    eq(("123"):drop_while_end(function(x) return x < "0" end), "123")

    eq(("1234"):strip_prefix("12"), "34")
    eq(("12"):strip_prefix("12"), "")
    eq(("1234"):strip_prefix("32"), nil)
    eq(("1234"):strip_prefix(""), "1234")

    eq(("1234"):strip_suffix("34"), "12")
    eq(("12"):strip_suffix("12"), "")
    eq(("1234"):strip_suffix("32"), nil)
    eq(("1234"):strip_suffix(""), "1234")

    eq(("123"):inits(), {"", "1", "12", "123"})
    eq((""):inits(), {""})

    eq(("123"):tails(), {"123","23","3",""})
    eq((""):tails(), {""})

    eq(("12"):is_prefix_of("123"), true)
    eq(("12"):is_prefix_of("132"), false)
    eq((""):is_prefix_of("123"), true)
    eq(("12"):is_prefix_of(""), false)

    eq(("123"):has_prefix("12"), true)
    eq(("132"):has_prefix("12"), false)
    eq(("123"):has_prefix(""), true)
    eq((""):has_prefix("12"), false)

    eq(("23"):is_suffix_of("123"), true)
    eq(("23"):is_suffix_of("132"), false)
    eq((""):is_suffix_of("123"), true)
    eq(("23"):is_suffix_of(""), false)

    eq(("123"):has_suffix("23"), true)
    eq(("132"):has_suffix("23"), false)
    eq(("123"):has_suffix(""), true)
    eq((""):has_suffix("23"), false)

    eq(("12"):is_infix_of("1234"), true)
    eq(("12"):is_infix_of("3124"), true)
    eq(("12"):is_infix_of("3412"), true)
    eq(("21"):is_infix_of("1234"), false)
    eq(("21"):is_infix_of("3124"), false)
    eq(("21"):is_infix_of("3412"), false)
    eq((""):is_infix_of("1234"), true)
    eq(("12"):is_infix_of(""), false)

    eq(("1234"):has_infix("12"), true)
    eq(("3124"):has_infix("12"), true)
    eq(("3412"):has_infix("12"), true)
    eq(("1234"):has_infix("21"), false)
    eq(("3124"):has_infix("21"), false)
    eq(("3412"):has_infix("21"), false)
    eq(("1234"):has_infix(""), true)
    eq((""):has_infix("12"), false)

    eq(("ab/cd/efg/hij"):split("/"), {"ab","cd","efg","hij"})
    eq(("ab/cd/efg/hij"):split("/", 2), {"ab","cd","efg/hij"})
    eq(("ab/cd/efg/hij/"):split("/"), {"ab","cd","efg","hij",""})
    eq(("ab/cd/efg/hij/"):split("/", 2), {"ab","cd","efg/hij/"})
    eq(("/ab/cd/efg/hij"):split("/"), {"", "ab","cd","efg","hij"})
    eq(("/ab/cd/efg/hij"):split("/", 2), {"","ab","cd/efg/hij"})
    eq(("abcz+defzzzghi"):split("z+", nil, false), {"abc","+def","ghi"})
    eq(("abcz+defzzzghi"):split("z+", nil, true), {"abc","defzzzghi"})

    eq(("aa bb cc\ndd ee ff\nhh ii jj"):lines(), {"aa bb cc","dd ee ff","hh ii jj"})
    eq(("\naa bb cc\ndd ee ff\nhh ii jj\n"):lines(), {"","aa bb cc","dd ee ff","hh ii jj"})

    eq(("aa bb cc\ndd ee ff\nhh ii jj"):words(), {"aa","bb","cc","dd","ee","ff","hh","ii","jj"})
    eq(("\naa bb cc\ndd ee ff\nhh ii jj"):words(), {"aa","bb","cc","dd","ee","ff","hh","ii","jj"})

    eq(("abc"):ltrim(), "abc")
    eq(("  abc"):ltrim(), "abc")
    eq(("abc  "):ltrim(), "abc  ")
    eq(("  abc  "):ltrim(), "abc  ")

    eq(("abc"):rtrim(), "abc")
    eq(("  abc"):rtrim(), "  abc")
    eq(("abc  "):rtrim(), "abc")
    eq(("  abc  "):rtrim(), "  abc")

    eq(("abc"):trim(), "abc")
    eq(("  abc"):trim(), "abc")
    eq(("abc  "):trim(), "abc")
    eq(("  abc  "):trim(), "abc")

    eq(F{}:unlines(), "")
    eq(F{""}:unlines(), "\n")
    eq(F{"one"}:unlines(), "one\n")
    eq(F{"one",""}:unlines(), "one\n\n")
    eq(F{"one","two"}:unlines(), "one\ntwo\n")
    eq(F{"one","","two"}:unlines(), "one\n\ntwo\n")

    eq(F{}:unwords(), "")
    eq(F{""}:unwords(), "")
    eq(F{"one"}:unwords(), "one")
    eq(F{"one","two"}:unwords(), "one two")

    eq(("hElLo"):cap(), "Hello")

end

---------------------------------------------------------------------
-- String interpolation
---------------------------------------------------------------------

local function string_interpolation()

    eq(("foo = $(foo); 1 + 1 = $(1+1)"):I{}, "foo = $(foo); 1 + 1 = 2")
    eq(("foo = $(foo); 1 + 1 = $(1+1)"):I{bar="aaa"}, "foo = $(foo); 1 + 1 = 2")
    eq(("foo = $(foo); 1 + 1 = $(1+1)"):I{foo="aaa"}, "foo = aaa; 1 + 1 = 2")
    eq(("foo = $(foo); 1 + 1 = $(1+1)"):I{foo="aaa", bar="bbb"}, "foo = aaa; 1 + 1 = 2")

    local I = F.I

    eq(I{}"foo = $(foo); 1 + 1 = $(1+1)", "foo = $(foo); 1 + 1 = 2")
    eq(I{bar="aaa"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = $(foo); 1 + 1 = 2")
    eq(I{foo="aaa"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = aaa; 1 + 1 = 2")
    eq(I{foo="aaa", bar="bbb"}"foo = $(foo); 1 + 1 = $(1+1)", "foo = aaa; 1 + 1 = 2")
    eq(I{foo="aaa"}{bar="bbb"}"foo = $(foo); 1 + 1 = $(1+1); bar = $(bar)", "foo = aaa; 1 + 1 = 2; bar = bbb")

end

---------------------------------------------------------------------
-- run all tests
---------------------------------------------------------------------

return function()

    -- standard functions
    basic_data_types()
    basic_type_classes()
    numeric_type_classes()
    miscellaneous_functions()
    convert_to_and_from_string()

    -- table functions
    table_construction()
    table_iterators()
    table_extraction()
    table_predicates()
    table_searching()
    table_size()
    table_transformations()
    table_reductions()
    table_zipping()
    set_operations()
    table_operations()
    ordered_lists()
    generalized_functions()
    miscellaneous_table_functions()

    -- string functions
    string_functions()
    string_interpolation()

end
