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
# Prelude

[`Prelude`]: https://hackage.haskell.org/package/base-4.17.0.0/docs/Prelude.html

`Prelude` is a module inspired by the Haskell module [`Prelude`].

Note: contrary to the original Haskell modules, all these functions are evaluated strictly
(i.e. no lazy evaluation, no infinite list, ...).

```lua
local P = require "Prelude"
```
@@@]]

local P = {}

P.op = {}

local mathx = require "mathx"
local luax = require "luax"

--[[------------------------------------------------------------------------@@@
## Standard types, and related functions
@@@]]

--[[------------------------------------------------------------------------@@@
### Basic data types
@@@]]

--[[@@@
```lua
P.op.and_(a, b)
```
> Boolean and
@@@]]
function P.op.and_(a, b) return a and b end

--[[@@@
```lua
P.op.or_(a, b)
```
> Boolean or
@@@]]
function P.op.or_(a, b) return a or b end

--[[@@@
```lua
P.op.xor_(a, b)
```
> Boolean xor
@@@]]
function P.op.xor_(a, b) return (a and not b) or (b and not a) end

--[[@@@
```lua
P.op.not_(a)
```
> Boolean not
@@@]]
function P.op.not_(a) return not a end

--[[@@@
```lua
P.maybe(b, f, a)
```
> Returns f(a) if f(a) is not nil, otherwise b
@@@]]
function P.maybe(b, f, a)
    local v = f(a)
    if v == nil then return b end
    return v
end

--[[@@@
```lua
P.op.band(a, b)
```
> Bitwise and
@@@]]
function P.op.band(a, b) return a & b end

--[[@@@
```lua
P.op.bor(a, b)
```
> Bitwise or
@@@]]
function P.op.bor(a, b) return a | b end

--[[@@@
```lua
P.op.bxor(a, b)
```
> Bitwise xor
@@@]]
function P.op.bxor(a, b) return a ~ b end

--[[@@@
```lua
P.op.bnot(a)
```
> Bitwise not
@@@]]
function P.op.bnot(a) return ~a end

--[[@@@
```lua
P.op.shl(a, b)
```
> Bitwise left shift
@@@]]
function P.op.shl(a, b) return a << b end

--[[@@@
```lua
P.op.shr(a, b)
```
> Bitwise right shift
@@@]]
function P.op.shr(a, b) return a >> b end

--[[------------------------------------------------------------------------@@@
#### Tuples
@@@]]

--[[@@@
```lua
P.fst(ab)
```
> Extract the first component of a pair.
@@@]]
function P.fst(xs) return xs[1] end

--[[@@@
```lua
P.snd(ab)
```
> Extract the second component of a pair.
@@@]]
function P.snd(xs) return xs[2] end

--[[@@@
```lua
P.trd(ab)
```
> Extract the third component of a pair.
@@@]]
function P.trd(xs) return xs[3] end

--[[------------------------------------------------------------------------@@@
### Basic type classes
@@@]]

--[[@@@
```lua
P.op.eq(a, b)
```
> Equality
@@@]]
function P.op.eq(a, b) return a == b end

--[[@@@
```lua
P.op.ne(a, b)
```
> Inequality
@@@]]
function P.op.ne(a, b) return a ~= b end

--[[@@@
```lua
P.compare(a, b)
```
> Comparison (-1, 0, 1)
@@@]]
function P.compare(a, b)
    if a < b then return -1 end
    if a > b then return 1 end
    return 0
end

--[[@@@
```lua
P.op.lt(a, b)
```
> a < b
@@@]]
function P.op.lt(a, b) return a < b end

--[[@@@
```lua
P.op.le(a, b)
```
> a <= b
@@@]]
function P.op.le(a, b) return a <= b end

--[[@@@
```lua
P.op.gt(a, b)
```
> a > b
@@@]]
function P.op.gt(a, b) return a > b end

--[[@@@
```lua
P.op.ge(a, b)
```
> a >= b
@@@]]
function P.op.ge(a, b) return a >= b end

--[[@@@
```lua
P.max(a, b)
```
> max(a, b)
@@@]]
function P.max(a, b) if a >= b then return a else return b end end

--[[@@@
```lua
P.min(a, b)
```
> min(a, b)
@@@]]
function P.min(a, b) if a <= b then return a else return b end end

--[[@@@
```lua
P.succ(a)
```
> a + 1
@@@]]
function P.succ(a) return a + 1 end

--[[@@@
```lua
P.pred(a)
```
> a - 1
@@@]]
function P.pred(a) return a - 1 end

--[[------------------------------------------------------------------------@@@
### Numbers
@@@]]
--
--[[------------------------------------------------------------------------@@@
#### Numeric type classes
@@@]]

--[[@@@
```lua
P.op.add(a, b)
```
> a + b
@@@]]
function P.op.add(a, b) return a + b end

--[[@@@
```lua
P.op.sub(a, b)
```
> a - b
@@@]]
function P.op.sub(a, b) return a - b end

