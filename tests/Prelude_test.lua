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

local P = require "Prelude"
local L = require "List"

---------------------------------------------------------------------
-- Basic data types
---------------------------------------------------------------------

local function basic_data_types()
    -- and_
    do
        eq(P.op.and_(false, false), false)
        eq(P.op.and_(false, true), false)
        eq(P.op.and_(true, false), false)
        eq(P.op.and_(true, true), true)
    end
    -- or_
    do
        eq(P.op.or_(false, false), false)
        eq(P.op.or_(false, true), true)
        eq(P.op.or_(true, false), true)
        eq(P.op.or_(true, true), true)
    end
    -- xor_
    do
        eq(P.op.xor_(false, false), false)
        eq(P.op.xor_(false, true), true)
        eq(P.op.xor_(true, false), true)
        eq(P.op.xor_(true, true), false)
    end
    -- not_
    do
        eq(P.op.not_(false), true)
        eq(P.op.not_(true), false)
    end
    -- band, bor, bxor, bnot
    do
        for a = 0, 255 do
            for b = 0, 255 do
                eq(P.op.band(a, b), a & b)
                eq(P.op.bor(a, b), a | b)
                eq(P.op.bxor(a, b), a ~ b)
                eq(P.op.bnot(a), ~a)
                eq(P.op.shl(a, b), a << b)
                eq(P.op.shr(a, b), a >> b)
            end
        end
    end
    -- maybe
    do
        local function odd(x) if x%2 == 1 then return x end end
        eq(P.maybe(42, odd, 0), 42)
        eq(P.maybe(42, odd, 1), 1)
        eq(P.maybe(42, odd, 2), 42)
        eq(P.maybe(42, odd, 3), 3)
    end
    -- fst, snd, trd
    do
        eq(P.fst{4,5,6}, 4)
        eq(P.snd{4,5,6}, 5)
        eq(P.trd{4,5,6}, 6)
    end
end

---------------------------------------------------------------------
-- Basic type classes
---------------------------------------------------------------------

local function basic_type_classes()
    -- eq
    do
        eq(P.op.eq(1,1), true)
        eq(P.op.eq(1,2), false)
    end
    -- ne
    do
        eq(P.op.ne(1,1), false)
        eq(P.op.ne(1,2), true)
    end
    -- compare
    do
        eq(P.compare(1, 0), 1)
        eq(P.compare(1, 1), 0)
        eq(P.compare(1, 2), -1)
    end
    -- lt
    do
        eq(P.op.lt(1, 0), false)
        eq(P.op.lt(1, 1), false)
        eq(P.op.lt(1, 2), true)
    end
    -- le
    do
        eq(P.op.le(1, 0), false)
        eq(P.op.le(1, 1), true)
        eq(P.op.le(1, 2), true)
    end
    -- gt
    do
        eq(P.op.gt(1, 0), true)
        eq(P.op.gt(1, 1), false)
        eq(P.op.gt(1, 2), false)
    end
    -- ge
    do
        eq(P.op.ge(1, 0), true)
        eq(P.op.ge(1, 1), true)
        eq(P.op.ge(1, 2), false)
    end
    -- max
    do
        eq(P.max(1, 0), 1)
        eq(P.max(1, 1), 1)
        eq(P.max(1, 2), 2)
    end
    -- min
    do
        eq(P.min(1, 0), 0)
        eq(P.min(1, 1), 1)
        eq(P.min(1, 2), 1)
    end
    -- succ, pred
    do
        eq(P.succ(42), 43)
        eq(P.pred(42), 41)
    end
end

---------------------------------------------------------------------
-- Numeric type classes
---------------------------------------------------------------------

local function numeric_type_classes()
    local mathx = require "mathx"
    -- add, sub, mul, div, idiv, mod, neg, negate
    do
        eq(P.op.add(3, 4), 7)
        eq(P.op.sub(3, 4), -1)
        eq(P.op.mul(3, 4), 12)
        eq(P.op.div(3, 4), 3/4)
        eq(P.op.idiv(3, 4), 0)
        eq(P.op.idiv(13, 4), 3)
        eq(P.op.mod(12, 4), 0)
        eq(P.op.mod(13, 4), 1)
        eq(P.op.mod(14, 4), 2)
        eq(P.op.mod(15, 4), 3)
        eq(P.op.mod(16, 4), 0)
        eq(P.op.neg(-10), 10)
        eq(P.op.neg(10), -10)
        eq(P.negate(-10), 10)
        eq(P.negate(10), -10)
    end
    -- abs, signum
    do
        eq(P.abs(-10), 10)
        eq(P.abs(0), 0)
        eq(P.abs(10), 10)
        eq(P.signum(-10), -1)
        eq(P.signum(0), 0)
        eq(P.signum(10), 1)
    end
    -- quot, rem, quotRem
    do
        eq({P.quotRem(17, 3)}, {5, 2})
        eq({P.quotRem(17, -3)}, {-5, 2})
        eq({P.quotRem(-17, 3)}, {-5, -2})
        eq({P.quotRem(-17, -3)}, {5, -2})
        for a = -20, 20 do
            for b = -10, 10 do
                if b ~= 0 then
                    local q, r = P.quotRem(a, b)
                    eq(b*q + r, a)
                    assert(math.abs(r) < math.abs(b))
                    assert(P.signum(q)*P.signum(a*b) >= 0)
                    assert(P.signum(r)*P.signum(a) >= 0)
                    eq(P.quot(a, b), q)
                    eq(P.rem(a, b), r)
                end
            end
        end
    end
    -- div, mod, divMod
    do
        eq({P.divMod(17, 3)}, {5, 2})
        eq({P.divMod(17, -3)}, {-6, -1})
        eq({P.divMod(-17, 3)}, {-6, 1})
        eq({P.divMod(-17, -3)}, {5, -2})
        for a = -20, 20 do
            for b = -10, 10 do
                if b ~= 0 then
                    local q, r = P.divMod(a, b)
                    eq(b*q + r, a)
                    assert(math.abs(r) < math.abs(b))
                    assert(P.signum(q)*P.signum(a*b) >= 0)
                    assert(P.signum(r)*P.signum(b) >= 0)
                    eq(P.div(a, b), q)
                    eq(P.mod(a, b), r)
                end
            end
        end
    end
    -- recip
    do
        eq(P.recip(16), 1/16)
        eq(P.recip(1/16), 16)
        eq(P.recip(0), 1/0) -- inf
    end
    -- pi, exp, log, sqrt, sin, cos, tan, ...
    do
        eq(P.pi, math.pi)
        for i = -100, 100 do
            local x = 0.1*i
            eq(P.exp(x), math.exp(x))
            if x > 0 then eq(P.log(x), math.log(x)) end
            if x > 0 then eq(P.log(x, 42), math.log(x, 42)) end
            if x > 0 then eq(P.log10(x), math.log(x, 10)) end
            if x > 0 then eq(P.log2(x), math.log(x, 2)) end
            if x >= 0 then eq(P.sqrt(x), math.sqrt(x)) end
            for y = -10, 10 do
                eq(P.op.pow(x, y), x^y)
            end
            if x > 0 then
                for b = 0.1, 10, 0.1 do
                    eq(P.logBase(x, b), math.log(x, b))
                end
            end
            eq(P.sin(x), math.sin(x))
            eq(P.cos(x), math.cos(x))
            eq(P.tan(x), math.tan(x))
            if -1 <= x and x <= 1 then
                eq(P.asin(x), math.asin(x))
                eq(P.acos(x), math.acos(x))
            end
            eq(P.atan(x), math.atan(x))
            eq(P.sinh(x), mathx.sinh(x))
            eq(P.cosh(x), mathx.cosh(x))
            eq(P.tanh(x), mathx.tanh(x))
            eq(P.asinh(x), mathx.asinh(x))
            if x >= 1 then eq(P.acosh(x), mathx.acosh(x)) end
            if -1 <= x and x <= 1 then eq(P.atanh(x), mathx.atanh(x)) end
        end
    end
    -- properFraction, truncate, round
    do
        eq({P.properFraction(10.25)}, {10, 0.25})
        eq({P.properFraction(-10.25)}, {-10, -0.25})
        eq(P.truncate(10.25), 10)
        eq(P.truncate(-10.25), -10)
        eq(P.round(10.25), 10)
        eq(P.round(-10.25), -10)
        eq(P.round(10.75), 11)
        eq(P.round(-10.75), -11)
        eq(P.round(10.5), 11)
        eq(P.round(-10.5), -11)
        eq(P.round(11.5), 12)
        eq(P.round(-11.5), -12)
        eq(P.ceiling(10.25), 11)
        eq(P.ceiling(-10.25), -10)
        eq(P.ceiling(10.75), 11)
        eq(P.ceiling(-10.75), -10)
        eq(P.ceiling(10.5), 11)
        eq(P.ceiling(-10.5), -10)
        eq(P.ceiling(11.5), 12)
        eq(P.ceiling(-11.5), -11)
        eq(P.floor(10.25), 10)
        eq(P.floor(-10.25), -11)
        eq(P.floor(10.75), 10)
        eq(P.floor(-10.75), -11)
        eq(P.floor(10.5), 10)
        eq(P.floor(-10.5), -11)
        eq(P.floor(11.5), 11)
        eq(P.floor(-11.5), -12)
    end
    -- isNan, isInfinite, isDenormalized
    do
        eq(P.isNaN(42), false)
        eq(P.isNaN(0/0), true)
        eq(P.isNaN(1/0), false)
        eq(P.isInfinite(42), false)
        eq(P.isInfinite(0/0), false)
        eq(P.isInfinite(1/0), true)
        eq(P.isDenormalized(1), false)
        eq(P.isDenormalized(0x1p-1024), true)
        eq(P.isNegativeZero(-0x0p0), true)
        eq(P.isNegativeZero(0x0p0), false)
    end
    -- even, odd
    do
        eq(P.even(12), true)
        eq(P.even(13), false)
        eq(P.odd(12), false)
        eq(P.odd(13), true)
    end
    -- gcd
    do
        eq(P.gcd(12, 8), 4)
        eq(P.gcd(-12, 8), 4)
        eq(P.gcd(12, -8), 4)
        eq(P.gcd(-12, -8), 4)
        eq(P.lcm(12, 8), 24)
        eq(P.lcm(-12, 8), 24)
        eq(P.lcm(12, -8), 24)
        eq(P.lcm(-12, -8), 24)
    end