--[[@@@
```lua
P.op.mul(a, b)
```
> a * b
@@@]]
function P.op.mul(a, b) return a * b end

--[[@@@
```lua
P.op.div(a, b)
```
> a / b
@@@]]
function P.op.div(a, b) return a / b end

--[[@@@
```lua
P.op.idiv(a, b)
```
> a // b
@@@]]
function P.op.idiv(a, b) return a // b end

--[[@@@
```lua
P.op.mod(a, b)
```
> a % b
@@@]]
function P.op.mod(a, b) return a % b end

--[[@@@
```lua
P.negate(a)
P.op.neg(a)
```
> -a
@@@]]
function P.op.neg(a) return -a end
function P.negate(a) return -a end

--[[@@@
```lua
P.abs(a)
```
> -a
@@@]]
function P.abs(a) if a < 0 then return -a else return a end end

--[[@@@
```lua
P.signum(a)
```
> sign of a (-1, 0 or +1)
@@@]]
function P.signum(a) return P.compare(a, 0) end

--[[@@@
```lua
P.quot(a, b)
```
> integer division truncated toward zero
@@@]]
function P.quot(a, b)
    local q, r = P.quotRem(a, b)
    return q
end

--[[@@@
```lua
P.rem(a, b)
```
> integer remainder satisfying quot(a, b)*b + rem(a, b) == a, 0 <= rem(a, b) < abs(b)
@@@]]
function P.rem(a, b)
    local q, r = P.quotRem(a, b)
    return r
end

--[[@@@
```lua
P.quotRem(a, b)
```
> simultaneous quot and rem
@@@]]
function P.quotRem(a, b)
    local r = math.fmod(a, b)
    local q = (a - r) // b
    return q, r
end

--[[@@@
```lua
P.div(a, b)
```
> integer division truncated toward negative infinity
@@@]]
function P.div(a, b)
    local q, r = P.divMod(a, b)
    return q
end

--[[@@@
```lua
P.mod(a, b)
```
> integer modulus satisfying div(a, b)*b + mod(a, b) == a, 0 <= mod(a, b) < abs(b)
@@@]]
function P.mod(a, b)
    local q, r = P.divMod(a, b)
    return r
end

--[[@@@
```lua
P.divMod(a, b)
```
> simultaneous div and mod
@@@]]
function P.divMod(a, b)
    local q = a // b
    local r = a - b*q
    return q, r
end

--[[@@@
```lua
P.recip(a)
```
> Reciprocal fraction.
@@@]]
function P.recip(a) return 1 / a end

--[[@@@
```lua
P.pi
P.exp(x)
P.log(x), P.log(x, base)
P.sqrt(x)
P.op.pow(x, y)
P.logBase(x, base)
P.sin(x)
P.cos(x)
P.tan(x)
P.asin(x)
P.acos(x)
P.atan(x)
P.sinh(x)
P.cosh(x)
P.tanh(x)
P.asinh(x)
P.acosh(x)
P.atanh(x)
```
> standard math constants and functions
@@@]]
P.pi = math.pi
P.exp = math.exp
P.log = math.log
P.log10 = function(x) return math.log(x, 10) end
P.log2 = function(x) return math.log(x, 2) end
P.sqrt = math.sqrt
P.op.pow = function(x, y) return x^y end
P.logBase = math.log
P.sin = math.sin
P.cos = math.cos
P.tan = math.tan
P.asin = math.asin
P.acos = math.acos
P.atan = math.atan
P.sinh = mathx.sinh
P.cosh = mathx.cosh
P.tanh = mathx.tanh
P.asinh = mathx.asinh
P.acosh = mathx.acosh
P.atanh = mathx.atanh

--[[@@@
```lua
P.properFraction(x)
```
> returns a pair (n,f) such that x = n+f, and:

  - n is an integral number with the same sign as x; and
  - f is a fraction with the same type and sign as x, and with absolute value less than 1.
@@@]]
function P.properFraction(x)
    return math.modf(x)
end

--[[@@@
```lua
P.truncate(x)
```
> returns the integer nearest x between zero and x.
@@@]]
function P.truncate(x)
    return (math.modf(x))
end

--[[@@@
```lua
P.round(x)
```
> returns the nearest integer to x; the even integer if x is equidistant between two integers
@@@]]
function P.round(x)
    return mathx.round(x)
end

--[[@@@
```lua
P.ceiling(x)
```
> returns the least integer not less than x.
@@@]]
function P.ceiling(x)
    return math.ceil(x)
end

--[[@@@
```lua
P.floor(x)
```
> returns the greatest integer not greater than x.
@@@]]
function P.floor(x)
    return math.floor(x)
end

--[[@@@
```lua
P.isNan(x)
```
> True if the argument is an IEEE "not-a-number" (NaN) value
@@@]]
P.isNaN = mathx.isnan

--[[@@@
```lua
P.isInfinite(x)
```
> True if the argument is an IEEE infinity or negative infinity
@@@]]
P.isInfinite = mathx.isinf

--[[@@@
```lua
P.isDenormalized(x)
```
> True if the argument is too small to be represented in normalized format
@@@]]
function P.isDenormalized(x)
    return not mathx.isnormal(x)
end

--[[@@@
```lua
P.isNegativeZero(x)
```
> True if the argument is an IEEE negative zero
@@@]]
function P.isNegativeZero(x)
    return mathx.copysign(1, x) < 0
end

--[[@@@
```lua
P.atan2(y, x)
```
> computes the angle (from the positive x-axis) of the vector from the origin to the point (x,y).
@@@]]
P.atan2 = mathx.atan2

--[[@@@
```lua
P.even(n)
P.odd(n)
```
> parity check
@@@]]
function P.even(n) return n%2 == 0 end
function P.odd(n) return n%2 == 1 end

--[[@@@
```lua
P.gcd(a, b)
P.lcm(a, b)
```
> Greatest Common Divisor and Least Common Multiple of a and b.
@@@]]
function P.gcd(a, b)
    a, b = math.abs(a), math.abs(b)
    while b > 0 do
        a, b = b, a%b
    end
    return a
end
function P.lcm(a, b)
    return math.abs(a // P.gcd(a,b) * b)
end

--[[------------------------------------------------------------------------@@@
### Miscellaneous functions
@@@]]

--[[@@@
```lua
P.id(x)
```
> Identity function.
@@@]]
function P.id(...) return ... end

--[[@@@
```lua
P.const(...)
```
> Constant function. const(...)(y) always returns ...
@@@]]
function P.const(...)
    local val = {...}
    return function()
        return table.unpack(val)
    end
end

--[[@@@
```lua
P.compose(fs)
```
> Function composition. compose{f, g, h}(...) returns f(g(h(...))).
@@@]]
function P.compose(fs)
    local n = #fs
    local function apply(i, ...)
        if i > 0 then return apply(i-1, fs[i](...)) end
        return ...
    end
    return function(...)
        return apply(n, ...)
    end
end

--[[@@@
```lua
P.flip(f)
```
> takes its (first) two arguments in the reverse order of f.
@@@]]
function P.flip(f)
    return function(a, b, ...)
        return f(b, a, ...)
    end
end

--[[@@@
```lua
P.curry(f)
```
> curry(f)(x)(...) calls f(x, ...)
@@@]]
function P.curry(f)
    return function(x)
        return function(...)
            return f(x, ...)
        end
    end
end

--[[@@@
```lua
P.uncurry(f)
```
> uncurry(f)(x, ...) calls f(x)(...)
@@@]]
function P.uncurry(f)
    return function(x, ...)
        return f(x)(...)
    end
end

--[[@@@
```lua
P.until_(p, f, x)
```
> yields the result of applying f until p holds.
@@@]]
function P.until_(p, f, x)
    while not p(x) do
        x = f(x)
    end
    return x
end

--[[@@@
```lua
P.error(message, level)
P.errorWithoutStackTrace(message, level)
```
> stops execution and displays an error message (with out without a stack trace).
@@@]]
local function err(msg, level, tb)
    level = (level or 1) + 2
    local file = debug.getinfo(level, "S").short_src
    local line = debug.getinfo(level, "l").currentline
    msg = table.concat{arg[0], ": ", file, ":", line, ": ", msg}
    io.stderr:write(tb and debug.traceback(msg, level) or msg, "\n")
    os.exit(1)
end
function P.error(message, level) err(message, level, true) end
function P.errorWithoutStackTrace(message, level) err(message, level, false) end

--[[@@@
```lua
P.op.concat(a, b)
```
> Lua concatenation operator
@@@]]
function P.op.concat(a, b) return a..b end

--[[@@@
```lua
P.op.len(a)
```
> Lua length operator
@@@]]
function P.op.len(a) return #a end

--[[@@@
```lua
P.prefix(pre)
```
> returns a function that adds the prefix pre to a string
@@@]]

function P.prefix(pre)
    return function(s) return pre..s end
end

--[[@@@
```lua
P.suffix(suf)
```
> returns a function that adds the suffix suf to a string
@@@]]

function P.suffix(suf)
    return function(s) return s..suf end
end

--[[@@@
```lua
P.memo1(f)
```
> returns a memoized function (one argument)
@@@]]

function P.memo1(f)
    return setmetatable({}, {
        __index = function(self, k) local v = f(k); self[k] = v; return v; end,
        __call = function(self, k) return self[k] end
    })
end

--[[------------------------------------------------------------------------@@@
## Converting to and from string
@@@]]

--[[------------------------------------------------------------------------@@@
### Converting to string
@@@]]

--[[@@@
```lua
P.show(x)
```
> Convert x to a string (luax.pretty)
@@@]]
function P.show(x)
    return luax.pretty(x)
end

--[[------------------------------------------------------------------------@@@
### Converting from string
@@@]]

--[[@@@
```lua
P.read(s)
```
> Convert s to a Lua value
@@@]]
function P.read(s)
    return assert(load("return "..s))()
end

-------------------------------------------------------------------------------
-- Prelude module
-------------------------------------------------------------------------------

return P