end

---------------------------------------------------------------------
-- Miscellaneous functions
---------------------------------------------------------------------

local function miscellaneous_functions()
    -- id, const
    do
        eq({P.id(10, 20, 30)}, {10, 20, 30})
        eq({P.const(11, 22, 33)("ignored")}, {11, 22, 33})
    end
    -- compose
    do
        local function h(x, y) return x+1, y+2 end
        local function g(x, y) return x*10, y*20 end
        local function f(x, y) return {x,x}, {y,y,y} end
        eq({P.compose{f, g, h}(100, 200)}, {{1010,1010},{4040,4040,4040}})
    end
    -- flip
    do
        eq(P.flip(function(a, b, c, d) return table.concat({a, b, c, d}, "-") end)(1,2,3,4), "2-1-3-4")
    end
    -- curry, uncurry
    do
        local f = function(a, b, c) return a+b+c end
        eq(P.curry(f)(1)(2, 3), 6)
        eq(P.curry(P.curry(f)(1))(2)(3), 6)
        local g = function(a) return function(b) return a+b end end
        eq(P.uncurry(g)(1, 2), 3)
    end
    -- until_
    do
        local p = function(x) return x > 1000 end
        local f = function(x) return x*2 end
        eq(P.until_(p, f, 1), 1024)
    end
    -- concat
    do
        eq(P.op.concat("ab", "cd"), "abcd")
        eq(P.op.concat(L{1,2}, L{3,4}), {1,2,3,4})
    end
    -- len
    do
        eq(P.op.len("abcd"), 4)
        eq(P.op.len({1,2,3,4,5,6}), 6)
    end
    -- prefix, suffix
    do
        eq(P.prefix("ab")("cd"), "abcd")
        eq(P.suffix("ab")("cd"), "cdab")
    end
    -- memo1
    do
        local imath = require "imath"
        local ps = require "ps"

        local function fib(n) return n <= 1 and imath.new(n) or fib(n-1) + fib(n-2) end
        fib = P.memo1(fib)

        eq(fib(0):tostring(), "0")
        eq(fib(1):tostring(), "1")
        eq(fib(2):tostring(), "1")
        eq(fib(3):tostring(), "2")
        eq(fib(4):tostring(), "3")
        eq(fib(5):tostring(), "5")
        eq(fib(6):tostring(), "8")
        local dt = ps.profile(function() eq(fib(100):tostring(), "354224848179261915075") end) -- this should be fast because of memoization
        assert(dt < 0.01, "memoized fibonacci suite is too long")
    end
end

---------------------------------------------------------------------
-- Convert to string
---------------------------------------------------------------------

local function convert_to_and_from_string()
    -- show
    do
        eq(P.show(42), "42")
        eq(P.show({1, x=2, 3}), "{1, 3, x=2}")
        eq(P.show({1, x=2, 3, p={x=1.5, y=2.5}}), "{1, 3, p={x=1.5, y=2.5}, x=2}")
    end
    -- read
    do
        eq(P.read("42"), 42)
        eq(P.read("{1, 3, x=2}"), {1, x=2, 3})
        eq(P.read("{1, 3, p={x=1.5, y=2.5}, x=2}"), {1, 3, p={x=1.5, y=2.5}, x=2})
    end
end

---------------------------------------------------------------------
-- Run all tests
---------------------------------------------------------------------

return function()
    basic_data_types()
    basic_type_classes()
    numeric_type_classes()
    miscellaneous_functions()
    convert_to_and_from_string()
end
