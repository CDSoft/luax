#!/usr/bin/env -S lua --
local function lib(path, src) return assert(load(src, '@$ypp.lua:'..path, 't')) end
local libs = {
["luax"] = lib("luax.lua", [===[--@LOAD=_: load luax to expose LuaX modules
_LUAX_VERSION = '4.3'
_LUAX_DATE = '2024-03-16'
local function lib(path, src) return assert(load(src, '@$luax:'..path, 't')) end
local libs = {
["luax_config"] = lib("luax_config.lua", [=[--@LIB
local version = "4.3"
return {
    version = version,
    date = "2024-03-16",
    copyright = "LuaX "..version.."  Copyright (C) 2021-2024 cdelord.fr/luax",
    authors = "Christophe Delord",
}
]=]),
["F"] = lib("libluax/F/F.lua", [==[--[[
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

-- Load F.lua to add new methods to strings
--@LOAD=_

--[[------------------------------------------------------------------------@@@
# Functional programming utilities

```lua
local F = require "F"
```

`F` provides some useful functions inspired by functional programming languages,
especially by these Haskell modules:

- [`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)
- [`Data.Map`](https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html)
- [`Data.String`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html)
- [`Prelude`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Prelude.html)

@@@]]

--[[@@@
This module provides functions for Lua tables that can represent both arrays (i.e. integral indices)
and tables (i.e. any indice types).
The `F` constructor adds methods to tables which may interfere with table fields that could have the same names.
In this case, F also defines a method alias (same name prefixed with `__`). E.g.:

```lua
t = F{foo = 12, mapk = 42} -- note that mapk is also a method of F tables

t:mapk(func)   -- fails because mapk is a field of t
t:__mapk(func) -- works and is equivalent to F.mapk(func, t)
```

@@@]]

local F = {}

local mt = {
    __name = "F-table",
    __index = setmetatable({}, {
        __newindex = function(t, k, v)
            rawset(t, k, v)         -- set the method k
            rawset(t, "__"..k, v)   -- and its __k alias in case of conflict with table fields named k
        end,
    }),
}

local function setmt(t) return setmetatable(t, mt) end

local function register0(name)
    return function(f)
        F[name] = f
    end
end

local function register1(name)
    return function(f)
        F[name] = f
        mt.__index[name] = f
    end
end

local function register2(name)
    return function(f)
        F[name] = f
        mt.__index[name] = function(t, x1, ...) return f(x1, t, ...) end
    end
end

local function register3(name)
    return function(f)
        F[name] = f
        mt.__index[name] = function(t, x1, x2, ...) return f(x1, x2, t, ...) end
    end
end

--[[------------------------------------------------------------------------@@@
## Standard types, and related functions
@@@]]

local mathx = require "mathx"

local type_rank = {
    ["nil"]         = 0,
    ["number"]      = 1,
    ["string"]      = 2,
    ["boolean"]     = 3,
    ["table"]       = 4,
    ["function"]    = 5,
    ["thread"]      = 6,
    ["userdata"]    = 7,
}

local function universal_eq(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return false end
    if ta == "nil" then return true end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            if not universal_eq(a[k], b[k]) then return false end
        end
        return true
    end
    return a == b
end

local function universal_ne(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return true end
    if ta == "nil" then return false end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            if universal_ne(a[k], b[k]) then return true end
        end
        return false
    end
    return a ~= b
end

local function universal_lt(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] < type_rank[tb] end
    if ta == "nil" then return false end
    if ta == "number" or ta == "string" or ta == "boolean" then return a < b end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            local ak = a[k]
            local bk = b[k]
            if not universal_eq(ak, bk) then return universal_lt(ak, bk) end
        end
        return false
    end
    return tostring(a) < tostring(b)
end

local function universal_le(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] <= type_rank[tb] end
    if ta == "nil" then return true end
    if ta == "number" or ta == "string" or ta == "boolean" then return a <= b end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            local ak = a[k]
            local bk = b[k]
            if not universal_eq(ak, bk) then return universal_le(ak, bk) end
        end
        return true
    end
    return tostring(a) <= tostring(b)
end

local function universal_gt(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] > type_rank[tb] end
    if ta == "nil" then return false end
    if ta == "number" or ta == "string" or ta == "boolean" then return a > b end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            local ak = a[k]
            local bk = b[k]
            if not universal_eq(ak, bk) then return universal_gt(ak, bk) end
        end
        return false
    end
    return tostring(a) > tostring(b)
end

local function universal_ge(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] >= type_rank[tb] end
    if ta == "nil" then return true end
    if ta == "number" or ta == "string" or ta == "boolean" then return a >= b end
    if ta == "table" then
        local ks = F.merge{a, b}:keys()
        for i = 1, #ks do
            local k = ks[i]
            local ak = a[k]
            local bk = b[k]
            if not universal_eq(ak, bk) then return universal_ge(ak, bk) end
        end
        return true
    end
    return tostring(a) >= tostring(b)
end

--[[------------------------------------------------------------------------@@@
### Operators
@@@]]

F.op = {}

--[[@@@
```lua
F.op.land(a, b)             -- a and b
F.op.lor(a, b)              -- a or b
F.op.lxor(a, b)             -- (not a and b) or (not b and a)
F.op.lnot(a)                -- not a
```
> Logical operators
@@@]]

F.op.land = function(a, b) return a and b end
F.op.lor = function(a, b) return a or b end
F.op.lxor = function(a, b) return (not a and b) or (not b and a) end
F.op.lnot = function(a) return not a end

--[[@@@
```lua
F.op.band(a, b)             -- a & b
F.op.bor(a, b)              -- a | b
F.op.bxor(a, b)             -- a ~ b
F.op.bnot(a)                -- ~a
F.op.shl(a, b)              -- a << b
F.op.shr(a, b)              -- a >> b
```
> Bitwise operators
@@@]]

F.op.band = function(a, b) return a & b end
F.op.bor = function(a, b) return a | b end
F.op.bxor = function(a, b) return a ~ b end
F.op.bnot = function(a) return ~a end
F.op.shl = function(a, b) return a << b end
F.op.shr = function(a, b) return a >> b end

--[[@@@
```lua
F.op.eq(a, b)               -- a == b
F.op.ne(a, b)               -- a ~= b
F.op.lt(a, b)               -- a < b
F.op.le(a, b)               -- a <= b
F.op.gt(a, b)               -- a > b
F.op.ge(a, b)               -- a >= b
```
> Comparison operators
@@@]]

F.op.eq = function(a, b) return a == b end
F.op.ne = function(a, b) return a ~= b end
F.op.lt = function(a, b) return a < b end
F.op.le = function(a, b) return a <= b end
F.op.gt = function(a, b) return a > b end
F.op.ge = function(a, b) return a >= b end

--[[@@@
```lua
F.op.ueq(a, b)              -- a == b  (†)
F.op.une(a, b)              -- a ~= b  (†)
F.op.ult(a, b)              -- a < b   (†)
F.op.ule(a, b)              -- a <= b  (†)
F.op.ugt(a, b)              -- a > b   (†)
F.op.uge(a, b)              -- a >= b  (†)
```
> Universal comparison operators ((†) comparisons on elements of possibly different Lua types)
@@@]]

F.op.ueq = universal_eq
F.op.une = universal_ne
F.op.ult = universal_lt
F.op.ule = universal_le
F.op.ugt = universal_gt
F.op.uge = universal_ge

--[[@@@
```lua
F.op.add(a, b)              -- a + b
F.op.sub(a, b)              -- a - b
F.op.mul(a, b)              -- a * b
F.op.div(a, b)              -- a / b
F.op.idiv(a, b)             -- a // b
F.op.mod(a, b)              -- a % b
F.op.neg(a)                 -- -a
F.op.pow(a, b)              -- a ^ b
```
> Arithmetic operators
@@@]]

F.op.add = function(a, b) return a + b end
F.op.sub = function(a, b) return a - b end
F.op.mul = function(a, b) return a * b end
F.op.div = function(a, b) return a / b end
F.op.idiv = function(a, b) return a // b end
F.op.mod = function(a, b) return a % b end
F.op.neg = function(a) return -a end
F.op.pow = function(a, b) return a ^ b end

--[[@@@
```lua
F.op.concat(a, b)           -- a .. b
F.op.len(a)                 -- #a
```
> String/list operators
@@@]]

F.op.concat = function(a, b) return a..b end
F.op.len = function(a) return #a end

--[[------------------------------------------------------------------------@@@
### Basic data types
@@@]]

--[[@@@
```lua
F.maybe(b, f, a)
```
> Returns f(a) if f(a) is not nil, otherwise b
@@@]]
function F.maybe(b, f, a)
    local v = f(a)
    if v == nil then return b end
    return v
end

--[[@@@
```lua
F.default(def, x)
```
> Returns x if x is not nil, otherwise def
@@@]]
function F.default(def, x)
    if x == nil then return def end
    return x
end

--[[@@@
```lua
F.case(x) {
    t1 = v1,
    ...
    tn = vn,
    [F.Nil] = default_value,
}
```
> returns `vi` such that `ti == x` or `default_value` if no `ti` is equal to `x`.
@@@]]

function F.case(val)
    return function(cases)
        return F.default(cases[F.Nil], cases[val])
    end
end

--[[------------------------------------------------------------------------@@@
#### Tuples
@@@]]

--[[@@@
```lua
F.fst(xs)
xs:fst()
```
> Extract the first component of a list.
@@@]]
register1 "fst" (function(xs) return xs[1] end)

--[[@@@
```lua
F.snd(xs)
xs:snd()
```
> Extract the second component of a list.
@@@]]
register1 "snd" (function(xs) return xs[2] end)

--[[@@@
```lua
F.thd(xs)
xs:thd()
```
> Extract the third component of a list.
@@@]]
register1 "thd" (function(xs) return xs[3] end)

--[[@@@
```lua
F.nth(n, xs)
xs:nth(n)
```
> Extract the n-th component of a list.
@@@]]
register2 "nth" (function(n, xs) return xs[n] end)

--[[------------------------------------------------------------------------@@@
### Basic type classes
@@@]]

--[[@@@
```lua
F.comp(a, b)
```
> Comparison (-1, 0, 1)
@@@]]

function F.comp(a, b)
    if a < b then return -1 end
    if a > b then return 1 end
    return 0
end

--[[@@@
```lua
F.ucomp(a, b)
```
> Comparison (-1, 0, 1) (using universal comparison operators)
@@@]]

function F.ucomp(a, b)
    if universal_lt(a, b) then return -1 end
    if universal_gt(a, b) then return 1 end
    return 0
end

--[[@@@
```lua
F.max(a, b)
```
> max(a, b)
@@@]]
function F.max(a, b) if a >= b then return a else return b end end

--[[@@@
```lua
F.min(a, b)
```
> min(a, b)
@@@]]
function F.min(a, b) if a <= b then return a else return b end end

--[[@@@
```lua
F.succ(a)
```
> a + 1
@@@]]
function F.succ(a) return a + 1 end

--[[@@@
```lua
F.pred(a)
```
> a - 1
@@@]]
function F.pred(a) return a - 1 end

--[[------------------------------------------------------------------------@@@
### Numbers
@@@]]
--
--[[------------------------------------------------------------------------@@@
#### Numeric type classes
@@@]]

--[[@@@
```lua
F.negate(a)
```
> -a
@@@]]
function F.negate(a) return -a end

--[[@@@
```lua
F.abs(a)
```
> absolute value of a
@@@]]
F.abs = math.abs

--[[@@@
```lua
F.signum(a)
```
> sign of a (-1, 0 or +1)
@@@]]
function F.signum(a) return F.comp(a, 0) end

--[[@@@
```lua
F.quot(a, b)
```
> integer division truncated toward zero
@@@]]
function F.quot(a, b)
    local q, _ = F.quot_rem(a, b)
    return q
end

--[[@@@
```lua
F.rem(a, b)
```
> integer remainder satisfying quot(a, b)*b + rem(a, b) == a, 0 <= rem(a, b) < abs(b)
@@@]]
function F.rem(a, b)
    local _, r = F.quot_rem(a, b)
    return r
end

--[[@@@
```lua
F.quot_rem(a, b)
```
> simultaneous quot and rem
@@@]]
function F.quot_rem(a, b)
    local r = math.fmod(a, b)
    local q = (a - r) // b
    return q, r
end

--[[@@@
```lua
F.div(a, b)
```
> integer division truncated toward negative infinity
@@@]]
function F.div(a, b)
    local q, _ = F.div_mod(a, b)
    return q
end

--[[@@@
```lua
F.mod(a, b)
```
> integer modulus satisfying div(a, b)*b + mod(a, b) == a, 0 <= mod(a, b) < abs(b)
@@@]]
function F.mod(a, b)
    local _, r = F.div_mod(a, b)
    return r
end

--[[@@@
```lua
F.div_mod(a, b)
```
> simultaneous div and mod
@@@]]
function F.div_mod(a, b)
    local q = a // b
    local r = a - b*q
    return q, r
end

--[[@@@
```lua
F.recip(a)
```
> Reciprocal fraction.
@@@]]
function F.recip(a) return 1 / a end

--[[@@@
```lua
F.pi
F.exp(x)
F.log(x), F.log(x, base)
F.sqrt(x)
F.sin(x)
F.cos(x)
F.tan(x)
F.asin(x)
F.acos(x)
F.atan(x)
F.sinh(x)
F.cosh(x)
F.tanh(x)
F.asinh(x)
F.acosh(x)
F.atanh(x)
```
> standard math constants and functions
@@@]]
F.pi = math.pi
F.exp = math.exp
F.log = math.log
F.log10 = function(x) return math.log(x, 10) end
F.log2 = function(x) return math.log(x, 2) end
F.sqrt = math.sqrt
F.sin = math.sin
F.cos = math.cos
F.tan = math.tan
F.asin = math.asin
F.acos = math.acos
F.atan = math.atan
F.sinh = mathx.sinh
F.cosh = mathx.cosh
F.tanh = mathx.tanh
F.asinh = mathx.asinh
F.acosh = mathx.acosh
F.atanh = mathx.atanh

--[[@@@
```lua
F.proper_fraction(x)
```
> returns a pair (n,f) such that x = n+f, and:
>
> - n is an integral number with the same sign as x
> - f is a fraction with the same type and sign as x, and with absolute value less than 1.
@@@]]
F.proper_fraction = math.modf

--[[@@@
```lua
F.truncate(x)
```
> returns the integer nearest x between zero and x and the fractional part of x.
@@@]]
F.truncate = math.modf

--[[@@@
```lua
F.round(x)
```
> returns the nearest integer to x; the even integer if x is equidistant between two integers
@@@]]

F.round = mathx.round

--[[@@@
```lua
F.ceiling(x)
F.ceil(x)
```
> returns the least integer not less than x.
@@@]]
F.ceiling = math.ceil
F.ceil = F.ceiling

--[[@@@
```lua
F.floor(x)
```
> returns the greatest integer not greater than x.
@@@]]
F.floor = math.floor

--[[@@@
```lua
F.is_nan(x)
```
> True if the argument is an IEEE "not-a-number" (NaN) value
@@@]]

F.is_nan = mathx.isnan

--[[@@@
```lua
F.is_infinite(x)
```
> True if the argument is an IEEE infinity or negative infinity
@@@]]

F.is_infinite = mathx.isinf

--[[@@@
```lua
F.is_normalized(x)
```
> True if the argument is represented in normalized format
@@@]]

F.is_normalized = mathx.isnormal

--[[@@@
```lua
F.is_denormalized(x)
```
> True if the argument is too small to be represented in normalized format
@@@]]

function F.is_denormalized(x)
    return not mathx.isnormal(x)
end

--[[@@@
```lua
F.is_negative_zero(x)
```
> True if the argument is an IEEE negative zero
@@@]]

function F.is_negative_zero(x)
    return mathx.copysign(1, x) < 0
end

--[[@@@
```lua
F.atan2(y, x)
```
> computes the angle (from the positive x-axis) of the vector from the origin to the point (x,y).
@@@]]

F.atan2 = mathx.atan

--[[@@@
```lua
F.even(n)
F.odd(n)
```
> parity check
@@@]]
function F.even(n) return n%2 == 0 end
function F.odd(n) return n%2 == 1 end

--[[@@@
```lua
F.gcd(a, b)
F.lcm(a, b)
```
> Greatest Common Divisor and Least Common Multiple of a and b.
@@@]]
function F.gcd(a, b)
    a, b = math.abs(a), math.abs(b)
    while b > 0 do
        a, b = b, a%b
    end
    return a
end
function F.lcm(a, b)
    return math.abs(a // F.gcd(a,b) * b)
end

--[[------------------------------------------------------------------------@@@
### Miscellaneous functions
@@@]]

--[[@@@
```lua
F.id(x)
```
> Identity function.
@@@]]
function F.id(...) return ... end

--[[@@@
```lua
F.const(...)
```
> Constant function. const(...)(y) always returns ...
@@@]]
function F.const(...)
    local val = {...}
    return function(...) ---@diagnostic disable-line:unused-vararg
        return table.unpack(val)
    end
end

--[[@@@
```lua
F.compose(fs)
```
> Function composition. compose{f, g, h}(...) returns f(g(h(...))).
@@@]]
function F.compose(fs)
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
F.flip(f)
```
> takes its (first) two arguments in the reverse order of f.
@@@]]
function F.flip(f)
    return function(a, b, ...)
        return f(b, a, ...)
    end
end

--[[@@@
```lua
F.curry(f)
```
> curry(f)(x)(...) calls f(x, ...)
@@@]]
function F.curry(f)
    return function(x)
        return function(...)
            return f(x, ...)
        end
    end
end

--[[@@@
```lua
F.uncurry(f)
```
> uncurry(f)(x, ...) calls f(x)(...)
@@@]]
function F.uncurry(f)
    return function(x, ...)
        return f(x)(...)
    end
end

--[[@@@
```lua
F.partial(f, ...)
```
> F.partial(f, xs)(ys) calls f(xs..ys)
@@@]]
function F.partial(f, ...)
    local n = select("#", ...)
    if n == 1 then
        local x1 = ...
        return function(...)
            return f(x1, ...)
        end
    elseif n == 2 then
        local x1, x2 = ...
        return function(...)
            return f(x1, x2, ...)
        end
    elseif n == 3 then
        local x1, x2, x3 = ...
        return function(...)
            return f(x1, x2, x3, ...)
        end
    else
        local xs = F{...}
        return function(...)
            return f((xs..{...}):unpack())
        end
    end
end

--[[@@@
```lua
F.call(f, ...)
```
> calls `f(...)`
@@@]]

function F.call(f, ...)
    return f(...)
end

--[[@@@
```lua
F.until_(p, f, x)
```
> yields the result of applying f until p holds.
@@@]]
function F.until_(p, f, x)
    while not p(x) do
        x = f(x)
    end
    return x
end

--[[@@@
```lua
F.error(message, level)
F.error_without_stack_trace(message, level)
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
function F.error(message, level) err(message, level, true) end
function F.error_without_stack_trace(message, level) err(message, level, false) end

--[[@@@
```lua
F.prefix(pre)
```
> returns a function that adds the prefix pre to a string
@@@]]

function F.prefix(pre)
    return function(s) return pre..s end
end

--[[@@@
```lua
F.suffix(suf)
```
> returns a function that adds the suffix suf to a string
@@@]]

function F.suffix(suf)
    return function(s) return s..suf end
end

--[[@@@
```lua
F.memo1(f)
```
> returns a memoized function (one argument)
>
> Note that the memoized function has a `reset` method to forget all the previously computed values.
@@@]]

function F.memo1(f)
    local mem = {}
    return setmetatable({}, {
        __index = {
            reset = function(_) mem = {} end,
        },
        __call = function(_, k)
            local v = mem[k]
            if v then return table.unpack(v) end
            v = {f(k)}
            mem[k] = v
            return table.unpack(v)
        end,
    })
end

--[[@@@
```lua
F.memo(f)
```
> returns a memoized function (any number of arguments)
>
> Note that the memoized function has a `reset` method to forget all the previously computed values.
@@@]]

function F.memo(f)
    local _nil = {}
    local _value = {}
    local mem = {}
    return setmetatable({}, {
        __index = {
            reset = function(_) mem = {} end,
        },
        __call = function(_, ...)
            local cur = mem
            for i = 1, select("#", ...) do
                local k = select(i, ...) or _nil
                cur[k] = cur[k] or {}
                cur = cur[k]
            end
            cur[_value] = cur[_value] or {f(...)}
            return table.unpack(cur[_value])
        end,
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
F.show(x, [opt])
```
> Convert x to a string
>
> `opt` is an optional table that customizes the output string:
>
>   - `opt.int`: integer format
>   - `opt.flt`: floating point number format
>   - `opt.indent`: number of spaces use to indent tables (`nil` for a single line output)
@@@]]

local default_show_options = {
    int = "%s",
    flt = "%s",
    indent = nil,
}

register1 "show" (function(x, opt)

    opt = F.merge{default_show_options, opt}

    local tokens = {}
    local function emit(token) tokens[#tokens+1] = token end
    local function drop() table.remove(tokens) end

    local stack = {}
    local function push(val) stack[#stack + 1] = val end
    local function pop() table.remove(stack) end
    local function in_stack(val)
        for i = 1, #stack do
            if rawequal(stack[i], val) then return true end
        end
    end

    local tabs = 0

    local function fmt(val)
        if type(val) == "table" then
            if in_stack(val) then
                emit "{...}" -- recursive table
            else
                push(val)
                local need_nl = false
                emit "{"
                if opt.indent then tabs = tabs + opt.indent end
                local n = 0
                for i = 1, #val do
                    fmt(val[i])
                    emit ", "
                    n = n + 1
                end
                local first_field = true
                for k, v in F.pairs(val) do
                    if not (type(k) == "number" and math.type(k) == "integer" and 1 <= k and k <= #val) then
                        if first_field and opt.indent and n > 1 then drop() emit "," end
                        first_field = false
                        need_nl = opt.indent ~= nil
                        if opt.indent then emit "\n" emit((" "):rep(tabs)) end
                        if type(k) == "string" and k:match "^[%a_][%w_]*$" then
                            emit(k)
                        else
                            emit "[" fmt(k) emit "]"
                        end
                        if opt.indent then emit " = " else emit "=" end
                        fmt(v)
                        if opt.indent then emit "," else emit ", " end
                        n = n + 1
                    end
                end
                if n > 0 and not need_nl then drop() end
                if need_nl then emit "\n" end
                if opt.indent then tabs = tabs - opt.indent end
                if opt.indent and need_nl then emit((" "):rep(tabs)) end
                emit "}"
                pop()
            end
        elseif type(val) == "number" then
            if math.type(val) == "integer" then
                emit(opt.int:format(val))
            elseif math.type(val) == "float" then
                emit(opt.flt:format(val))
            else
                emit(("%s"):format(val))
            end
        elseif type(val) == "string" then
            emit(("%q"):format(val))
        else
            emit(("%s"):format(val))
        end
    end

    fmt(x)
    return table.concat(tokens)

end)

--[[------------------------------------------------------------------------@@@
### Converting from string
@@@]]

--[[@@@
```lua
F.read(s)
```
> Convert s to a Lua value
@@@]]

function F.read(s)
    local chunk, msg = load("return "..s)
    if chunk == nil then return nil, msg end
    local status, value = pcall(chunk)
    if not status then return nil, value end
    return value
end

--[[------------------------------------------------------------------------@@@
## Table construction
@@@]]

--[[@@@
```lua
F(t)
```
> `F(t)` sets the metatable of `t` and returns `t`.
> Most of the functions of `F` will be methods of `t`.
>
> Note that other `F` functions that return tables actually return `F` tables.
@@@]]

--[[@@@
```lua
F.clone(t)
t:clone()
```
> `F.clone(t)` clones the first level of `t`.
@@@]]

register1 "clone" (function(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return setmt(t2)
end)

--[[@@@
```lua
F.deep_clone(t)
t:deep_clone()
```
> `F.deep_clone(t)` recursively clones `t`.
@@@]]

register1 "deep_clone" (function(t)
    local function go(t1)
        if type(t1) ~= "table" then return t1 end
        local t2 = {}
        for k, v in pairs(t1) do t2[k] = go(v) end
        return setmetatable(t2, getmetatable(t1))
    end
    return setmt(go(t))
end)

--[[@@@
```lua
F.rep(n, x)
```
> Returns a list of length n with x the value of every element.
@@@]]

register0 "rep" (function(n, x)
    local xs = {}
    for _ = 1, n do
        xs[#xs+1] = x
    end
    return setmt(xs)
end)

--[[@@@
```lua
F.range(a)
F.range(a, b)
F.range(a, b, step)
```
> Returns a range [1, a], [a, b] or [a, a+step, ... b]
@@@]]

register0 "range" (function(a, b, step)
    step = step or 1
    if step == 0 then return nil, "range step can not be zero" end
    if b == nil then a, b = 1, a end
    local r = {}
    if step > 0 then
        while a <= b do
            r[#r+1] = a
            a = a + step
        end
    else
        while a >= b do
            r[#r+1] = a
            a = a + step
        end
    end

    return setmt(r)
end)

--[[@@@
```lua
F.concat{xs1, xs2, ... xsn}
F{xs1, xs2, ... xsn}:concat()
xs1 .. xs2
```
> concatenates lists
@@@]]

register1 "concat"(function(xss)
    local ys = {}
    for i = 1, #xss do
        local xs = xss[i]
        for j = 1, #xs do
            ys[#ys+1] = xs[j]
        end
    end
    return setmt(ys)
end)

function mt.__concat(xs1, xs2)
    return F.concat{xs1, xs2}
end

--[[@@@
```lua
F.flatten(xs, [leaf])
xs:flatten([leaf])
```
> Returns a flat list with all elements recursively taken from xs.
  The optional `leaf` parameter is a predicate that can stop `flatten` on some kind of nodes.
  By default, `flatten` only recurses on tables with no metatable or on `F` tables.
@@@]]

local function default_leaf(x)
    -- by default, a table is a leaf if it has a metatable and is not an F' list
    local xmt = getmetatable(x)
    return xmt and xmt ~= mt
end

register1 "flatten" (function(xs, leaf)
    leaf = leaf or default_leaf
    local zs = {}
    local function f(ys)
        for i = 1, #ys do
            local x = ys[i]
            if type(x) == "table" and not leaf(x) then
                f(x)
            else
                zs[#zs+1] = x
            end
        end
    end
    f(xs)
    return setmt(zs)
end)

--[=[@@@
```lua
F.str({s1, s2, ... sn}, [separator, [last_separator]])
ss:str([separator, [last_separator]])
```
> concatenates strings (separated with an optional separator) and returns a string.
@@@]=]

register1 "str" (function(ss, sep, last_sep)
    if last_sep then
        if #ss <= 1 then return table.concat(ss) end
        return table.concat({table.concat(ss, sep, 1, #ss-1), ss[#ss]}, last_sep)
    else
        return table.concat(ss, sep)
    end
end)

--[[@@@
```lua
F.from_set(f, ks)
ks:from_set(f)
```
> Build a map from a set of keys and a function which for each key computes its value.
@@@]]

register2 "from_set" (function(f, ks)
    local t = {}
    for i = 1, #ks do
        local k = ks[i]
        t[k] = f(k)
    end
    return F(t)
end)

--[[@@@
```lua
F.from_list(kvs)
kvs:from_list()
```
> Build a map from a list of key/value pairs.
@@@]]

register1 "from_list" (function(kvs)
    local t = {}
    for i = 1, #kvs do
        local k, v = table.unpack(kvs[i])
        t[k] = v
    end
    return F(t)
end)

--[[------------------------------------------------------------------------@@@
## Iterators
@@@]]

--[[@@@
```lua
F.pairs(t, [comp_lt])
t:pairs([comp_lt])
F.ipairs(xs, [comp_lt])
xs:ipairs([comp_lt])
```
> behave like the Lua `pairs` and `ipairs` iterators.
> `F.pairs` sorts keys using the function `comp_lt` or the universal `<=` operator (`F.op.ult`).
@@@]]

register1 "ipairs" (ipairs)

register1 "pairs" (function(t, comp_lt)
    local kvs = F.items(t, comp_lt)
    local i = 0
    return function()
        if i < #kvs then
            i = i+1
            return table.unpack(kvs[i])
        end
    end
end)

--[[@@@
```lua
F.keys(t, [comp_lt])
t:keys([comp_lt])
F.values(t, [comp_lt])
t:values([comp_lt])
F.items(t, [comp_lt])
t:items([comp_lt])
```
> returns the list of keys, values or pairs of keys/values (same order than F.pairs).
@@@]]

register1 "keys" (function(t, comp_lt)
    comp_lt = comp_lt or universal_lt
    local ks = {}
    for k, _ in pairs(t) do ks[#ks+1] = k end
    table.sort(ks, comp_lt)
    return F(ks)
end)

register1 "values" (function(t, comp_lt)
    local ks = F.keys(t, comp_lt)
    local vs = {}
    for i = 1, #ks do vs[i] = t[ks[i]] end
    return F(vs)
end)

register1 "items" (function(t, comp_lt)
    local ks = F.keys(t, comp_lt)
    local kvs = {}
    for i = 1, #ks do
        local k = ks[i]
        kvs[i] = F{k, t[k]} end
    return F(kvs)
end)

--[[------------------------------------------------------------------------@@@
## Table extraction
@@@]]

--[[@@@
```lua
F.head(xs)
xs:head()
F.last(xs)
xs:last()
```
> returns the first element (head) or the last element (last) of a list.
@@@]]

register1 "head" (function(xs) return xs[1] end)
register1 "last" (function(xs) return xs[#xs] end)

--[[@@@
```lua
F.tail(xs)
xs:tail()
F.init(xs)
xs:init()
```
> returns the list after the head (tail) or before the last element (init).
@@@]]

register1 "tail" (function(xs)
    if #xs == 0 then return nil end
    local tail = {}
    for i = 2, #xs do tail[#tail+1] = xs[i] end
    return setmt(tail)
end)

register1 "init" (function(xs)
    if #xs == 0 then return nil end
    local init = {}
    for i = 1, #xs-1 do init[#init+1] = xs[i] end
    return setmt(init)
end)

--[[@@@
```lua
F.uncons(xs)
xs:uncons()
```
> returns the head and the tail of a list.
@@@]]

register1 "uncons" (function(xs) return F.head(xs), F.tail(xs) end)

--[[@@@
```lua
F.unpack(xs, [ i, [j] ])
xs:unpack([ i, [j] ])
```
> returns the elements of xs between indices i and j
@@@]]

register1 "unpack" (table.unpack)

--[[@@@
```lua
F.take(n, xs)
xs:take(n)
```
> Returns the prefix of xs of length n.
@@@]]

register2 "take" (function(n, xs)
    local ys = {}
    for i = 1, n do
        ys[#ys+1] = xs[i]
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.drop(n, xs)
xs:drop(n)
```
> Returns the suffix of xs after the first n elements.
@@@]]

register2 "drop" (function(n, xs)
    local ys = {}
    for i = n+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.split_at(n, xs)
xs:split_at(n)
```
> Returns a tuple where first element is xs prefix of length n and second element is the remainder of the list.
@@@]]

register2 "split_at" (function(n, xs)
    return F.take(n, xs), F.drop(n, xs)
end)

--[[@@@
```lua
F.take_while(p, xs)
xs:take_while(p)
```
> Returns the longest prefix (possibly empty) of xs of elements that satisfy p.
@@@]]

register2 "take_while" (function(p, xs)
    local ys = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.drop_while(p, xs)
xs:drop_while(p)
```
> Returns the suffix remaining after `take_while(p, xs)`{.lua}.
@@@]]

register2 "drop_while" (function(p, xs)
    local zs = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmt(zs)
end)

--[[@@@
```lua
F.drop_while_end(p, xs)
xs:drop_while_end(p)
```
> Drops the largest suffix of a list in which the given predicate holds for all elements.
@@@]]

register2 "drop_while_end" (function(p, xs)
    local zs = {}
    local i = #xs
    while i > 0 and p(xs[i]) do
        i = i-1
    end
    for j = 1, i do
        zs[#zs+1] = xs[j]
    end
    return setmt(zs)
end)

--[[@@@
```lua
F.span(p, xs)
xs:span(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that satisfy p and second element is the remainder of the list.
@@@]]

register2 "span" (function(p, xs)
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
    return setmt(ys), setmt(zs)
end)

--[[@@@
```lua
F.break_(p, xs)
xs:break_(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that do not satisfy p and second element is the remainder of the list.
@@@]]

register2 "break_" (function(p, xs)
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
    return setmt(ys), setmt(zs)
end)

--[[@@@
```lua
F.strip_prefix(prefix, xs)
xs:strip_prefix(prefix)
```
> Drops the given prefix from a list.
@@@]]

register2 "strip_prefix" (function(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return nil end
    end
    local ys = {}
    for i = #prefix+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.strip_suffix(suffix, xs)
xs:strip_suffix(suffix)
```
> Drops the given suffix from a list.
@@@]]

register2 "strip_suffix" (function(suffix, xs)
    for i = 1, #suffix do
        if xs[#xs-#suffix+i] ~= suffix[i] then return nil end
    end
    local ys = {}
    for i = 1, #xs-#suffix do
        ys[i] = xs[i]
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.group(xs, [comp_eq])
xs:group([comp_eq])
```
> Returns a list of lists such that the concatenation of the result is equal to the argument. Moreover, each sublist in the result contains only equal elements.
@@@]]

register1 "group" (function(xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local yss = {}
    if #xs == 0 then return setmt(yss) end
    local y = xs[1]
    local ys = {y}
    for i = 2, #xs do
        local x = xs[i]
        if comp_eq(x, y) then
            ys[#ys+1] = x
        else
            yss[#yss+1] = setmt(ys)
            y = x
            ys = {y}
        end
    end
    yss[#yss+1] = setmt(ys)
    return setmt(yss)
end)

--[[@@@
```lua
F.inits(xs)
xs:inits()
```
> Returns all initial segments of the argument, shortest first.
@@@]]

register1 "inits" (function(xs)
    local yss = {}
    for i = 0, #xs do
        local ys = {}
        for j = 1, i do
            ys[#ys+1] = xs[j]
        end
        yss[#yss+1] = setmt(ys)
    end
    return setmt(yss)
end)

--[[@@@
```lua
F.tails(xs)
xs:tails()
```
> Returns all final segments of the argument, longest first.
@@@]]

register1 "tails" (function(xs)
    local yss = {}
    for i = 1, #xs+1 do
        local ys = {}
        for j = i, #xs do
            ys[#ys+1] = xs[j]
        end
        yss[#yss+1] = setmt(ys)
    end
    return setmt(yss)
end)

--[[------------------------------------------------------------------------@@@
## Predicates
@@@]]

--[[@@@
```lua
F.is_prefix_of(prefix, xs)
prefix:is_prefix_of(xs)
```
> Returns `true` iff `xs` starts with `prefix`
@@@]]

register1 "is_prefix_of" (function(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return false end
    end
    return true
end)

--[[@@@
```lua
F.is_suffix_of(suffix, xs)
suffix:is_suffix_of(xs)
```
> Returns `true` iff `xs` ends with `suffix`
@@@]]

register1 "is_suffix_of" (function(suffix, xs)
    for i = 1, #suffix do
        if xs[#xs-#suffix+i] ~= suffix[i] then return false end
    end
    return true
end)

--[[@@@
```lua
F.is_infix_of(infix, xs)
infix:is_infix_of(xs)
```
> Returns `true` iff `xs` caontains `infix`
@@@]]

register1 "is_infix_of" (function(infix, xs)
    for i = 1, #xs-#infix+1 do
        local found = true
        for j = 1, #infix do
            if xs[i+j-1] ~= infix[j] then found = false; break end
        end
        if found then return true end
    end
    return false
end)

--[[@@@
```lua
F.has_prefix(xs, prefix)
xs:has_prefix(prefix)
```
> Returns `true` iff `xs` starts with `prefix`
@@@]]

register1 "has_prefix" (function(xs, prefix) return F.is_prefix_of(prefix, xs) end)

--[[@@@
```lua
F.has_suffix(xs, suffix)
xs:has_suffix(suffix)
```
> Returns `true` iff `xs` ends with `suffix`
@@@]]

register1 "has_suffix" (function(xs, suffix) return F.is_suffix_of(suffix, xs) end)

--[[@@@
```lua
F.has_infix(xs, infix)
xs:has_infix(infix)
```
> Returns `true` iff `xs` caontains `infix`
@@@]]

register1 "has_infix" (function(xs, infix) return F.is_infix_of(infix, xs) end)

--[[@@@
```lua
F.is_subsequence_of(seq, xs)
seq:is_subsequence_of(xs)
```
> Returns `true` if all the elements of the first list occur, in order, in the second. The elements do not have to occur consecutively.
@@@]]

register1 "is_subsequence_of" (function(seq, xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local i = 1
    local j = 1
    while j <= #xs do
        if i > #seq then return true end
        if comp_eq(xs[j], seq[i]) then
            i = i+1
        end
        j = j+1
    end
    return false
end)

--[[@@@
```lua
F.is_submap_of(t1, t2)
t1:is_submap_of(t2)
```
> returns true if all keys in t1 are in t2.
@@@]]

register1 "is_submap_of" (function(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] == nil then return false end
    end
    return true
end)

--[[@@@
```lua
F.map_contains(t1, t2, [comp_eq])
t1:map_contains(t2, [comp_eq])
```
> returns true if all keys in t2 are in t1.
@@@]]

register1 "map_contains" (function(t1, t2, comp_eq)
    return F.is_submap_of(t2, t1, comp_eq)
end)

--[[@@@
```lua
F.is_proper_submap_of(t1, t2)
t1:is_proper_submap_of(t2)
```
> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are different.
@@@]]

register1 "is_proper_submap_of" (function(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] == nil then return false end
    end
    for k, _ in pairs(t2) do
        if t1[k] == nil then return true end
    end
    return false
end)

--[[@@@
```lua
F.map_strictly_contains(t1, t2, [comp_eq])
t1:map_strictly_contains(t2, [comp_eq])
```
> returns true if all keys in t2 are in t1.
@@@]]

register1 "map_strictly_contains" (function(t1, t2, comp_eq)
    return F.is_proper_submap_of(t2, t1, comp_eq)
end)

--[[------------------------------------------------------------------------@@@
## Searching
@@@]]

--[[@@@
```lua
F.elem(x, xs, [comp_eq])
xs:elem(x, [comp_eq])
```
> Returns `true` if x occurs in xs (using the optional comp_eq function).
@@@]]

register2 "elem" (function(x, xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    for i = 1, #xs do
        if comp_eq(xs[i], x) then return true end
    end
    return false
end)

--[[@@@
```lua
F.not_elem(x, xs, [comp_eq])
xs:not_elem(x, [comp_eq])
```
> Returns `true` if x does not occur in xs (using the optional comp_eq function).
@@@]]

register2 "not_elem" (function(x, xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    for i = 1, #xs do
        if comp_eq(xs[i], x) then return false end
    end
    return true
end)

--[[@@@
```lua
F.lookup(x, xys, [comp_eq])
xys:lookup(x, [comp_eq])
```
> Looks up a key `x` in an association list (using the optional comp_eq function).
@@@]]

register2 "lookup" (function(x, xys, comp_eq)
    comp_eq = comp_eq or F.op.eq
    for i = 1, #xys do
        if comp_eq(xys[i][1], x) then return xys[i][2] end
    end
    return nil
end)

--[[@@@
```lua
F.find(p, xs)
xs:find(p)
```
> Returns the leftmost element of xs matching the predicate p.
@@@]]

register2 "find" (function(p, xs)
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then return x end
    end
    return nil
end)

--[[@@@
```lua
F.filter(p, xs)
xs:filter(p)
```
> Returns the list of those elements that satisfy the predicate p(x).
@@@]]

register2 "filter" (function(p, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x end
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.filteri(p, xs)
xs:filteri(p)
```
> Returns the list of those elements that satisfy the predicate p(i, x).
@@@]]

register2 "filteri" (function(p, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(i, x) then ys[#ys+1] = x end
    end
    return setmt(ys)
end)

--[[@@@
```lua
F.filtert(p, t)
t:filtert(p)
```
> Returns the table of those values that satisfy the predicate p(v).
@@@]]

register2 "filtert" (function(p, t)
    local t2 = {}
    for k, v in pairs(t) do
        if p(v) then t2[k] = v end
    end
    return setmt(t2)
end)

--[[@@@
```lua
F.filterk(p, t)
t:filterk(p)
```
> Returns the table of those values that satisfy the predicate p(k, v).
@@@]]

register2 "filterk" (function(p, t)
    local t2 = {}
    for k, v in pairs(t) do
        if p(k, v) then t2[k] = v end
    end
    return setmt(t2)
end)

--[[@@@
```lua
F.restrict_keys(t, ks)
t:restrict_keys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

register1 "restrict_keys" (function(t, ks)
    local kset = F.from_set(F.const(true), ks)
    local function p(k, _) return kset[k] end
    return F.filterk(p, t)
end)

--[[@@@
```lua
F.without_keys(t, ks)
t:without_keys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

register1 "without_keys" (function(t, ks)
    local kset = F.from_set(F.const(true), ks)
    local function p(k, _) return not kset[k] end
    return F.filterk(p, t)
end)

--[[@@@
```lua
F.partition(p, xs)
xs:partition(p)
```
> Returns the pair of lists of elements which do and do not satisfy the predicate, respectively.
@@@]]

register2 "partition" (function(p, xs)
    local ys = {}
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x else zs[#zs+1] = x end
    end
    return setmt(ys), setmt(zs)
end)

--[[@@@
```lua
F.table_partition(p, t)
t:table_partition(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

register2 "table_partition" (function(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(v) then t1[k] = v else t2[k] = v end
    end
    return setmt(t1), setmt(t2)
end)

--[[@@@
```lua
F.table_partition_with_key(p, t)
t:table_partition_with_key(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

register2 "table_partition_with_key" (function(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(k, v) then t1[k] = v else t2[k] = v end
    end
    return setmt(t1), setmt(t2)
end)

--[[@@@
```lua
F.elem_index(x, xs)
xs:elem_index(x)
```
> Returns the index of the first element in the given list which is equal to the query element.
@@@]]

register2 "elem_index" (function(x, xs)
    for i = 1, #xs do
        if x == xs[i] then return i end
    end
    return nil
end)

--[[@@@
```lua
F.elem_indices(x, xs)
xs:elem_indices(x)
```
> Returns the indices of all elements equal to the query element, in ascending order.
@@@]]

register2 "elem_indices" (function(x, xs)
    local indices = {}
    for i = 1, #xs do
        if x == xs[i] then indices[#indices+1] = i end
    end
    return setmt(indices)
end)

--[[@@@
```lua
F.find_index(p, xs)
xs:find_index(p)
```
> Returns the index of the first element in the list satisfying the predicate.
@@@]]

register2 "find_index" (function(p, xs)
    for i = 1, #xs do
        if p(xs[i]) then return i end
    end
    return nil
end)

--[[@@@
```lua
F.find_indices(p, xs)
xs:find_indices(p)
```
> Returns the indices of all elements satisfying the predicate, in ascending order.
@@@]]

register2 "find_indices" (function(p, xs)
    local indices = {}
    for i = 1, #xs do
        if p(xs[i]) then indices[#indices+1] = i end
    end
    return setmt(indices)
end)

--[[------------------------------------------------------------------------@@@
## Table size
@@@]]

--[[@@@
```lua
F.null(xs)
xs:null()
F.null(t)
t:null("t")
```
> checks wether a list or a table is empty.
@@@]]

register1 "null" (function(t)
    return next(t) == nil
end)

--[[@@@
```lua
#xs
F.length(xs)
xs:length()
```
> Length of a list.
@@@]]

register1 "length" (function(xs)
    return #xs
end)

--[[@@@
```lua
F.size(t)
t:size()
```
> Size of a table (number of (key, value) pairs).
@@@]]

register1 "size" (function(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n+1
    end
    return n
end)

--[[------------------------------------------------------------------------@@@
## Table transformations
@@@]]

--[[@@@
```lua
F.map(f, xs)
xs:map(f)
```
> maps `f` to the elements of `xs` and returns `{f(xs[1]), f(xs[2]), ...}`
@@@]]

register2 "map" (function(f, xs)
    local ys = {}
    for i = 1, #xs do ys[i] = f(xs[i]) end
    return setmt(ys)
end)

--[[@@@
```lua
F.mapi(f, xs)
xs:mapi(f)
```
> maps `f` to the indices and elements of `xs` and returns `{f(1, xs[1]), f(2, xs[2]), ...}`
@@@]]

register2 "mapi" (function(f, xs)
    local ys = {}
    for i = 1, #xs do ys[i] = f(i, xs[i]) end
    return setmt(ys)
end)

--[[@@@
```lua
F.mapt(f, t)
t:mapt(f)
```
> maps `f` to the values of `t` and returns `{k1=f(t[k1]), k2=f(t[k2]), ...}`
@@@]]

register2 "mapt" (function(f, t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = f(v) end
    return setmt(t2)
end)

--[[@@@
```lua
F.mapk(f, t)
t:mapk(f)
```
> maps `f` to the keys and values of `t` and returns `{k1=f(k1, t[k1]), k2=f(k2, t[k2]), ...}`
@@@]]

register2 "mapk" (function(f, t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = f(k, v) end
    return setmt(t2)
end)

--[[@@@
```lua
F.reverse(xs)
xs:reverse()
```
> reverses the order of a list
@@@]]

register1 "reverse" (function(xs)
    local ys = {}
    for i = #xs, 1, -1 do ys[#ys+1] = xs[i] end
    return setmt(ys)
end)

--[[@@@
```lua
F.transpose(xss)
xss:transpose()
```
> Transposes the rows and columns of its argument.
@@@]]

register1 "transpose" (function(xss)
    local N = #xss
    local M = math.max(table.unpack(F.map(F.length, xss)))
    local yss = {}
    for j = 1, M do
        local ys = {}
        for i = 1, N do ys[#ys+1] = xss[i][j] end
        yss[j] = setmt(ys)
    end
    return setmt(yss)
end)

--[[@@@
```lua
F.update(f, k, t)
t:update(f, k)
```
> Updates the value `x` at `k`. If `f(x)` is nil, the element is deleted. Otherwise the key `k` is bound to the value `f(x)`.
>
> **Warning**: in-place modification.
@@@]]

register3 "update" (function(f, k, t)
    t[k] = f(t[k])
    return t
end)

--[[@@@
```lua
F.updatek(f, k, t)
t:updatek(f, k)
```
> Updates the value `x` at `k`. If `f(k, x)` is nil, the element is deleted. Otherwise the key `k` is bound to the value `f(k, x)`.
>
> **Warning**: in-place modification.
@@@]]

register3 "updatek" (function(f, k, t)
    t[k] = f(k, t[k])
    return t
end)

--[[------------------------------------------------------------------------@@@
## Table transversal
@@@]]

--[[@@@
```lua
F.foreach(xs, f)
xs:foreach(f)
```
> calls `f` with the elements of `xs` (`f(xi)` for `xi` in `xs`)
@@@]]

register1 "foreach" (function(xs, f)
    for i = 1, #xs do f(xs[i]) end
end)

--[[@@@
```lua
F.foreachi(xs, f)
xs:foreachi(f)
```
> calls `f` with the indices and elements of `xs` (`f(i, xi)` for `xi` in `xs`)
@@@]]

register1 "foreachi" (function(xs, f)
    for i = 1, #xs do f(i, xs[i]) end
end)

--[[@@@
```lua
F.foreacht(t, f)
t:foreacht(f)
```
> calls `f` with the values of `t` (`f(v)` for `v` in `t` such that `v = t[k]`)
@@@]]

register1 "foreacht" (function(t, f)
    for _, v in F.pairs(t) do f(v) end
end)

--[[@@@
```lua
F.foreachk(t, f)
t:foreachk(f)
```
> calls `f` with the keys and values of `t` (`f(k, v)` for (`k`, `v`) in `t` such that `v = t[k]`)
@@@]]

register1 "foreachk" (function(t, f)
    for k, v in F.pairs(t) do f(k, v) end
end)

--[[------------------------------------------------------------------------@@@
## Table reductions (folds)
@@@]]

--[[@@@
```lua
F.fold(f, x, xs)
xs:fold(f, x)
```
> Left-associative fold of a list (`f(...f(f(x, xs[1]), xs[2]), ...)`).
@@@]]

register3 "fold" (function(fzx, z, xs)
    for i = 1, #xs do
        z = fzx(z, xs[i])
    end
    return z
end)

--[[@@@
```lua
F.foldi(f, x, xs)
xs:foldi(f, x)
```
> Left-associative fold of a list (`f(...f(f(x, 1, xs[1]), 2, xs[2]), ...)`).
@@@]]

register3 "foldi" (function(fzx, z, xs)
    for i = 1, #xs do
        z = fzx(z, i, xs[i])
    end
    return z
end)

--[[@@@
```lua
F.fold1(f, xs)
xs:fold1(f)
```
> Left-associative fold of a list, the initial value is `xs[1]`.
@@@]]

register2 "fold1" (function(fzx, xs)
    if #xs == 0 then return nil end
    local z = xs[1]
    for i = 2, #xs do
        z = fzx(z, xs[i])
    end
    return z
end)

--[[@@@
```lua
F.foldt(f, x, t)
t:foldt(f, x)
```
> Left-associative fold of a table (in the order given by F.pairs).
@@@]]

register3 "foldt" (function(fzx, z, t)
    return F.values(t):fold(fzx, z)
end)

--[[@@@
```lua
F.foldk(f, x, t)
t:foldk(f, x)
```
> Left-associative fold of a table (in the order given by F.pairs).
@@@]]

register3 "foldk" (function(fzx, z, t)
    for _, kv in F.items(t):ipairs() do
        local k, v = table.unpack(kv)
        z = fzx(z, k, v)
    end
    return z
end)

--[[@@@
```lua
F.land(bs)
bs:land()
```
> Returns the conjunction of a container of booleans.
@@@]]

register1 "land" (function(bs)
    for i = 1, #bs do if not bs[i] then return false end end
    return true
end)

--[[@@@
```lua
F.lor(bs)
bs:lor()
```
> Returns the disjunction of a container of booleans.
@@@]]

register1 "lor" (function(bs)
    for i = 1, #bs do if bs[i] then return true end end
    return false
end)

--[[@@@
```lua
F.any(p, xs)
xs:any(p)
```
> Determines whether any element of the structure satisfies the predicate.
@@@]]

register2 "any" (function(p, xs)
    for i = 1, #xs do if p(xs[i]) then return true end end
    return false
end)

--[[@@@
```lua
F.all(p, xs)
xs:all(p)
```
> Determines whether all elements of the structure satisfy the predicate.
@@@]]

register2 "all" (function(p, xs)
    for i = 1, #xs do if not p(xs[i]) then return false end end
    return true
end)

--[[@@@
```lua
F.sum(xs)
xs:sum()
```
> Returns the sum of the numbers of a structure.
@@@]]

register1 "sum" (function(xs)
    local s = 0
    for i = 1, #xs do s = s + xs[i] end
    return s
end)

--[[@@@
```lua
F.product(xs)
xs:product()
```
> Returns the product of the numbers of a structure.
@@@]]

register1 "product" (function(xs)
    local p = 1
    for i = 1, #xs do p = p * xs[i] end
    return p
end)

--[[@@@
```lua
F.maximum(xs, [comp_lt])
xs:maximum([comp_lt])
```
> The largest element of a non-empty structure, according to the optional comparison function.
@@@]]

register1 "maximum" (function(xs, comp_lt)
    if #xs == 0 then return nil end
    comp_lt = comp_lt or F.op.lt
    local max = xs[1]
    for i = 2, #xs do
        if not comp_lt(xs[i], max) then max = xs[i] end
    end
    return max
end)

--[[@@@
```lua
F.minimum(xs, [comp_lt])
xs:minimum([comp_lt])
```
> The least element of a non-empty structure, according to the optional comparison function.
@@@]]

register1 "minimum" (function(xs, comp_lt)
    if #xs == 0 then return nil end
    comp_lt = comp_lt or F.op.lt
    local min = xs[1]
    for i = 2, #xs do
        if comp_lt(xs[i], min) then min = xs[i] end
    end
    return min
end)

--[[@@@
```lua
F.scan(f, x, xs)
xs:scan(f, x)
```
> Similar to `fold` but returns a list of successive reduced values from the left.
@@@]]

register3 "scan" (function(fzx, z, xs)
    local zs = {z}
    for i = 1, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return setmt(zs)
end)

--[[@@@
```lua
F.scan1(f, xs)
xs:scan1(f)
```
> Like `scan` but the initial value is `xs[1]`.
@@@]]

register2 "scan1" (function(fzx, xs)
    local z = xs[1]
    local zs = {z}
    for i = 2, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return setmt(zs)
end)

--[[@@@
```lua
F.concat_map(f, xs)
xs:concat_map(f)
```
> Map a function over all the elements of a container and concatenate the resulting lists.
@@@]]

register2 "concat_map" (function(fx, xs)
    return F.concat(F.map(fx, xs))
end)

--[[------------------------------------------------------------------------@@@
## Zipping
@@@]]

--[[@@@
```lua
F.zip(xss, [f])
xss:zip([f])
```
> `zip` takes a list of lists and returns a list of corresponding tuples.
@@@]]

register1 "zip" (function(xss, f)
    local yss = {}
    local ns = F.map(F.length, xss):minimum()
    for i = 1, ns do
        local ys = F.map(function(xs) return xs[i] end, xss)
        if f then
            yss[i] = f(table.unpack(ys))
        else
            yss[i] = ys
        end
    end
    return setmt(yss)
end)

--[[@@@
```lua
F.unzip(xss)
xss:unzip()
```
> Transforms a list of n-tuples into n lists
@@@]]

register1 "unzip" (function(xss)
    return table.unpack(F.zip(xss))
end)

--[[@@@
```lua
F.zip_with(f, xss)
xss:zip_with(f)
```
> `zip_with` generalises `zip` by zipping with the function given as the first argument, instead of a tupling function.
@@@]]

register2 "zip_with" (function(f, xss) return F.zip(xss, f) end)

--[[------------------------------------------------------------------------@@@
## Set operations
@@@]]

--[[@@@
```lua
F.nub(xs, [comp_eq])
xs:nub([comp_eq])
```
> Removes duplicate elements from a list. In particular, it keeps only the first occurrence of each element, according to the optional comp_eq function.
@@@]]

register1 "nub" (function(xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(x, ys[j]) then found = true; break end
        end
        if not found then ys[#ys+1] = x end
    end
    return F(ys)
end)

--[[@@@
```lua
F.delete(x, xs, [comp_eq])
xs:delete(x, [comp_eq])
```
> Removes the first occurrence of x from its list argument, according to the optional comp_eq function.
@@@]]

register2 "delete" (function(x, xs, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local ys = {}
    local i = 1
    while i <= #xs do
        if comp_eq(xs[i], x) then break end
        ys[#ys+1] = xs[i]
        i = i+1
    end
    i = i+1
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return F(ys)
end)

--[[@@@
```lua
F.difference(xs, ys, [comp_eq])
xs:difference(ys, [comp_eq])
```
> Returns the list difference. In `difference(xs, ys)`{.lua} the first occurrence of each element of ys in turn (if any) has been removed from xs, according to the optional comp_eq function.
@@@]]

register1 "difference" (function(xs, ys, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local zs = {}
    ys = {table.unpack(ys)}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(ys[j], x) then
                found = true
                table.remove(ys, j)
                break
            end
        end
        if not found then zs[#zs+1] = x end
    end
    return F(zs)
end)

--[[@@@
```lua
F.union(xs, ys, [comp_eq])
xs:union(ys, [comp_eq])
```
> Returns the list union of the two lists. Duplicates, and elements of the first list, are removed from the the second list, but if the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

register1 "union" (function(xs, ys, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local zs = {table.unpack(xs)}
    for i = 1, #ys do
        local y = ys[i]
        local found = false
        for j = 1, #zs do
            if comp_eq(y, zs[j]) then found = true; break end
        end
        if not found then zs[#zs+1] = y end
    end
    return F(zs)
end)

--[[@@@
```lua
F.intersection(xs, ys, [comp_eq])
xs:intersection(ys, [comp_eq])
```
> Returns the list intersection of two lists. If the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

register1 "intersection" (function(xs, ys, comp_eq)
    comp_eq = comp_eq or F.op.eq
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(x, ys[j]) then found = true; break end
        end
        if found then zs[#zs+1] = x end
    end
    return F(zs)
end)

--[[------------------------------------------------------------------------@@@
## Table operations
@@@]]

--[[@@@
```lua
F.merge(ts)
ts:merge()
F.table_union(ts)
ts:table_union()
```
> Right-biased union of tables.
@@@]]

register1 "merge" (function(ts)
    local u = {}
    for i = 1, #ts do
        for k, v in pairs(ts[i]) do u[k] = v end
    end
    return F(u)
end)

register1 "table_union" (F.merge)

--[[@@@
```lua
F.merge_with(f, ts)
ts:merge_with(f)
F.table_union_with(f, ts)
ts:table_union_with(f)
```
> Right-biased union of tables with a combining function.
@@@]]

register2 "merge_with" (function(f, ts)
    local u = {}
    for i = 1, #ts do
        for k, v in pairs(ts[i]) do
            local uk = u[k]
            if uk == nil then
                u[k] = v
            else
                u[k] = f(u[k], v)
            end
        end
    end
    return F(u)
end)

register2 "table_union_with" (F.merge_with)

--[[@@@
```lua
F.merge_with_key(f, ts)
ts:merge_with_key(f)
F.table_union_with_key(f, ts)
ts:table_union_with_key(f)
```
> Right-biased union of tables with a combining function.
@@@]]

register2 "merge_with_key" (function(f, ts)
    local u = {}
    for i = 1, #ts do
        for k, v in pairs(ts[i]) do
            local uk = u[k]
            if uk == nil then
                u[k] = v
            else
                u[k] = f(k, u[k], v)
            end
        end
    end
    return F(u)
end)

register2 "table_union_with_key" (F.merge_with_key)

--[[@@@
```lua
F.table_difference(t1, t2)
t1:table_difference(t2)
```
> Difference of two maps. Return elements of the first map not existing in the second map.
@@@]]

register1 "table_difference" (function(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] == nil then t[k] = v end end
    return F(t)
end)

--[[@@@
```lua
F.table_difference_with(f, t1, t2)
t1:table_difference_with(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

register2 "table_difference_with" (function(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(v1, v2)
        end
    end
    return F(t)
end)

--[[@@@
```lua
F.table_difference_with_key(f, t1, t2)
t1:table_difference_with_key(f, t2)
```
> Union with a combining function.
@@@]]

register2 "table_difference_with_key" (function(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(k, v1, v2)
        end
    end
    return F(t)
end)

--[[@@@
```lua
F.table_intersection(t1, t2)
t1:table_intersection(t2)
```
> Intersection of two maps. Return data in the first map for the keys existing in both maps.
@@@]]

register1 "table_intersection" (function(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] ~= nil then t[k] = v end end
    return F(t)
end)

--[[@@@
```lua
F.table_intersection_with(f, t1, t2)
t1:table_intersection_with(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

register2 "table_intersection_with" (function(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(v1, v2)
        end
    end
    return F(t)
end)

--[[@@@
```lua
F.table_intersection_with_key(f, t1, t2)
t1:table_intersection_with_key(f, t2)
```
> Union with a combining function.
@@@]]

register2 "table_intersection_with_key" (function(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(k, v1, v2)
        end
    end
    return F(t)
end)

--[[@@@
```lua
F.disjoint(t1, t2)
t1:disjoint(t2)
```
> Check the intersection of two maps is empty.
@@@]]

register1 "disjoint" (function(t1, t2)
    for k, _ in pairs(t1) do if t2[k] ~= nil then return false end end
    return true
end)

--[[@@@
```lua
F.table_compose(t1, t2)
t1:table_compose(t2)
```
> Relate the keys of one map to the values of the other, by using the values of the former as keys for lookups in the latter.
@@@]]

register1 "table_compose" (function(t1, t2)
    local t = {}
    for k2, v2 in pairs(t2) do
        local v1 = t1[v2]
        t[k2] = v1
    end
    return F(t)
end)

--[[@@@
```lua
F.Nil
```
> `F.Nil` is a singleton used to represent `nil` (see `F.patch`)
@@@]]
local Nil = setmetatable({}, {
    __name = "Nil",
    __call = function(_) return nil end,
    __tostring = function(_) return "Nil" end,
})
F.Nil = Nil

--[[@@@
```lua
F.patch(t1, t2)
t1:patch(t2)
```
> returns a copy of `t1` where some fields are replaced by values from `t2`.
Keys not found in `t2` are not modified.
If `t2` contains `F.Nil` then the corresponding key is removed from `t1`.
Unmodified subtrees are not cloned but returned as is (common subtrees are shared).
@@@]]

local function patch(t1, t2)
    if t2 == nil then return t1 end -- value not patched
    if t2 == Nil then return nil end -- remove t1
    if type(t1) ~= "table" then return t2 end -- replace a scalar field by a scalar or a table
    if type(t2) ~= "table" then return t2 end -- a scalar replaces a scalar or a table
    local t = {}
    -- patch fields from t1 with values from t2
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        t[k] = patch(v1, v2)
    end
    -- add new values from t2
    for k, v2 in pairs(t2) do
        local v1 = t1[k]
        if v1 == nil then
            t[k] = v2
        end
    end
    return setmt(t)
end

register1 "patch" (patch)

--[[------------------------------------------------------------------------@@@
## Ordered lists
@@@]]

--[[@@@
```lua
F.sort(xs, [comp_lt])
xs:sort([comp_lt])
```
> Sorts xs from lowest to highest, according to the optional comp_lt function.
@@@]]

register1 "sort" (function(xs, comp_lt)
    local ys = {}
    for i = 1, #xs do ys[i] = xs[i] end
    table.sort(ys, comp_lt)
    return F(ys)
end)

--[[@@@
```lua
F.sort_on(f, xs, [comp_lt])
xs:sort_on(f, [comp_lt])
```
> Sorts a list by comparing the results of a key function applied to each element, according to the optional comp_lt function.
@@@]]

register2 "sort_on" (function(f, xs, comp_lt)
    comp_lt = comp_lt or F.op.lt
    local ys = {}
    for i = 1, #xs do ys[i] = {f(xs[i]), xs[i]} end
    table.sort(ys, function(a, b) return comp_lt(a[1], b[1]) end)
    local zs = {}
    for i = 1, #ys do zs[i] = ys[i][2] end
    return F(zs)
end)

--[[@@@
```lua
F.insert(x, xs, [comp_lt])
xs:insert(x, [comp_lt])
```
> Inserts the element into the list at the first position where it is less than or equal to the next element, according to the optional comp_lt function.
@@@]]

register2 "insert" (function(x, xs, comp_lt)
    comp_lt = comp_lt or F.op.lt
    local ys = {}
    local i = 1
    while i <= #xs and not comp_lt(x, xs[i]) do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    ys[#ys+1] = x
    while i <= #xs do
        ys[#ys+1] = xs[i]
        i = i+1
    end
    return F(ys)
end)

--[[------------------------------------------------------------------------@@@
## Miscellaneous functions
@@@]]

--[[@@@
```lua
F.subsequences(xs)
xs:subsequences()
```
> Returns the list of all subsequences of the argument.
@@@]]

register1 "subsequences" (function(xs)
    local function subsequences(ys)
        if F.null(ys) then return F{{}} end
        local inits = subsequences(F.init(ys))
        local last = F.last(ys)
        return inits .. F.map(function(seq) return F.concat{seq, {last}} end, inits)
    end
    return subsequences(xs)
end)

--[[@@@
```lua
F.permutations(xs)
xs:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]

register1 "permutations" (function(xs)
    local perms = {}
    local n = #xs
    xs = F.clone(xs)
    local function permute(k)
        if k > n then perms[#perms+1] = F.clone(xs)
        else
            for i = k, n do
                xs[k], xs[i] = xs[i], xs[k]
                permute(k+1)
                xs[k], xs[i] = xs[i], xs[k]
            end
        end
    end
    permute(1)
    return setmt(perms)
end)

--[[------------------------------------------------------------------------@@@
## Functions on strings
@@@]]

--[[@@@
```lua
string.chars(s, i, j)
s:chars(i, j)
```
> Returns the list of characters of a string between indices i and j, or the whole string if i and j are not provided.
@@@]]

function string.chars(s, i, j)
    return s:bytes(i, j):map(string.char)
end

--[[@@@
```lua
string.bytes(s, i, j)
s:bytes(i, j)
```
> Returns the list of byte codes of a string between indices i and j, or the whole string if i and j are not provided.
@@@]]

function string.bytes(s, i, j)
    i = i or 1
    j = j or -1
    return F{s:byte(i, j)}
end

--[[@@@
```lua
string.head(s)
s:head()
```
> Extract the first element of a string.
@@@]]

function string.head(s)
    if #s == 0 then return nil end
    return s:sub(1, 1)
end

--[[@@@
```lua
sting.last(s)
s:last()
```
> Extract the last element of a string.
@@@]]

function string.last(s)
    if #s == 0 then return nil end
    return s:sub(#s)
end

--[[@@@
```lua
string.tail(s)
s:tail()
```
> Extract the elements after the head of a string
@@@]]

function string.tail(s)
    if #s == 0 then return nil end
    return s:sub(2)
end

--[[@@@
```lua
string.init(s)
s:init()
```
> Return all the elements of a string except the last one.
@@@]]

function string.init(s)
    if #s == 0 then return nil end
    return s:sub(1, #s-1)
end

--[[@@@
```lua
string.uncons(s)
s:uncons()
```
> Decompose a string into its head and tail.
@@@]]

function string.uncons(s)
    return s:head(), s:tail()
end

--[[@@@
```lua
string.null(s)
s:null()
```
> Test whether the string is empty.
@@@]]

function string.null(s)
    return #s == 0
end

--[[@@@
```lua
string.length(s)
s:length()
```
> Returns the length of a string.
@@@]]

function string.length(s)
    return #s
end

--[[@@@
```lua
string.intersperse(c, s)
c:intersperse(s)
```
> Intersperses a element c between the elements of s.
@@@]]

function string.intersperse(c, s)
    if #s < 2 then return s end
    local chars = {}
    for i = 1, #s-1 do
        chars[#chars+1] = s:sub(i, i)
        chars[#chars+1] = c
    end
    chars[#chars+1] = s:sub(#s)
    return table.concat(chars)
end

--[[@@@
```lua
string.intercalate(s, ss)
s:intercalate(ss)
```
> Inserts the string s in between the strings in ss and concatenates the result.
@@@]]

function string.intercalate(s, ss)
    return table.concat(ss, s)
end

--[[@@@
```lua
string.subsequences(s)
s:subsequences()
```
> Returns the list of all subsequences of the argument.
@@@]]

function string.subsequences(s)
    if s:null() then return {""} end
    local inits = s:init():subsequences()
    local last = s:last()
    return inits .. F.map(function(seq) return seq..last end, inits)
end

--[[@@@
```lua
string.permutations(s)
s:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]

function string.permutations(s)
    return s:chars():permutations():map(table.concat)
end

--[[@@@
```lua
string.take(s, n)
s:take(n)
```
> Returns the prefix of s of length n.
@@@]]

function string.take(s, n)
    if n <= 0 then return "" end
    return s:sub(1, n)
end

--[[@@@
```lua
string.drop(s, n)
s:drop(n)
```
> Returns the suffix of s after the first n elements.
@@@]]

function string.drop(s, n)
    if n <= 0 then return s end
    return s:sub(n+1)
end

--[[@@@
```lua
string.split_at(s, n)
s:split_at(n)
```
> Returns a tuple where first element is s prefix of length n and second element is the remainder of the string.
@@@]]

function string.split_at(s, n)
    return s:take(n), s:drop(n)
end

--[[@@@
```lua
string.take_while(s, p)
s:take_while(p)
```
> Returns the longest prefix (possibly empty) of s of elements that satisfy p.
@@@]]

function string.take_while(s, p)
    return s:chars():take_while(p):str()
end

--[[@@@
```lua
string.drop_while(s, p)
s:drop_while(p)
```
> Returns the suffix remaining after `s:take_while(p)`{.lua}.
@@@]]

function string.drop_while(s, p)
    return s:chars():drop_while(p):str()
end

--[[@@@
```lua
string.drop_while_end(s, p)
s:drop_while_end(p)
```
> Drops the largest suffix of a string in which the given predicate holds for all elements.
@@@]]

function string.drop_while_end(s, p)
    return s:chars():drop_while_end(p):str()
end

--[[@@@
```lua
string.strip_prefix(s, prefix)
s:strip_prefix(prefix)
```
> Drops the given prefix from a string.
@@@]]

function string.strip_prefix(s, prefix)
    local n = #prefix
    if s:sub(1, n) == prefix then return s:sub(n+1) end
    return nil
end

--[[@@@
```lua
string.strip_suffix(s, suffix)
s:strip_suffix(suffix)
```
> Drops the given suffix from a string.
@@@]]

function string.strip_suffix(s, suffix)
    local n = #suffix
    if s:sub(#s-n+1) == suffix then return s:sub(1, #s-n) end
    return nil
end

--[[@@@
```lua
string.inits(s)
s:inits()
```
> Returns all initial segments of the argument, shortest first.
@@@]]

function string.inits(s)
    local ss = {}
    for i = 0, #s do
        ss[#ss+1] = s:sub(1, i)
    end
    return F(ss)
end

--[[@@@
```lua
string.tails(s)
s:tails()
```
> Returns all final segments of the argument, longest first.
@@@]]

function string.tails(s)
    local ss = {}
    for i = 1, #s+1 do
        ss[#ss+1] = s:sub(i)
    end
    return F(ss)
end

--[[@@@
```lua
string.is_prefix_of(prefix, s)
prefix:is_prefix_of(s)
```
> Returns `true` iff the first string is a prefix of the second.
@@@]]

function string.is_prefix_of(prefix, s)
    return s:sub(1, #prefix) == prefix
end

--[[@@@
```lua
string.has_prefix(s, prefix)
s:has_prefix(prefix)
```
> Returns `true` iff the second string is a prefix of the first.
@@@]]

function string.has_prefix(s, prefix)
    return s:sub(1, #prefix) == prefix
end

--[[@@@
```lua
string.is_suffix_of(suffix, s)
suffix:is_suffix_of(s)
```
> Returns `true` iff the first string is a suffix of the second.
@@@]]

function string.is_suffix_of(suffix, s)
    return s:sub(#s-#suffix+1) == suffix
end

--[[@@@
```lua
string.has_suffix(s, suffix)
s:has_suffix(suffix)
```
> Returns `true` iff the second string is a suffix of the first.
@@@]]

function string.has_suffix(s, suffix)
    return s:sub(#s-#suffix+1) == suffix
end

--[[@@@
```lua
string.is_infix_of(infix, s)
infix:is_infix_of(s)
```
> Returns `true` iff the first string is contained, wholly and intact, anywhere within the second.
@@@]]

function string.is_infix_of(infix, s)
    return s:find(infix) ~= nil
end

--[[@@@
```lua
string.has_infix(s, infix)
s:has_infix(infix)
```
> Returns `true` iff the second string is contained, wholly and intact, anywhere within the first.
@@@]]

function string.has_infix(s, infix)
    return s:find(infix) ~= nil
end

--[[@@@
```lua
string.matches(s, pattern, [init])
s:matches(pattern, [init])
```
> Returns the list of the captures from `pattern` by iterating on `string.gmatch`.
  If `pattern` defines two or more captures, the result is a list of list of captures.
@@@]]

function string.matches(s, pattern, init)
    local iterator = s:gmatch(pattern, init)
    local ms = F{}
    while true do
        local xs = {iterator()}
        if #xs == 0 then return ms end
        if #xs == 1 then xs = xs[1] end
        ms[#ms+1] = xs
    end
end

--[[@@@
```lua
string.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```
> Splits a string `s` around the separator `sep`. `maxsplit` is the maximal number of separators. If `plain` is true then the separator is a plain string instead of a Lua string pattern.
@@@]]

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
    return F(items)
end

--[[@@@
```lua
string.lines(s)
s:lines()
```
> Splits the argument into a list of lines stripped of their terminating `\n` characters.
@@@]]

function string.lines(s)
    local lines = s:split('\r?\n\r?')
    if lines[#lines] == "" and s:match('\r?\n\r?$') then table.remove(lines) end
    return F(lines)
end

--[[@@@
```lua
string.words(s)
s:words()
```
> Breaks a string up into a list of words, which were delimited by white space.
@@@]]

function string.words(s)
    local words = s:split('%s+')
    if words[1] == "" and s:match('^%s+') then table.remove(words, 1) end
    if words[#words] == "" and s:match('%s+$') then table.remove(words) end
    return F(words)
end

--[[@@@
```lua
F.unlines(xs)
xs:unlines()
```
> Appends a `\n` character to each input string, then concatenates the results.
@@@]]

register1 "unlines" (function(xs)
    local s = {}
    for i = 1, #xs do
        s[#s+1] = xs[i]
        s[#s+1] = "\n"
    end
    return table.concat(s)
end)

--[[@@@
```lua
string.unwords(xs)
xs:unwords()
```
> Joins words with separating spaces.
@@@]]

register1 "unwords" (function(xs)
    return table.concat(xs, " ")
end)

--[[@@@
```lua
string.ltrim(s)
s:ltrim()
```
> Removes heading spaces
@@@]]

function string.ltrim(s)
    return (s:match("^%s*(.*)"))
end

--[[@@@
```lua
string.rtrim(s)
s:rtrim()
```
> Removes trailing spaces
@@@]]

function string.rtrim(s)
    return (s:match("(.-)%s*$"))
end

--[[@@@
```lua
string.trim(s)
s:trim()
```
> Removes heading and trailing spaces
@@@]]

function string.trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

--[[@@@
```lua
string.cap(s)
s:cap()
```
> Capitalizes a string. The first character is upper case, other are lower case.
@@@]]

function string.cap(s)
    return s:head():upper()..s:tail():lower()
end

--[[------------------------------------------------------------------------@@@
## Identifier formatting
@@@]]

local function split_identifier(...)
    local words = F{}
    local function add_word(name)
        -- an upper case letter starts a new word
        name = tostring(name):gsub("([^%u])(%u)", "%1_%2")
        -- split words
        for w in name:gmatch"%w+" do words[#words+1] = w end
    end
    F.flatten{...}:foreach(add_word)
    return words
end

--[[@@@
```lua
string.lower_snake_case(s)              -- e.g.: hello_world
string.upper_snake_case(s)              -- e.g.: HELLO_WORLD
string.lower_camel_case(s)              -- e.g.: helloWorld
string.upper_camel_case(s)              -- e.g.: HelloWorld
string.dotted_lower_snake_case(s)       -- e.g.: hello.world
string.dotted_upper_snake_case(s)       -- e.g.: hello.world

F.lower_snake_case(s)                   -- e.g.: hello_world
F.upper_snake_case(s)                   -- e.g.: HELLO_WORLD
F.lower_camel_case(s)                   -- e.g.: helloWorld
F.upper_camel_case(s)                   -- e.g.: HelloWorld
F.dotted_lower_snake_case(s)            -- e.g.: hello.world
F.dotted_upper_snake_case(s)            -- e.g.: hello.world

s:lower_snake_case()                    -- e.g.: hello_world
s:upper_snake_case()                    -- e.g.: HELLO_WORLD
s:lower_camel_case()                    -- e.g.: helloWorld
s:upper_camel_case()                    -- e.g.: HelloWorld
s:dotted_lower_snake_case()             -- e.g.: hello.world
s:dotted_upper_snake_case()             -- e.g.: hello.world
```
> Convert an identifier using some wellknown naming conventions.
  `s` can be a string or a list of strings.
@@@]]

function string.lower_snake_case(...)
    return split_identifier(...):map(string.lower):str"_"
end

function string.upper_snake_case(...)
    return split_identifier(...):map(string.upper):str"_"
end

function string.lower_camel_case(...)
    return split_identifier(...):map(string.cap):str():gsub("^%w", string.lower)
end

function string.upper_camel_case(...)
    return split_identifier(...):map(string.cap):str()
end

function string.dotted_lower_snake_case(...)
    return split_identifier(...):map(string.lower):str"."
end

function string.dotted_upper_snake_case(...)
    return split_identifier(...):map(string.upper):str"."
end

register1 "lower_snake_case" (string.lower_snake_case)
register1 "upper_snake_case" (string.upper_snake_case)
register1 "lower_camel_case" (string.lower_camel_case)
register1 "upper_camel_case" (string.upper_camel_case)
register1 "dotted_lower_snake_case" (string.dotted_lower_snake_case)
register1 "dotted_upper_snake_case" (string.dotted_upper_snake_case)

--[[------------------------------------------------------------------------@@@
## String evaluation
@@@]]

--[[@@@
```lua
string.read(s)
s:read()
```
> Convert s to a Lua value (like `F.read`)
@@@]]

string.read = F.read

--[[------------------------------------------------------------------------@@@
## String interpolation
@@@]]

--[[@@@
```lua
F.I(t)
```
> returns a string interpolator that replaces `$(...)` with
> the value of `...` in the environment defined by the table `t`.
> An interpolator can be given another table
> to build a new interpolator with new values.
>
> The mod operator (`%`) produces a new interpolator with a custom pattern.
> E.g. `F.I % "@[]"` is an interpolator that replaces `@[...]` with
> the value of `...`.
@@@]]

local interpolator_mt = {}

function interpolator_mt.__mod(self, pattern)
    assert(type(pattern)=="string" and #pattern>=3)
    return setmetatable({
        pattern = pattern:gsub("^(.+)(.)(.)$", "%1(%%b%2%3)"),
        env = self.env
    }, interpolator_mt)
end

function interpolator_mt.__call(self, s)
    if type(s) == "string" then
        return (s:gsub(self.pattern, function(x)
            local y = ((assert(load("return "..x:sub(2,-2), nil, "t", self.env)))())
            if type(y) == "table" or type(y) == "userdata" then
                y = tostring(y)
            end
            return y
        end))
    end
    if type(s) == "table" then
        local new_env = s
        return setmetatable({
            pattern = self.pattern,
            env = setmetatable({}, {
                __index = function(_, k)
                    local v = new_env[k]
                    if v ~= nil then return v end
                    return self.env and self.env[k]
                end
            })
        }, interpolator_mt)
    end
    error "An interpolator expects a table or a string"
end

F.I = setmetatable({env=nil}, interpolator_mt) % "%$()"

--[[------------------------------------------------------------------------@@@
## Random array access

@@@]]

--[[@@@
```lua
F.choose(xs, prng)
F.choose(xs)    -- using the global PRNG
xs:choose(prng)
xs:choose()     -- using the global PRNG
```
returns a random item from `xs`
@@@]]

register1 "choose" (function(xs, prng)
    if prng then
        return prng:choose(xs)
    else
        return require "crypt".choose(xs)
    end
end)

--[[@@@
```lua
F.shuffle(xs, prng)
F.shuffle(xs)   -- using the global PRNG
xs:shuffle(prng)
xs:shuffle()    -- using the global PRNG
```
returns a shuffled copy of `xs`
@@@]]

register1 "shuffle" (function(xs, prng)
    if prng then
        return prng:shuffle(xs)
    else
        return require "crypt".shuffle(xs)
    end
end)

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return setmetatable(F, {
    __call = function(_, t)
        if type(t) == "table" then return setmt(t) end
        return t
    end,
})
]==]),
["L"] = lib("libluax/L/L.lua", [=[--[[
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

--@LIB

--[[------------------------------------------------------------------------@@@
# L: Pandoc List package

```lua
local L = require "L"
```

`L` is just a shortcut to `Pandoc.List`.

@@@]]

local L = pandoc and pandoc.List

local F = require "F"

if not L then

    local mt = {__index={}}

    L = {}

    function mt.__concat(l1, l2)
        return setmetatable(F.concat{l1, l2}, mt)
    end

    function mt.__eq(l1, l2)
        return F.ueq(l1, l2)
    end

    function mt.__index:clone()
        return setmetatable(F.clone(self), mt)
    end

    function mt.__index:extend(l)
        for i = 1, #l do
            self[#self+1] = l[i]
        end
    end

    function mt.__index:find(needle, init)
        for i = init or 1, #self do
            if F.ueq(self[i], needle) then
                return self[i], i
            end
        end
    end

    function mt.__index:find_if(pred, init)
        for i = init or 1, #self do
            if pred(self[i]) then
                return self[i], i
            end
        end
    end

    function mt.__index:filter(pred)
        return setmetatable(F.filter(pred, self), mt)
    end

    function mt.__index:includes(needle, init)
        for i = init or 1, #self do
            if F.ueq(self[i], needle) then
                return true
            end
        end
        return false
    end

    function mt.__index:insert(pos, value)
        return table.insert(self, pos, value)
    end

    function mt.__index:map(fn)
        return setmetatable(F.map(fn, self), mt)
    end

    function mt.__index:new(t)
        return setmetatable(t or {}, mt)
    end

    function mt.__index:remove(pos)
        return table.remove(self, pos)
    end

    function mt.__index:sort(comp)
        return table.sort(self, comp)
    end

    setmetatable(L, {
        __index = {
            __call = function(self) return L.new(self) end,
        },
    })

end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

return L
]=]),
["complex"] = lib("libluax/complex/complex.lua", [=[--[[
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

--@LIB
local _, complex = pcall(require, "_complex")
complex = _ and complex

if not complex then

    -- see https://github.com/krakow10/Complex-Number-Library/blob/master/Lua/Complex.lua

    local mathx = require "mathx"

    local e = math.exp(1)
    local pi = math.pi
    local abs = math.abs
    local exp = math.exp
    local log = math.log
    local cos = math.cos
    local sin = math.sin
    local cosh = mathx.cosh
    local sinh = mathx.sinh
    local atan2 = math.atan

    local mt = {__index={}}

    ---@diagnostic disable:unused-vararg
    local function ni(f) return function(...) error(f.." not implemented") end end

    local forget = 1e-14

    local function new(x, y)
        if forget then
            if x and abs(x) <= forget then x = 0 end
            if y and abs(y) <= forget then y = 0 end
        end
        return setmetatable({x=x or 0, y=y or 0}, mt)
    end

    local i = new(0, 1)

    local function _z(z)
        if type(z) == "table" and getmetatable(z) == mt then return z end
        return new(tonumber(z), 0)
    end

    function mt.__index.real(z) return z.x end

    function mt.__index.imag(z) return z.y end

    local function rect(r, phi)
        return new(r*cos(phi), r*sin(phi))
    end

    local function arg(z)
        return atan2(z.y, z.x)
    end

    local function ln(z)
        return new(log(z.x^2+z.y^2)/2, atan2(z.y, z.x))
    end

    function mt.__index.conj(z)
        return new(z.x, -z.y)
    end

    function mt.__add(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        return new(z1.x+z2.x, z1.y+z2.y)
    end

    function mt.__sub(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        return new(z1.x-z2.x, z1.y-z2.y)
    end

    function mt.__mul(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        return new(z1.x*z2.x-z1.y*z2.y, z1.x*z2.y+z2.x*z1.y)
    end

    function mt.__div(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        local d = z2.x^2 + z2.y^2
        return new((z1.x*z2.x+z1.y*z2.y)/d, (z2.x*z1.y-z1.x*z2.y)/d)
    end

    function mt.__pow(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        local z1sq = z1.x^2 + z1.y^2
        if z1sq == 0 then
            if z2.x == 0 and z2.y == 0 then return 1 end
            return 0
        end
        local phi = arg(z1)
        return rect(z1sq^(z2.x/2)*exp(-z2.y*phi), z2.y*log(z1sq)/2+z2.x*phi)
    end

    function mt.__unm(z)
        return new(-z.x, -z.y)
    end

    function mt.__eq(z1, z2)
        z1 = _z(z1)
        z2 = _z(z2)
        return z1.x == z2.x and z1.y == z2.y
    end

    function mt.__tostring(z)
        if z.y == 0 then return tostring(z.x) end
        if z.x == 0 then
            if z.y == 1 then return "i" end
            if z.y == -1 then return "-i" end
            return z.y.."i"
        end
        if z.y == 1 then return z.x.."+i" end
        if z.y == -1 then return z.x.."-i" end
        if z.y < 0 then return z.x..z.y.."i" end
        return z.x.."+"..z.y.."i"
    end

    function mt.__index.abs(z)
        return (z.x^2+z.y^2)^0.5
    end

    mt.__index.arg = arg

    function mt.__index.exp(z)
        return e^z
    end

    function mt.__index.sqrt(z)
        return z^0.5
    end

    function mt.__index.sin(z)
        return new(sin(z.x)*cosh(z.y), cos(z.x)*sinh(z.y))
    end

    function mt.__index.cos(z)
        return new(cos(z.x)*cosh(z.y), -sin(z.x)*sinh(z.y))
    end

    function mt.__index.tan(z)
        z = 2*z
        local div = cos(z.x) + cosh(z.y)
        return new(sin(z.x)/div, sinh(z.y)/div)
    end

    function mt.__index.sinh(z)
        return new(cos(z.y)*sinh(z.x), sin(z.y)*cosh(z.x))
    end

    function mt.__index.cosh(z)
        return new(cos(z.y)*cosh(z.x), sin(z.y)*sinh(z.x))
    end

    function mt.__index.tanh(z)
        z = 2*z
        local div = cos(z.y) + cosh(z.x)
        return new(sinh(z.x)/div, sin(z.y)/div)
    end

    function mt.__index.asin(z)
        return -i*ln(i*z+(1-z^2)^0.5)
    end

    function mt.__index.acos(z)
        return pi/2 + i*ln(i*z+(1-z^2)^0.5)
    end

    function mt.__index.atan(z)
        local z3, z4 = new(1-z.y, z.x), new(1+z.x^2-z.y^2, 2*z.x*z.y)
        return new(arg(z3/z4^0.5), -log(z3:abs()/z4:abs()^0.5))
    end

    function mt.__index.asinh(z)
        return ln(z+(1+z^2)^0.5)
    end

    function mt.__index.acosh(z)
        return 2*ln((z-1)^0.5+(z+1)^0.5)-log(2)
    end

    function mt.__index.atanh(z)
        return (ln(1+z)-ln(1-z))/2
    end

    mt.__index.log = ln

    mt.__index.proj = ni "proj"

    complex = {
        new = new,
        I = i,
        real = function(z) return _z(z):real() end,
        imag = function(z) return _z(z):imag() end,
        abs = function(z) return _z(z):abs() end,
        arg = function(z) return _z(z):arg() end,
        exp = function(z) return _z(z):exp() end,
        sqrt = function(z) return _z(z):sqrt() end,
        sin = function(z) return _z(z):sin() end,
        cos = function(z) return _z(z):cos() end,
        tan = function(z) return _z(z):tan() end,
        sinh = function(z) return _z(z):sinh() end,
        cosh = function(z) return _z(z):cosh() end,
        tanh = function(z) return _z(z):tanh() end,
        asin = function(z) return _z(z):asin() end,
        acos = function(z) return _z(z):acos() end,
        atan = function(z) return _z(z):atan() end,
        asinh = function(z) return _z(z):asinh() end,
        acosh = function(z) return _z(z):acosh() end,
        atanh = function(z) return _z(z):atanh() end,
        pow = function(z, z2) return _z(z) ^ z2 end,
        log = function(z) return _z(z):log() end,
        proj = function(z) return _z(z):proj() end,
        conj = function(z) return _z(z):conj() end,
        tostring = function(z) return _z(z):tostring() end,
    }

end

return complex
]=]),
["crypt"] = lib("libluax/crypt/crypt.lua", [=[--[[
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

-- Load crypt.lua to add new methods to strings
--@LOAD=_

local _, crypt = pcall(require, "_crypt")
crypt = _ and crypt

local F = require "F"

-- Pure Lua implementation
if not crypt then

    crypt = {}

    -- Random number generator

    local prng_mt = {__index={}}

    local random = math.random

    local byte = string.byte
    local char = string.char
    local format = string.format
    local gsub = string.gsub

    local concat = table.concat

    local tonumber = tonumber

    local RAND_MAX = 0xFFFFFFFF

    crypt.RAND_MAX = RAND_MAX

    function crypt.prng(seed, inc)
        local self = setmetatable({}, prng_mt)
        self:seed(seed or random(0), inc)
        return self
    end

    function prng_mt.__index:seed(seed, inc)
        self.state = assert(seed, "seed parameter missing")
        self.inc = (inc or 1) | 1
        self.state = 6364136223846793005*self.state + self.inc
        self.state = 6364136223846793005*self.state + self.inc
    end

    function prng_mt.__index:int(a, b)
        local oldstate = self.state
        self.state = 6364136223846793005*self.state + self.inc
        local xorshifted = (((oldstate >> 18) ~ oldstate) >> 27) & 0xFFFFFFFF
        local rot = oldstate >> 59;
        local r = ((xorshifted >> rot) | (xorshifted << ((-rot) & 31))) & 0xFFFFFFFF

        if not a then return r end
        if not b then return r % (a+1) end
        return r % (b-a+1) + a
    end

    function prng_mt.__index:float(a, b)
        local r = self:int()
        if not a then return r / RAND_MAX end
        if not b then return r * a/RAND_MAX end
        return r * (b-a)/RAND_MAX + a
    end

    function prng_mt.__index:str(n)
        local bs = {}
        for i = 1, n do
            bs[i] = char(self:int(0, 255))
        end
        return concat(bs)
    end

    -- global random number generator
    local _rng = crypt.prng()
    function crypt.seed(...) return _rng:seed(...) end
    function crypt.int(...) return _rng:int(...) end
    function crypt.float(...) return _rng:float(...) end
    function crypt.str(...) return _rng:str(...) end

    -- Hexadecimal encoding

    function crypt.hex(s)
        return (gsub(s, '.', function(c) return format("%02x", byte(c)) end))
    end

    function crypt.unhex(s)
        return (gsub(s, '..', function(h) return char(tonumber(h, 16)) end))
    end

    -- Base64 encoding

    -- see <https://en.wikipedia.org/wiki/Base64>

    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    function crypt.base64(s)
        return ((s:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b64chars:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#s%3+1])
    end

    function crypt.base64url(s)
        return crypt.base64(s):gsub("+", "-"):gsub("/", "_")
    end

    function crypt.unbase64(s)
        s = string.gsub(s, '[^'..b64chars..'=]', '')
        return (s:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b64chars:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end

    function crypt.unbase64url(s)
        return crypt.unbase64(s:gsub("-", "+"):gsub("_", "/"))
    end

    -- CRC32 hash

    local crc32_table = { [0]=
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
        0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
        0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
        0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
        0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
        0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
        0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
        0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
        0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
        0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
        0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
        0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
        0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
        0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
        0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
        0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
        0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
        0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
        0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
        0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
        0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
        0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
        0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
        0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
        0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
        0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
        0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
        0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
        0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
        0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
        0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
        0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
    }

    function crypt.crc32(s)
        local crc = 0xFFFFFFFF
        for i = 1, #s do
            crc = (crc>>8) ~ crc32_table[(crc~byte(s, i))&0xFF]
        end
        return crc ~ 0xFFFFFFFF
    end

    -- CRC64 hash

    local crc64_table = { [0]=
        0x0000000000000000, 0xb32e4cbe03a75f6f, 0xf4843657a840a05b, 0x47aa7ae9abe7ff34,
        0x7bd0c384ff8f5e33, 0xc8fe8f3afc28015c, 0x8f54f5d357cffe68, 0x3c7ab96d5468a107,
        0xf7a18709ff1ebc66, 0x448fcbb7fcb9e309, 0x0325b15e575e1c3d, 0xb00bfde054f94352,
        0x8c71448d0091e255, 0x3f5f08330336bd3a, 0x78f572daa8d1420e, 0xcbdb3e64ab761d61,
        0x7d9ba13851336649, 0xceb5ed8652943926, 0x891f976ff973c612, 0x3a31dbd1fad4997d,
        0x064b62bcaebc387a, 0xb5652e02ad1b6715, 0xf2cf54eb06fc9821, 0x41e11855055bc74e,
        0x8a3a2631ae2dda2f, 0x39146a8fad8a8540, 0x7ebe1066066d7a74, 0xcd905cd805ca251b,
        0xf1eae5b551a2841c, 0x42c4a90b5205db73, 0x056ed3e2f9e22447, 0xb6409f5cfa457b28,
        0xfb374270a266cc92, 0x48190ecea1c193fd, 0x0fb374270a266cc9, 0xbc9d3899098133a6,
        0x80e781f45de992a1, 0x33c9cd4a5e4ecdce, 0x7463b7a3f5a932fa, 0xc74dfb1df60e6d95,
        0x0c96c5795d7870f4, 0xbfb889c75edf2f9b, 0xf812f32ef538d0af, 0x4b3cbf90f69f8fc0,
        0x774606fda2f72ec7, 0xc4684a43a15071a8, 0x83c230aa0ab78e9c, 0x30ec7c140910d1f3,
        0x86ace348f355aadb, 0x3582aff6f0f2f5b4, 0x7228d51f5b150a80, 0xc10699a158b255ef,
        0xfd7c20cc0cdaf4e8, 0x4e526c720f7dab87, 0x09f8169ba49a54b3, 0xbad65a25a73d0bdc,
        0x710d64410c4b16bd, 0xc22328ff0fec49d2, 0x85895216a40bb6e6, 0x36a71ea8a7ace989,
        0x0adda7c5f3c4488e, 0xb9f3eb7bf06317e1, 0xfe5991925b84e8d5, 0x4d77dd2c5823b7ba,
        0x64b62bcaebc387a1, 0xd7986774e864d8ce, 0x90321d9d438327fa, 0x231c512340247895,
        0x1f66e84e144cd992, 0xac48a4f017eb86fd, 0xebe2de19bc0c79c9, 0x58cc92a7bfab26a6,
        0x9317acc314dd3bc7, 0x2039e07d177a64a8, 0x67939a94bc9d9b9c, 0xd4bdd62abf3ac4f3,
        0xe8c76f47eb5265f4, 0x5be923f9e8f53a9b, 0x1c4359104312c5af, 0xaf6d15ae40b59ac0,
        0x192d8af2baf0e1e8, 0xaa03c64cb957be87, 0xeda9bca512b041b3, 0x5e87f01b11171edc,
        0x62fd4976457fbfdb, 0xd1d305c846d8e0b4, 0x96797f21ed3f1f80, 0x2557339fee9840ef,
        0xee8c0dfb45ee5d8e, 0x5da24145464902e1, 0x1a083bacedaefdd5, 0xa9267712ee09a2ba,
        0x955cce7fba6103bd, 0x267282c1b9c65cd2, 0x61d8f8281221a3e6, 0xd2f6b4961186fc89,
        0x9f8169ba49a54b33, 0x2caf25044a02145c, 0x6b055fede1e5eb68, 0xd82b1353e242b407,
        0xe451aa3eb62a1500, 0x577fe680b58d4a6f, 0x10d59c691e6ab55b, 0xa3fbd0d71dcdea34,
        0x6820eeb3b6bbf755, 0xdb0ea20db51ca83a, 0x9ca4d8e41efb570e, 0x2f8a945a1d5c0861,
        0x13f02d374934a966, 0xa0de61894a93f609, 0xe7741b60e174093d, 0x545a57dee2d35652,
        0xe21ac88218962d7a, 0x5134843c1b317215, 0x169efed5b0d68d21, 0xa5b0b26bb371d24e,
        0x99ca0b06e7197349, 0x2ae447b8e4be2c26, 0x6d4e3d514f59d312, 0xde6071ef4cfe8c7d,
        0x15bb4f8be788911c, 0xa6950335e42fce73, 0xe13f79dc4fc83147, 0x521135624c6f6e28,
        0x6e6b8c0f1807cf2f, 0xdd45c0b11ba09040, 0x9aefba58b0476f74, 0x29c1f6e6b3e0301b,
        0xc96c5795d7870f42, 0x7a421b2bd420502d, 0x3de861c27fc7af19, 0x8ec62d7c7c60f076,
        0xb2bc941128085171, 0x0192d8af2baf0e1e, 0x4638a2468048f12a, 0xf516eef883efae45,
        0x3ecdd09c2899b324, 0x8de39c222b3eec4b, 0xca49e6cb80d9137f, 0x7967aa75837e4c10,
        0x451d1318d716ed17, 0xf6335fa6d4b1b278, 0xb199254f7f564d4c, 0x02b769f17cf11223,
        0xb4f7f6ad86b4690b, 0x07d9ba1385133664, 0x4073c0fa2ef4c950, 0xf35d8c442d53963f,
        0xcf273529793b3738, 0x7c0979977a9c6857, 0x3ba3037ed17b9763, 0x888d4fc0d2dcc80c,
        0x435671a479aad56d, 0xf0783d1a7a0d8a02, 0xb7d247f3d1ea7536, 0x04fc0b4dd24d2a59,
        0x3886b22086258b5e, 0x8ba8fe9e8582d431, 0xcc0284772e652b05, 0x7f2cc8c92dc2746a,
        0x325b15e575e1c3d0, 0x8175595b76469cbf, 0xc6df23b2dda1638b, 0x75f16f0cde063ce4,
        0x498bd6618a6e9de3, 0xfaa59adf89c9c28c, 0xbd0fe036222e3db8, 0x0e21ac88218962d7,
        0xc5fa92ec8aff7fb6, 0x76d4de52895820d9, 0x317ea4bb22bfdfed, 0x8250e80521188082,
        0xbe2a516875702185, 0x0d041dd676d77eea, 0x4aae673fdd3081de, 0xf9802b81de97deb1,
        0x4fc0b4dd24d2a599, 0xfceef8632775faf6, 0xbb44828a8c9205c2, 0x086ace348f355aad,
        0x34107759db5dfbaa, 0x873e3be7d8faa4c5, 0xc094410e731d5bf1, 0x73ba0db070ba049e,
        0xb86133d4dbcc19ff, 0x0b4f7f6ad86b4690, 0x4ce50583738cb9a4, 0xffcb493d702be6cb,
        0xc3b1f050244347cc, 0x709fbcee27e418a3, 0x3735c6078c03e797, 0x841b8ab98fa4b8f8,
        0xadda7c5f3c4488e3, 0x1ef430e13fe3d78c, 0x595e4a08940428b8, 0xea7006b697a377d7,
        0xd60abfdbc3cbd6d0, 0x6524f365c06c89bf, 0x228e898c6b8b768b, 0x91a0c532682c29e4,
        0x5a7bfb56c35a3485, 0xe955b7e8c0fd6bea, 0xaeffcd016b1a94de, 0x1dd181bf68bdcbb1,
        0x21ab38d23cd56ab6, 0x9285746c3f7235d9, 0xd52f0e859495caed, 0x6601423b97329582,
        0xd041dd676d77eeaa, 0x636f91d96ed0b1c5, 0x24c5eb30c5374ef1, 0x97eba78ec690119e,
        0xab911ee392f8b099, 0x18bf525d915feff6, 0x5f1528b43ab810c2, 0xec3b640a391f4fad,
        0x27e05a6e926952cc, 0x94ce16d091ce0da3, 0xd3646c393a29f297, 0x604a2087398eadf8,
        0x5c3099ea6de60cff, 0xef1ed5546e415390, 0xa8b4afbdc5a6aca4, 0x1b9ae303c601f3cb,
        0x56ed3e2f9e224471, 0xe5c372919d851b1e, 0xa26908783662e42a, 0x114744c635c5bb45,
        0x2d3dfdab61ad1a42, 0x9e13b115620a452d, 0xd9b9cbfcc9edba19, 0x6a978742ca4ae576,
        0xa14cb926613cf817, 0x1262f598629ba778, 0x55c88f71c97c584c, 0xe6e6c3cfcadb0723,
        0xda9c7aa29eb3a624, 0x69b2361c9d14f94b, 0x2e184cf536f3067f, 0x9d36004b35545910,
        0x2b769f17cf112238, 0x9858d3a9ccb67d57, 0xdff2a94067518263, 0x6cdce5fe64f6dd0c,
        0x50a65c93309e7c0b, 0xe388102d33392364, 0xa4226ac498dedc50, 0x170c267a9b79833f,
        0xdcd7181e300f9e5e, 0x6ff954a033a8c131, 0x28532e49984f3e05, 0x9b7d62f79be8616a,
        0xa707db9acf80c06d, 0x14299724cc279f02, 0x5383edcd67c06036, 0xe0ada17364673f59
    }

    function crypt.crc64(s)
        local crc = 0xFFFFFFFFFFFFFFFF
        for i = 1, #s do
            crc = (crc>>8) ~ crc64_table[(crc~byte(s, i))&0xFF]
        end
        return crc ~ 0xFFFFFFFFFFFFFFFF
    end

    -- RC4 encryption

    function crypt.rc4(input, key, drop)
        assert(type(key) == "string", "rc4 key shall be a string")
        drop = drop or 768
        local S = {}
        for i = 0, 255 do S[i] = i end
        local j = 0
        if #key > 0 then
            for i = 0, 255 do
                j = (j + S[i] + byte(key, i%#key+1)) % 256
                S[i], S[j] = S[j], S[i]
            end
        end
        local i = 0
        j = 0
        for _ = 1, drop do
            i = (i + 1) % 256
            j = (j + S[i]) % 256
            S[i], S[j] = S[j], S[i]
        end
        local output = {}
        for k = 1, #input do
            i = (i + 1) % 256
            j = (j + S[i]) % 256
            S[i], S[j] = S[j], S[i]
            output[k] = char(byte(input, k) ~ S[(S[i] + S[j]) % 256])
        end
        return concat(output)
    end

    crypt.unrc4 = crypt.rc4

    if pandoc then
        crypt.sha1 = pandoc.utils.sha1
    else
        -------------------------------------------------
        ---      *** SHA-1 algorithm for Lua ***      ---
        -------------------------------------------------
        --- Author:  Martin Huesser                   ---
        --- Date:    2008-06-16                       ---
        --- License: You may use this code in your    ---
        ---          projects as long as this header  ---
        ---          stays intact.                    ---
        -------------------------------------------------
        -- Adapted for LuaX                           --
        -------------------------------------------------

        local strlen  = string.len
        local strchar = string.char
        local strbyte = string.byte
        local strsub  = string.sub
        local lshift  = function(a,n) return (a << n) & 0xFFFFFFFF end
        local rshift  = function(a,n) return (a&0xFFFFFFFF) >> n end
        local lrot    = function(a,n) return lshift(a, n) | rshift(a, 32-n) end
        local pack = string.pack

        local h0, h1, h2, h3, h4

        -------------------------------------------------

        local function preprocess(str)
            local bitlen, i
            local str2 = ""
            bitlen = strlen(str) * 8
            str = str .. strchar(128)
            i = 56 - (strlen(str)&63)
            if i < 0 then
                i = i + 64
            end
            for _ = 1, i do
                str = str .. strchar(0)
            end
            for _ = 1, 8 do
                str2 = strchar(bitlen & 0xFF) .. str2
                bitlen = bitlen >> 8
            end
            return str .. str2
        end

        -------------------------------------------------

        local function main_loop(str)
            local a, b, c, d, e, f, k, t
            local w = {}
            while (str ~= "") do
                for i = 0, 15 do
                    w[i] = 0
                    for j = 1, 4 do
                        w[i] = w[i] * 256 + strbyte(str, i * 4 + j)
                    end
                end
                for i = 16, 79 do
                    w[i] = lrot(w[i - 3] ~ w[i - 8] ~ w[i - 14] ~ w[i - 16], 1)
                end
                a = h0
                b = h1
                c = h2
                d = h3
                e = h4
                for i = 0, 79 do
                    if i < 20 then
                        f = (b&c) ~ ((~b)&d)
                        k = 1518500249
                    elseif i < 40 then
                        f = b ~ c ~ d
                        k = 1859775393
                    elseif i < 60 then
                        f = (b&c) | (b&d) | (c&d)
                        k = 2400959708
                    else
                        f = b ~ c ~ d
                        k = 3395469782
                    end
                    t = lrot(a, 5) + f + e + k + w[i]
                    e = d
                    d = c
                    c = lrot(b, 30)
                    b = a
                    a = t
                end
                h0 = (h0 + a) & 0xFFFFFFFF
                h1 = (h1 + b) & 0xFFFFFFFF
                h2 = (h2 + c) & 0xFFFFFFFF
                h3 = (h3 + d) & 0xFFFFFFFF
                h4 = (h4 + e) & 0xFFFFFFFF
                str = strsub(str, 65)
            end
        end

        -------------------------------------------------

        function crypt.sha1(s)
            s = preprocess(s)
            h0  = 1732584193
            h1  = 4023233417
            h2  = 2562383102
            h3  = 0271733878
            h4  = 3285377520
            main_loop(s)
            return pack(">I4I4I4I4I4", h0, h1, h2, h3, h4):hex()
        end

    end

    function crypt.hash(s)
        local hash = 1844674407370955155*10+7
        hash = hash * 6364136223846793005 + 1
        for i = 1, #s do
            local c = byte(s, i)
            hash = hash * 6364136223846793005 + ((c << 1) | 1)
        end
        hash = hash * 6364136223846793005 + 1
        return ("<I8"):pack(hash):hex()
    end

end

--[[------------------------------------------------------------------------@@@
## Random array access

@@@]]

--[[@@@
```lua
prng:choose(xs)
crypt.choose(xs)    -- using the global PRNG
```
returns a random item from `xs`
@@@]]

local prng_mt = getmetatable(crypt.prng())

function prng_mt.__index.choose(prng, xs)
    return xs[prng:int(1, #xs)]
end

function crypt.choose(xs)
    return xs[crypt.int(1, #xs)]
end

--[[@@@
```lua
prng:shuffle(xs)
crypt.shuffle(xs)    -- using the global PRNG
```
returns a shuffled copy of `xs`
@@@]]

function prng_mt.__index.shuffle(prng, xs)
    local ys = F.clone(xs)
    for i = 1, #ys-1 do
        local j = prng:int(i, #ys)
        ys[i], ys[j] = ys[j], ys[i]
    end
    return ys
end

function crypt.shuffle(xs)
    local ys = F.clone(xs)
    for i = 1, #ys-1 do
        local j = crypt.int(i, #ys)
        ys[i], ys[j] = ys[j], ys[i]
    end
    return ys
end

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `crypt` package are added to the string module:

@@@]]

--[[@@@
```lua
s:hex()             == crypt.hex(s)
s:unhex()           == crypt.unhex(s)
s:base64()          == crypt.base64(s)
s:unbase64()        == crypt.unbase64(s)
s:base64url()       == crypt.base64url(s)
s:unbase64url()     == crypt.unbase64url(s)
s:crc32()           == crypt.crc32(s)
s:crc64()           == crypt.crc64(s)
s:rc4(key, drop)    == crypt.rc4(s, key, drop)
s:unrc4(key, drop)  == crypt.unrc4(s, key, drop)
s:sha1()            == crypt.sha1(s)
s:hash()            == crypt.hash(s)
```
@@@]]

function string.hex(s)          return crypt.hex(s) end
function string.unhex(s)        return crypt.unhex(s) end
function string.base64(s)       return crypt.base64(s) end
function string.unbase64(s)     return crypt.unbase64(s) end
function string.base64url(s)    return crypt.base64url(s) end
function string.unbase64url(s)  return crypt.unbase64url(s) end
function string.rc4(s, k, d)    return crypt.rc4(s, k, d) end
function string.unrc4(s, k, d)  return crypt.unrc4(s, k, d) end
function string.sha1(s)         return crypt.sha1(s) end
function string.hash(s)         return crypt.hash(s) end
function string.crc32(s)        return crypt.crc32(s) end
function string.crc64(s)        return crypt.crc64(s) end

return crypt
]=]),
["fs"] = lib("libluax/fs/fs.lua", [=[--[[
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
## Additional functions (Lua)
@@@]]

-- Load fs.lua to add new methods to strings
--@LOAD=_

local _, fs = pcall(require, "_fs")
fs = _ and fs

local F = require "F"
local sys = require "sys"

-- Pure Lua / Pandoc Lua implementation
if not fs then
    fs = {}

    local sh = require "sh"

    if pandoc and pandoc.path then
        fs.sep = pandoc.path.separator
        fs.path_sep = pandoc.path.search_path_separator
    else
        fs.sep = package.config:match("^([^\n]-)\n")
        fs.path_sep = fs.sep == '\\' and ";" or ":"
    end

    if pandoc and pandoc.system then
        fs.getcwd = pandoc.system.get_working_directory
    else
        function fs.getcwd()
            return sh.read "pwd" : trim() ---@diagnostic disable-line:undefined-field
        end
    end

    if pandoc and pandoc.system then
        fs.dir = F.compose{F, pandoc.system.list_directory}
    else
        function fs.dir(path)
            return sh.read("ls", path) : lines() : sort() ---@diagnostic disable-line:undefined-field
        end
    end

    function fs.remove(name)
        return os.remove(name)
    end

    function fs.rename(old_name, new_name)
        return os.rename(old_name, new_name)
    end

    function fs.copy(source_name, target_name)
        local from, err_from = io.open(source_name, "rb")
        if not from then return from, err_from end
        local to, err_to = io.open(target_name, "wb")
        if not to then from:close(); return to, err_to end
        while true do
            local block = from:read(64*1024)
            if not block then break end
            local ok, err = to:write(block)
            if not ok then
                from:close()
                to:close()
                return ok, err
            end
        end
        from:close()
        to:close()
    end

    if pandoc and pandoc.system then
        fs.mkdir = pandoc.system.make_directory
    else
        function fs.mkdir(path)
            return sh.run("mkdir", path)
        end
    end

    local S_IRUSR = 1 << 8
    local S_IWUSR = 1 << 7
    local S_IXUSR = 1 << 6
    local S_IRGRP = 1 << 5
    local S_IWGRP = 1 << 4
    local S_IXGRP = 1 << 3
    local S_IROTH = 1 << 2
    local S_IWOTH = 1 << 1
    local S_IXOTH = 1 << 0

    fs.uR = S_IRUSR
    fs.uW = S_IWUSR
    fs.uX = S_IXUSR
    fs.aR = S_IRUSR|S_IRGRP|S_IROTH
    fs.aW = S_IWUSR|S_IWGRP|S_IWOTH
    fs.aX = S_IXUSR|S_IXGRP|S_IXOTH
    fs.gR = S_IRGRP
    fs.gW = S_IWGRP
    fs.gX = S_IXGRP
    fs.oR = S_IROTH
    fs.oW = S_IWOTH
    fs.oX = S_IXOTH

    local stat = sys.os=="macos" and "gstat" or "stat"

    function fs.stat(name)
        local st = sh.read("LC_ALL=C", stat, "-L", "-c '%s;%Y;%X;%W;%F;%f'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        local size, mtime, atime, ctime, type, mode = st:trim():split ";":unpack()
        mode = tonumber(mode, 16)
        if type == "regular file" then type = "file" end
        return F{
            name = name,
            size = tonumber(size),
            mtime = tonumber(mtime),
            atime = tonumber(atime),
            ctime = tonumber(ctime),
            type = type,
            mode = mode,
            uR = (mode & S_IRUSR) ~= 0,
            uW = (mode & S_IWUSR) ~= 0,
            uX = (mode & S_IXUSR) ~= 0,
            gR = (mode & S_IRGRP) ~= 0,
            gW = (mode & S_IWGRP) ~= 0,
            gX = (mode & S_IXGRP) ~= 0,
            oR = (mode & S_IROTH) ~= 0,
            oW = (mode & S_IWOTH) ~= 0,
            oX = (mode & S_IXOTH) ~= 0,
            aR = (mode & (S_IRUSR|S_IRGRP|S_IROTH)) ~= 0,
            aW = (mode & (S_IWUSR|S_IWGRP|S_IWOTH)) ~= 0,
            aX = (mode & (S_IXUSR|S_IXGRP|S_IXOTH)) ~= 0,
        }
    end

    function fs.inode(name)
        local st = sh.read("LC_ALL=C", stat, "-L", "-c '%d;%i'", name, "2>/dev/null")
        if not st then return nil, "cannot stat "..name end
        local dev, ino = st:trim():split ";":unpack()
        return F{
            ino = tonumber(ino),
            dev = tonumber(dev),
        }
    end

    function fs.chmod(name, ...)
        local mode = {...}
        if type(mode[1]) == "string" then
            return sh.run("chmod", "--reference="..mode[1], name, "2>/dev/null")
        else
            return sh.run("chmod", ("%o"):format(F(mode):fold(F.op.bor, 0)), name)
        end
    end

    function fs.touch(name, opt)
        if opt == nil then
            return sh.run("touch", name, "2>/dev/null")
        elseif type(opt) == "number" then
            return sh.run("touch", "-d", '"'..os.date("%c", opt)..'"', name, "2>/dev/null")
        elseif type(opt) == "string" then
            return sh.run("touch", "--reference="..opt, name, "2>/dev/null")
        else
            error "bad argument #2 to touch (none, nil, number or string expected)"
        end
    end

    if pandoc and pandoc.path then
        fs.basename = pandoc.path.filename
    else
        function fs.basename(path)
            return (path:gsub(".*[/\\]", ""))
        end
    end

    if pandoc and pandoc.path then
        fs.dirname = pandoc.path.directory
    else
        function fs.dirname(path)
            local dir, n = path:gsub("[/\\][^/\\]*$", "")
            return n > 0 and dir or "."
        end
    end

    if pandoc and pandoc.path then
        function fs.splitext(path)
            if fs.basename(path):match "^%." then
                return path, ""
            end
            return pandoc.path.split_extension(path)
        end
    else
        function fs.splitext(path)
            local name, ext = path:match("^(.*)(%.[^/\\]-)$")
            if name and ext and #name > 0 and not name:has_suffix(fs.sep) then
                return name, ext
            end
            return path, ""
        end
    end

    function fs.ext(path)
        local _, ext = fs.splitext(path)
        return ext
    end

    if pandoc and pandoc.path then
        fs.realpath = pandoc.path.normalize
    else
        function fs.realpath(path)
            return sh.read("realpath", path) : trim() ---@diagnostic disable-line:undefined-field
        end
    end

    function fs.readlink(path)
        return sh.read("readlink", path) : trim() ---@diagnostic disable-line:undefined-field
    end

    function fs.absname(path)
        if path:match "^[/\\]" or path:match "^.:" then return path end
        return fs.getcwd()..fs.sep..path
    end

    if pandoc and pandoc.system then
        function fs.mkdirs(path)
            return pandoc.system.make_directory(path, true)
        end
    else
        function fs.mkdirs(path)
            return sh.run("mkdir", "-p", path)
        end
    end

end

--[[@@@
```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).
If a component is absolute, the previous components are removed.
@@@]]

if pandoc and pandoc.path then
    function fs.join(...)
        return pandoc.path.join(F.flatten{...})
    end
else
    function fs.join(...)
        local function add_path(ps, p)
            if p:match("^"..fs.sep) then return F{p} end
            ps[#ps+1] = p
            return ps
        end
        return F{...}
            :flatten()
            :fold(add_path, F{})
            :str(fs.sep)
    end
end

--[[@@@
```lua
fs.splitpath(path)
```
return a list of path components.
@@@]]

function fs.splitpath(path)
    if path == "" then return F{} end
    local components = path:split "[/\\]+"
    if components[1] == "" then components[1] = fs.sep end
    return components
end

--[[@@@
```lua
fs.is_file(name)
```
returns `true` if `name` is a file.
@@@]]

function fs.is_file(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "file"
end

--[[@@@
```lua
fs.is_dir(name)
```
returns `true` if `name` is a directory.
@@@]]

function fs.is_dir(name)
    local stat = fs.stat(name)
    return stat ~= nil and stat.type == "directory"
end

--[[@@@
```lua
fs.findpath(name)
```
returns the full path of `name` if `name` is found in `$PATH` or `nil`.
@@@]]

function fs.findpath(name)
    local function exists_in(path) return fs.is_file(fs.join(path, name)) end
    local path = os.getenv("PATH")
        :split(fs.path_sep)
        :find(exists_in)
    if path then return fs.join(path, name) end
    return nil, name..": not found in $PATH"
end

--[[@@@
```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent directories.
@@@]]

if not fs.mkdirs then
    function fs.mkdirs(path)
        if path == "" or fs.stat(path) then return end
        fs.mkdirs(fs.dirname(path))
        fs.mkdir(path)
    end
end

--[[@@@
```lua
fs.mv(old_name, new_name)
```
alias for `fs.rename(old_name, new_name)`.
@@@]]

fs.mv = fs.rename

--[[@@@
```lua
fs.rm(name)
```
alias for `fs.remove(name)`.
@@@]]

fs.rm = fs.remove

--[[@@@
```lua
fs.rmdir(path, [params])
```
deletes the directory `path` and its content recursively.
@@@]]

if pandoc and pandoc.system then
    function fs.rmdir(path)
        pandoc.system.remove_directory(path, true)
        return true
    end
else
    function fs.rmdir(path)
        fs.walk(path, {reverse=true}):foreach(fs.rm)
        return fs.rm(path)
    end
end

--[[@@@
```lua
fs.walk([path], [{reverse=true|false, links=true|false, cross=true|false}])
```
returns a list listing directory and
file names in `path` and its subdirectories (the default path is the current
directory).

Options:

- `stat`: returns the list of stat results instead of just filenames
- `reverse`: the list is built in a reverse order
  (suitable for recursive directory removal)
- `cross`: walk across several devices
- `func`: function applied to the current file or directory.
  `func` takes two parameters (path of the file or directory and the stat object returned by `fs.stat`)
  and returns a boolean (to continue or not walking recursively through the subdirectories)
  and the value to add to the list.
@@@]]

function fs.walk(path, options)
    options = options or {}
    local return_stat = options.stat
    local reverse = options.reverse
    local cross_device = options.cross
    local func = options.func
              or return_stat and function(_, stat) return true, stat end
              or function(name, _) return true, name end
    local dirs = {path or "."}
    local acc_files = {}
    local acc_dirs = {}
    local seen = {}
    local dev0 = nil
    local function already_seen(name)
        local inode = fs.inode(name)
        if not inode then return true end
        dev0 = dev0 or inode.dev
        if dev0 ~= inode.dev and not cross_device then
            return true
        end
        if not seen[inode.dev] then
            seen[inode.dev] = {[inode]=true}
            return false
        end
        if not seen[inode.dev][inode.ino] then
            seen[inode.dev][inode.ino] = true
            return false
        end
        return true
    end
    while #dirs > 0 do
        local dir = table.remove(dirs)
        if not already_seen(dir) then
            local names = fs.dir(dir)
            if names then
                table.sort(names)
                for i = 1, #names do
                    local name = dir..fs.sep..names[i]
                    local stat = fs.stat(name)
                    if stat then
                        if stat.type == "directory" then
                            local continue, obj = func(name, stat)
                            if continue then
                                dirs[#dirs+1] = name
                            end
                            if obj then
                                if reverse then table.insert(acc_dirs, 1, obj)
                                else acc_dirs[#acc_dirs+1] = obj
                                end
                            end
                        else
                            local _, obj = func(name, stat)
                            if obj then
                                acc_files[#acc_files+1] = obj
                            end
                        end
                    end
                end
            end
        end
    end
    return F.concat(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end

--[[@@@
```lua
fs.ls(path)
```
returns a list of file names.
`path` can be a directory name or a simple file pattern.
Patterns can contain jokers (`*` to match any character and `**` to search files recursively).

Examples:

- `fs.ls "src"`: list all files/directories in `src`
- `fs.ls "src/*.c"`: list all C files in `src`
- `fs.ls "src/**.c"`: list all C files in `src` and its subdirectories
@@@]]

function fs.ls(dir)
    dir = dir or "."
    local base = dir:basename()
    local path = dir:dirname()
    local recursive = base:match"%*%*"
    local pattern = base:match"%*" and base : gsub("([.+-])", "%%%0")
                                            : gsub("%*%*", "*")
                                            : gsub("%*", ".*")

    local useless_path_prefix = "^%."..fs.sep
    local function clean_path(fullpath)
        return fullpath:gsub(useless_path_prefix, "")
    end

    if recursive then
        return fs.walk(path)
            : filter(function(name) return name:basename():match("^"..pattern.."$") end)
            : map(clean_path)
            : sort()
    end
    if pattern then
        return fs.dir(path)
            : filter(function(name) return name:match("^"..pattern.."$") end)
            : map(F.partial(fs.join, path))
            : map(clean_path)
            : sort()
    end
    return fs.dir(dir)
        : map(F.partial(fs.join, dir))
        : map(clean_path)
        : sort()
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

if pandoc and pandoc.system then
    function fs.with_tmpfile(f)
        return pandoc.system.with_temporary_directory("luax-XXXXXX", function(tmpdir)
            return f(fs.join(tmpdir, "tmpfile"))
        end)
    end
elseif sys.os == "windows" then
    function fs.with_tmpfile(f)
        local tmp = os.getenv "TMP" / os.tmpname():basename()
        local ret = {f(tmp)}
        fs.rm(tmp)
        return table.unpack(ret)
    end
else
    function fs.with_tmpfile(f)
        local tmp = os.tmpname()
        local ret = {f(tmp)}
        fs.rm(tmp)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.
@@@]]

if pandoc and pandoc.system then
    function fs.with_tmpdir(f)
        return pandoc.system.with_temporary_directory("luax", f)
    end
elseif sys.os == "windows" then
    function fs.with_tmpdir(f)
        local tmp = os.getenv "TMP" / os.tmpname():basename()
        fs.rm(tmp)
        fs.mkdir(tmp)
        local ret = {f(tmp)}
        fs.rmdir(tmp)
        return table.unpack(ret)
    end
else
    function fs.with_tmpdir(f)
        local tmp = os.tmpname()
        fs.rm(tmp)
        fs.mkdir(tmp)
        local ret = {f(tmp)}
        fs.rmdir(tmp)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.with_dir(path, f)
```
changes the current working directory to `path` and calls `f()`.
@@@]]

if pandoc and pandoc.system then
    fs.with_dir = pandoc.system.with_working_directory
elseif fs.chdir then
    function fs.with_dir(path, f)
        local old = fs.getcwd()
        fs.chdir(path)
        local ret = {f()}
        fs.chdir(old)
        return table.unpack(ret)
    end
end

--[[@@@
```lua
fs.with_env(env, f)
```
changes the environnement to `env` and calls `f()`.
@@@]]

if pandoc and pandoc.system then
    fs.with_env = pandoc.system.with_environment
end

--[[@@@
```lua
fs.read(filename)
```
returns the content of the text file `filename`.
@@@]]

function fs.read(name)
    local f, oerr = io.open(name, "r")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write(filename, ...)
```
write `...` to the text file `filename`.
@@@]]

function fs.write(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "w")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
end

--[[@@@
```lua
fs.read_bin(filename)
```
returns the content of the binary file `filename`.
@@@]]

function fs.read_bin(name)
    local f, oerr = io.open(name, "rb")
    if not f then return f, oerr end
    local content, rerr = f:read("a")
    f:close()
    return content, rerr
end

--[[@@@
```lua
fs.write_bin(filename, ...)
```
write `...` to the binary file `filename`.
@@@]]

function fs.write_bin(name, ...)
    local content = F{...}:flatten():str()
    local f, oerr = io.open(name, "wb")
    if not f then return f, oerr end
    local ok, werr = f:write(content)
    f:close()
    return ok, werr
end

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `fs` package are added to the string module:

@@@]]

--[[@@@
```lua
path:dir()              == fs.dir(path)
path:stat()             == fs.stat(path)
path:inode()            == fs.inode(path)
path:basename()         == fs.basename(path)
path:dirname()          == fs.dirname(path)
path:splitext()         == fs.splitext(path)
path:ext()              == fs.ext(path)
path:realpath()         == fs.realpath(path)
path:readlink()         == fs.readlink(path)
path:absname()          == fs.absname(path)
path1 / path2           == fs.join(path1, path2)
path:is_file()          == fs.is_file(path)
path:is_dir()           == fs.is_dir(path)
path:findpath()         == fs.findpath(path)
path:walk(...)          == fs.walk(path, ...)
```
@@@]]

function string.dir(path)                   return fs.dir(path) end
function string.stat(path)                  return fs.stat(path) end
function string.inode(path)                 return fs.inode(path) end
function string.basename(path)              return fs.basename(path) end
function string.dirname(path)               return fs.dirname(path) end
function string.splitext(path)              return fs.splitext(path) end
function string.ext(path)                   return fs.ext(path) end
function string.splitpath(path)             return fs.splitpath(path) end
function string.realpath(path)              return fs.realpath(path) end
function string.readlink(path)              return fs.readlink(path) end
function string.absname(path)               return fs.absname(path) end

getmetatable("").__div = function(path1, path2)
    return fs.join(path1, path2)
end

function string.is_file(path)               return fs.is_file(path) end
function string.is_dir(path)                return fs.is_dir(path) end
function string.findpath(path)              return fs.findpath(path) end
function string.walk(path, ...)             return fs.walk(path, ...) end

return fs
]=]),
["imath"] = lib("libluax/imath/imath.lua", [=[--[[
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

--@LIB
local _, imath = pcall(require, "_imath")
imath = _ and imath

if not imath then

    imath = {}
    local mt = {__index={}}

    ---@diagnostic disable:unused-vararg
    local function ni(f) return function(...) error(f.." not implemented") end end

    local floor = math.floor
    local ceil = math.ceil
    local sqrt = math.sqrt
    local log = math.log
    local max = math.max

    local RADIX = 10000000
    local RADIX_LEN = floor(log(RADIX, 10))

    assert(RADIX^2 < 2^53, "RADIX^2 shall be storable on a Lua number")

    local int_add, int_sub, int_mul, int_divmod, int_abs

    local function int_trim(a)
        for i = #a, 1, -1 do
            if a[i] and a[i] ~= 0 then break end
            a[i] = nil
        end
        if #a == 0 then a.sign = 1 end
    end

    local function int(n, base)
        n = n or 0
        if type(n) == "table" then return n end
        if type(n) == "number" then n = ("%.0f"):format(floor(n)) end
        assert(type(n) == "string")
        n = n:gsub("[ _]", "")
        local sign = 1
        local d = 1 -- current digit index
        if n:sub(d, d) == "+" then d = d+1
        elseif n:sub(d, d) == "-" then sign = -1; d = d+1
        end
        if n:sub(d, d+1) == "0x" then d = d+2; base = 16
        elseif n:sub(d, d+1) == "0o" then d = d+2; base = 8
        elseif n:sub(d, d+1) == "0b" then d = d+2; base = 2
        else base = base or 10
        end
        local self = {sign=1}
        if base == 10 then
            for i = #n, d, -RADIX_LEN do
                local digit = n:sub(max(d, i-RADIX_LEN+1), i)
                self[#self+1] = tonumber(digit)
            end
        else
            local bn_base = {sign=1, base}
            local bn_shift = {sign=1, 1}
            local bn_digit = {sign=1, 0}
            for i = #n, d, -1 do
                bn_digit[1] = tonumber(n:sub(i, i), base)
                self = int_add(self, int_mul(bn_digit, bn_shift))
                bn_shift = int_mul(bn_shift, bn_base)
            end
        end
        self.sign = sign
        int_trim(self)
        return setmetatable(self, mt)
    end

    local int_zero = int(0)
    local int_one = int(1)
    local int_two = int(2)

    local function int_copy(n)
        local c = {sign=n.sign}
        for i = 1, #n do
            c[i] = n[i]
        end
        return setmetatable(c, mt)
    end


    local function int_tonumber(n)
        local s = n.sign < 0 and "-0" or "0"
        local fmt = ("%%0%dd"):format(RADIX_LEN)
        for i = #n, 1, -1 do
            s = s..fmt:format(n[i])
        end
        return tonumber(s..".")
    end

    local function int_tostring(n, base)
        base = base or 10
        local s = ""
        local sign = n.sign
        if base == 10 then
            local fmt = ("%%0%dd"):format(RADIX_LEN)
            for i = 1, #n do
                s = fmt:format(n[i]) .. s
            end
            s = s:gsub("^[_0]+", "")
            if s == "" then s = "0" end
        else
            local bn_base = int(base)
            local absn = int_abs(n)
            while #absn > 0 do
                local d
                absn, d = int_divmod(absn, bn_base)
                d = int_tonumber(d)
                s = ("0123456789ABCDEF"):sub(d+1, d+1) .. s
            end
            s = s:gsub("^0+", "")
            if s == "" then s = "0" end
        end
        if sign < 0 then s = "-" .. s end
        return s
    end

    local function int_iszero(a)
        return #a == 0
    end

    local function int_isone(a)
        return #a == 1 and a[1] == 1 and a.sign == 1
    end

    local function int_cmp(a, b)
        if #a == 0 and #b == 0 then return 0 end -- 0 == -0
        if a.sign > b.sign then return 1 end
        if a.sign < b.sign then return -1 end
        if #a > #b then return a.sign end
        if #a < #b then return -a.sign end
        for i = #a, 1, -1 do
            if a[i] > b[i] then return a.sign end
            if a[i] < b[i] then return -a.sign end
        end
        return 0
    end

    local function int_abscmp(a, b)
        if #a > #b then return 1 end
        if #a < #b then return -1 end
        for i = #a, 1, -1 do
            if a[i] > b[i] then return 1 end
            if a[i] < b[i] then return -1 end
        end
        return 0
    end

    local function int_neg(a)
        local b = int_copy(a)
        b.sign = -a.sign
        return b
    end

    int_add = function(a, b)
        if a.sign == b.sign then            -- a+b = a+b, (-a)+(-b) = -(a+b)
            local c = int()
            c.sign = a.sign
            local carry = 0
            for i = 1, max(#a, #b) + 1 do -- +1 for the last carry
                c[i] = carry + (a[i] or 0) + (b[i] or 0)
                if c[i] >= RADIX then
                    c[i] = c[i] - RADIX
                    carry = 1
                else
                    carry = 0
                end
            end
            int_trim(c)
            return c
        else
            return int_sub(a, int_neg(b))
        end
    end

    int_sub = function(a, b)
        if a.sign == b.sign then
            local A, B
            local cmp = int_abscmp(a, b)
            if cmp >= 0 then A = a; B = b; else A = b; B = a; end
            local c = int()
            local carry = 0
            for i = 1, #A do
                c[i] = A[i] - (B[i] or 0) - carry
                if c[i] < 0 then
                    c[i] = c[i] + RADIX
                    carry = 1
                else
                    carry = 0
                end
            end
            assert(carry == 0) -- should be true if |A| >= |B|
            c.sign = (cmp >= 0) and a.sign or -a.sign
            int_trim(c)
            return c
        else
            local c = int_add(a, int_neg(b))
            c.sign = a.sign
            return c
        end
    end

    int_mul = function(a, b)
        local c = int()
        for i = 1, #a do
            local carry = 0
            for j = 1, #b do
                carry = (c[i+j-1] or 0) + a[i]*b[j] + carry
                c[i+j-1] = carry % RADIX
                carry = math.floor(carry / RADIX)
            end
            if carry ~= 0 then
                c[i + #b] = carry
            end
        end
        int_trim(c)
        c.sign = a.sign * b.sign
        return c
    end

    local function int_absdiv2(a)
        local c = int()
        local carry = 0
        for i = 1, #a do
            c[i] = 0
        end
        for i = #a, 1, -1 do
            c[i] = floor(carry + a[i] / 2)
            if a[i] % 2 ~= 0 then
                carry = RADIX // 2
            else
                carry = 0
            end
        end
        c.sign = a.sign
        int_trim(c)
        return c, (a[1] or 0) % 2
    end

    int_divmod = function(a, b)
        -- euclidian division using dichotomie
        -- searching q and r such that a = q*b + r and |r| < |b|
        assert(not int_iszero(b), "Division by zero")
        if int_iszero(a) then return int_zero, int_zero end
        if int_isone(b) then return a, int_zero end
        if b.sign < 0 then a = int_neg(a); b = int_neg(b) end
        local qmin = int_neg(a)
        local qmax = a
        if int_cmp(qmax, qmin) < 0 then qmin, qmax = qmax, qmin end
        local rmin = int_sub(a, int_mul(qmin, b))
        if rmin.sign > 0 and int_cmp(rmin, b) < 0 then return qmin, rmin end
        local rmax = int_sub(a, int_mul(qmax, b))
        if rmax.sign > 0 and int_cmp(rmax, b) < 0 then return qmax, rmax end
        assert(rmin.sign ~= rmax.sign)
        local q = int_absdiv2(int_add(qmin, qmax))
        local r = int_sub(a, int_mul(q, b))
        while r.sign < 0 or int_cmp(r, b) >= 0 do
            if r.sign == rmin.sign then
                qmin, qmax = q, qmax
                rmin, rmax = r, rmax
            else
                qmin, qmax = qmin, q
                rmin, rmax = rmin, r
            end
            q = int_absdiv2(int_add(qmin, qmax))
            r = int_sub(a, int_mul(q, b))
        end
        return q, r
    end

    local function int_sqrt(a)
        assert(a.sign >= 0, "Square root of a negative number")
        if int_iszero(a) then return int_zero end
        local b = int()
        local c = int()
        for i = #a//2+1, #a do b[#b+1] = ceil(sqrt(a[i])) end
        while b ~= c do
            c = b
            local q, _ = int_divmod(a, b)
            b = int_absdiv2(int_add(b, q))
            --if b^2 <= a and (b+1)^2 > a then break end
        end
        assert(b^2 <= a and (b+1)^2 > a)
        return b
    end

    local function int_pow(a, b)
        assert(b.sign > 0)
        if #b == 0 then return int_one end
        if #b == 1 and b[1] == 1 then return a end
        if #b == 1 and b[1] == 2 then return int_mul(a, a) end
        local c
        local q, r = int_absdiv2(b)
        c = int_pow(a, q)
        c = int_mul(c, c)
        if r == 1 then c = int_mul(c, a) end
        return c
    end

    int_abs = function(a)
        local b = int_copy(a)
        b.sign = 1
        return b
    end

    local function int_gcd(a, b)
        a = int_abs(a)
        b = int_abs(b)
        while true do
            local _
            local order = int_cmp(a, b)
            if order == 0 then return a end
            if order > 0 then
                _, a = int_divmod(a, b)
                if int_iszero(a) then return b end
            else
                _, b = int_divmod(b, a)
                if int_iszero(b) then return a end
            end
        end
    end

    local function int_lcm(a, b)
        a = int_abs(a)
        b = int_abs(b)
        return int_mul((int_divmod(a, int_gcd(a, b))), b)
    end

    local function int_iseven(a)
        return #a == 0 or a[1]%2 == 0
    end

    local function int_isodd(a)
        return #a > 0 and a[1]%2 == 1
    end

    local int_shift_left, int_shift_right

    int_shift_left = function(a, b)
        if int_iszero(b) then return a end
        if b.sign > 0 then
            return int_mul(a, int_two^b)
        else
            return int_shift_right(a, int_neg(b))
        end
    end

    int_shift_right = function(a, b)
        if int_iszero(b) then return a end
        if b.sign < 0 then
            return int_shift_left(a, int_neg(b))
        else
            return (int_divmod(a, int_two^b))
        end
    end

    mt.__add = function(a, b) return int_add(int(a), int(b)) end
    mt.__div = function(a, b) local q, _ = int_divmod(int(a), int(b)); return q end
    mt.__eq = function(a, b) return int_cmp(int(a), int(b)) == 0 end
    mt.__idiv = mt.__div
    mt.__le = function(a, b) return int_cmp(int(a), int(b)) <= 0 end
    mt.__lt = function(a, b) return int_cmp(int(a), int(b)) < 0 end
    mt.__mod = function(a, b) local _, r = int_divmod(int(a), int(b)); return r end
    mt.__mul = function(a, b) return int_mul(int(a), int(b)) end
    mt.__pow = function(a, b) return int_pow(int(a), int(b)) end
    mt.__shl = function(a, b) return int_shift_left(int(a), int(b)) end
    mt.__shr = function(a, b) return int_shift_right(int(a), int(b)) end
    mt.__sub = function(a, b) return int_sub(int(a), int(b)) end
    mt.__tostring = function(a, base) return int_tostring(a, base) end
    mt.__unm = function(a) return int_neg(a) end

    mt.__index.add = mt.__add
    mt.__index.bits = ni "bits"
    mt.__index.compare = function(a, b) return int_cmp(int(a), int(b)) end
    mt.__index.div = mt.__div
    mt.__index.egcd = ni "egcd"
    mt.__index.gcd = function(a, b) return int_gcd(int(a), int(b)) end
    mt.__index.invmod = ni "invmod"
    mt.__index.iseven = int_iseven
    mt.__index.isodd = int_isodd
    mt.__index.iszero = int_iszero
    mt.__index.isone = int_isone
    mt.__index.lcm = function(a, b) return int_lcm(int(a), int(b)) end
    mt.__index.mod = mt.__mod
    mt.__index.mul = mt.__mul
    mt.__index.neg = mt.__unm
    mt.__index.pow = mt.__pow
    mt.__index.powmod = ni "powmod"
    mt.__index.quotrem = function(a, b) return int_divmod(int(a), int(b)) end
    mt.__index.root = ni "root"
    mt.__index.shift = mt.__index.shl
    mt.__index.sqr = function(a) return int_mul(a, a) end
    mt.__index.sqrt = int_sqrt
    mt.__index.sub = mt.__sub
    mt.__index.abs = function(a) return int_abs(a) end
    mt.__index.tonumber = int_tonumber
    mt.__index.tostring = mt.__tostring
    mt.__index.totext = ni "totext"

    imath.abs = function(a) return int(a):abs() end
    imath.add = function(a, b) return int(a) + int(b) end
    imath.bits = function(a) return int(a):bits() end
    imath.compare = function(a, b) return int(a):compare(int(b)) end
    imath.div = function(a, b) return int(a) / int(b) end
    imath.egcd = function(a, b) return int(a):egcd(int(b)) end
    imath.gcd = function(a, b) return int(a):gcd(int(b)) end
    imath.invmod = function(a, b) return int(a):invmod(int(b)) end
    imath.iseven = function(a) return int(a):iseven() end
    imath.isodd = function(a) return int(a):isodd() end
    imath.iszero = function(a) return int(a):iszero() end
    imath.isone = function(a) return int(a):isone() end
    imath.lcm = function(a, b) return int(a):lcm(int(b)) end
    imath.mod = function(a, b) return int(a) % int(b) end
    imath.mul = function(a, b) return int(a) * int(b) end
    imath.neg = function(a) return -int(a) end
    imath.new = int
    imath.pow = function(a, b) return int(a) ^ b end
    imath.powmod = function(a, b) return int(a):powmod(int(b)) end
    imath.quotrem = function(a, b) return int(a):quotrem(int(b)) end
    imath.root = function(a) return int(a):root() end
    imath.shift = function(a, b) return int(a) << b end
    imath.sqr = function(a) return int(a):sqr() end
    imath.sqrt = function(a) return int(a):sqrt() end
    imath.sub = function(a, b) return int(a) - int(b) end
    imath.text = ni "text"
    imath.tonumber = function(a) return int(a):tonumber() end
    imath.tostring = function(a) return int(a):tostring() end
    imath.totext = function(a) return int(a):totext() end

end

return imath
]=]),
["import"] = lib("libluax/import/import.lua", [=[--[[
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

--@LIB

--[[------------------------------------------------------------------------@@@
# import: import Lua scripts into tables

```lua
local import = require "import"
```

The import module can be used to manage simple configuration files,
configuration parameters being global variables defined in the configuration file.

```lua
local conf = import "myconf.lua"
```
Evaluates `"myconf.lua"` in a new table and returns this table.
All files are tracked in `import.files`.

@@@]]

local F = require "F"

local import = {}
local mt = {}

import.files = F{}

function mt.__call(self, fname)
    local mod = setmetatable({}, {__index = _ENV})
    assert(loadfile(fname, "t", mod))()
    if F.not_elem(fname, self.files) then
        self.files[#self.files+1] = fname
        table.sort(self.files)
    end
    return mod
end

return setmetatable(import, mt)
]=]),
["linenoise"] = lib("libluax/linenoise/linenoise.lua", [=[--[[
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

--@LIB

local _, linenoise = pcall(require, "_linenoise")
linenoise = _ and linenoise

if not linenoise then

    local F = require "F"
    local term = require "term"

    local nop = F.const()

    linenoise = {}

    linenoise.read = term.prompt
    linenoise.read_mask = linenoise.read

    linenoise.add = nop
    linenoise.set_len = nop
    linenoise.save = nop
    linenoise.load = nop
    linenoise.multi_line = nop
    linenoise.mask = nop

    linenoise.clear = term.clear

end

return linenoise
]=]),
["lpeg"] = lib("libluax/lpeg/lpeg.lua", [=[--[[
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

--@LIB
local lpeg = require "_lpeg"

return lpeg
]=]),
["lz4"] = lib("libluax/lz4/lz4.lua", [=[--[[
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

-- Load lz4.lua to add new methods to strings
--@LOAD=_

--[[------------------------------------------------------------------------@@@
## String methods

The `lz4` functions are also available as `string` methods:
@@@]]

local _, lz4 = pcall(require, "_lz4")
lz4 = _ and lz4

if not lz4 then

    lz4 = {}

    local fs = require "fs"
    local sh = require "sh"

    function lz4.lz4(s)
        return fs.with_tmpfile(function(tmp)
            assert(sh.write("lz4 -q -z -BD -9 --frame-crc -f -", tmp)(s))
            return fs.read_bin(tmp)
        end)
    end

    function lz4.unlz4(s)
        return fs.with_tmpfile(function(tmp)
            assert(sh.write("lz4 -q -d -f -", tmp)(s))
            return fs.read_bin(tmp)
        end)
    end

end

--[[@@@
```lua
s:lz4()         == lz4.lz4(s)
s:unlz4()       == lz4.unlz4(s)
```
@@@]]

function string.lz4(s)      return lz4.lz4(s) end
function string.unlz4(s)    return lz4.unlz4(s) end

return lz4
]=]),
["lzw"] = lib("libluax/lzw/lzw.lua", [=[--[[
MIT License

Copyright (c) 2016 Rochet2

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Adapted for LuaX

-- Load lzw.lua to add new methods to strings
--@LOAD=_

--[[------------------------------------------------------------------------@@@
# lzw: A relatively fast LZW compression algorithm in pure Lua

```lua
local lzw = require "lzw"
```

LZW is a relatively fast LZW compression algorithm in pure Lua.

The source code in on Github: <https://github.com/Rochet2/lualzw>.

## LZW compression

```lua
lzw.lzw(data)
```
compresses `data` with LZW.

## LZW decompression

```lua
lzw.unlzw(data)
```
decompresses `data` with LZW.
@@@]]

local char = string.char
local type = type
local sub = string.sub
local tconcat = table.concat

local basedictcompress = {}
local basedictdecompress = {}
for i = 0, 255 do
    local ic, iic = char(i), char(i, 0)
    basedictcompress[ic] = iic
    basedictdecompress[iic] = ic
end

local function dictAddA(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b+1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[str] = char(a,b)
    a = a+1
    return dict, a, b
end

local function compress(input)
    if type(input) ~= "string" then
        return nil, "string expected, got "..type(input)
    end
    local len = #input
    if len <= 1 then
        return "u"..input
    end

    local dict = {}
    local a, b = 0, 1

    local result = {"c"}
    local resultlen = 1
    local n = 2
    local word = ""
    for i = 1, len do
        local c = sub(input, i, i)
        local wc = word..c
        if not (basedictcompress[wc] or dict[wc]) then
            local write = basedictcompress[word] or dict[word]
            if not write then
                return nil, "algorithm error, could not fetch word"
            end
            result[n] = write
            resultlen = resultlen + #write
            n = n+1
            if  len <= resultlen then
                return "u"..input
            end
            dict, a, b = dictAddA(wc, dict, a, b)
            word = c
        else
            word = wc
        end
    end
    result[n] = basedictcompress[word] or dict[word]
    resultlen = resultlen+#result[n]
    n = n+1
    if  len <= resultlen then
        return "u"..input
    end
    return tconcat(result)
end

local function dictAddB(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b+1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[char(a,b)] = str
    a = a+1
    return dict, a, b
end

local function decompress(input)
    if type(input) ~= "string" then
        return nil, "string expected, got "..type(input)
    end

    if #input < 1 then
        return nil, "invalid input - not a compressed string"
    end

    local control = sub(input, 1, 1)
    if control == "u" then
        return sub(input, 2)
    elseif control ~= "c" then
        return nil, "invalid input - not a compressed string"
    end
    input = sub(input, 2)
    local len = #input

    if len < 2 then
        return nil, "invalid input - not a compressed string"
    end

    local dict = {}
    local a, b = 0, 1

    local result = {}
    local n = 1
    local last = sub(input, 1, 2)
    result[n] = basedictdecompress[last] or dict[last]
    n = n+1
    for i = 3, len, 2 do
        local code = sub(input, i, i+1)
        local lastStr = basedictdecompress[last] or dict[last]
        if not lastStr then
            return nil, "could not find last from dict. Invalid input?"
        end
        local toAdd = basedictdecompress[code] or dict[code]
        if toAdd then
            result[n] = toAdd
            n = n+1
            dict, a, b = dictAddB(lastStr..sub(toAdd, 1, 1), dict, a, b)
        else
            local tmp = lastStr..sub(lastStr, 1, 1)
            result[n] = tmp
            n = n+1
            dict, a, b = dictAddB(tmp, dict, a, b)
        end
        last = code
    end
    return tconcat(result)
end

--[[------------------------------------------------------------------------@@@
## String methods

The `lzw` functions are also available as `string` methods:

```lua
s:lzw()         == lzw.lzw(s)
s:unlzw()       == lzw.unlzw(s)
```
@@@]]

string.lzw = compress
string.unlzw = decompress

return {
    lzw = compress,
    unlzw = decompress,
}
]=]),
["mathx"] = lib("libluax/mathx/mathx.lua", [=[--[[
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

--@LIB
local _, mathx = pcall(require, "_mathx")
mathx = _ and mathx

if not mathx then

    mathx = {}

    local exp = math.exp
    local log = math.log
    local log2 = function(x) return log(x, 2) end
    local abs = math.abs
    local max = math.max
    local floor = math.floor
    local ceil = math.ceil
    local modf = math.modf

    local pack = string.pack
    local unpack = string.unpack

    local inf = 1/0

    ---@diagnostic disable:unused-vararg
    local function ni(f) return function(...) error(f.." not implemented") end end

    local function sign(x) return x < 0 and -1 or 1 end

    mathx.fabs = math.abs
    mathx.acos = math.acos
    mathx.acosh = function(x) return log(x + (x^2-1)^0.5) end
    mathx.asin = math.asin
    mathx.asinh = function(x) return log(x + (x^2+1)^0.5) end
    mathx.atan = math.atan
    mathx.atan2 = math.atan
    mathx.atanh = function(x) return 0.5*log((1+x)/(1-x)) end
    mathx.cbrt = function(x) return x < 0 and -(-x)^(1/3) or x^(1/3) end
    mathx.ceil = math.ceil
    mathx.copysign = function(x, y) return abs(x) * sign(y) end
    mathx.cos = math.cos
    mathx.cosh = function(x) return (exp(x)+exp(-x))/2 end
    mathx.deg = math.deg
    mathx.erf = ni "erf"
    mathx.erfc = ni "erfc"
    mathx.exp = math.exp
    mathx.exp2 = function(x) return 2^x end
    mathx.expm1 = function(x) return exp(x)-1 end
    mathx.fdim = function(x, y) return max(x-y, 0) end
    mathx.floor = math.floor
    mathx.fma = function(x, y, z) return x*y + z end
    mathx.fmax = math.max
    mathx.fmin = math.min
    mathx.fmod = math.fmod
    mathx.frexp = function(x)
        if x == 0 then return 0, 0 end
        local ax = abs(x)
        local e = ceil(log2(ax))
        local m = ax / (2^e)
        if m == 1 then m, e = m/2, e+1 end
        return m*sign(x), e
    end
    mathx.gamma = ni "gamma"
    mathx.hypot = function(x, y)
        if x == 0 and y == 0 then return 0.0 end
        local ax, ay = abs(x), abs(y)
        if ax > ay then return ax * (1+(y/x)^2)^0.5 end
        return ay * (1+(x/y)^2)^0.5
    end
    mathx.isfinite = function(x) return abs(x) < inf end
    mathx.isinf = function(x) return abs(x) == inf end
    mathx.isnan = function(x) return x ~= x end
    mathx.isnormal = ni "isnormal"
    mathx.ldexp = function(x, e) return x*2^e end
    mathx.lgamma = ni "lgamma"
    mathx.log = math.log
    mathx.log10 = function(x) return log(x, 10) end
    mathx.log1p = function(x) return log(1+x) end
    mathx.log2 = function(x) return log(x, 2) end
    mathx.logb = ni "logb"
    mathx.modf = math.modf
    mathx.nearbyint = function(x)
        local m = modf(x)
        if m%2 == 0 then
            return x < 0 and floor(x+0.5) or ceil(x-0.5)
        else
            return x >= 0 and floor(x+0.5) or ceil(x-0.5)
        end
    end
    mathx.nextafter = function(x, y)
        if x == y then return x end
        if x == 0 then
            if y > 0 then return 0x0.0000000000001p-1022 end
            if y < 0 then return -0x0.0000000000001p-1022 end
        end
        local i = unpack("i8", pack("d", x))
        i = i + (  y > x and x < 0 and -1
                or y < x and x < 0 and 1
                or y > x and x > 0 and 1
                or y < x and x > 0 and -1
                )
        return unpack("d", pack("i8", i))
    end
    mathx.pow = function(x, y) return x^y end
    mathx.rad = math.rad
    mathx.round = function(x) return x >= 0 and floor(x+0.5) or ceil(x-0.5) end
    mathx.scalbn = ni "scalbn"
    mathx.sin = math.sin
    mathx.sinh = function(x) return (exp(x)-exp(-x))/2 end
    mathx.sqrt = math.sqrt
    mathx.tan = math.tan
    mathx.tanh = function(x) return (exp(x)-exp(-x))/(exp(x)+exp(-x)) end
    mathx.trunc = function(x) return x >= 0 and floor(x) or ceil(x) end

    mathx.inf = inf
    mathx.nan = math.abs(0/0)
    mathx.pi = math.pi

end

return mathx
]=]),
["package_hook"] = lib("libluax/package/package_hook.lua", [==[--[[
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

--@LOAD=_

local F = require "F"

-- inspired by https://stackoverflow.com/questions/60283272/how-to-get-the-exact-path-to-the-script-that-was-loaded-in-lua

-- This module wraps package searchers in a function that tracks package paths.
-- The paths are stored in package.modpath, which can be used to generate dependency files
-- for [ypp](https://cdelord.fr/ypp) or [panda](https://cdelord.fr/panda).

--[=[-----------------------------------------------------------------------@@@
# package

The standard Lua package `package` is added some information about packages loaded by LuaX.
@@@]=]

--[[@@@
```lua
package.modpath      -- { module_name = module_path }
```
> table containing the names of the loaded packages and their actual paths.
@@@]]

package.modpath = F{}

local function wrap_searcher(searcher)
    return function(modname)
        local loader, path = searcher(modname)
        if type(loader) == "function" then
            package.modpath[modname] = path
        end
        return loader, path
    end
end

for i = 2, #package.searchers do
    package.searchers[i] = wrap_searcher(package.searchers[i])
end
]==]),
["ps"] = lib("libluax/ps/ps.lua", [=[--[[
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

--@LIB
local _, ps = pcall(require, "_ps")
ps = _ and ps

if not ps then
    ps = {}

    function ps.sleep(n)
        io.popen("sleep "..tostring(n)):close()
    end

    ps.time = os.time

    ps.clock = os.clock

    function ps.profile(func)
        local clock = ps.clock
        local ok, dt = pcall(function()
            local t0 = clock()
            func()
            local t1 = clock()
            return t1 - t0
        end)
        if ok then
            return dt
        else
            return ok, dt
        end

    end

end

return ps
]=]),
["qmath"] = lib("libluax/qmath/qmath.lua", [=[--[[
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

--@LIB
local _, qmath = pcall(require, "_qmath")
qmath = _ and qmath

--[[@@@
## qmath additional functions
@@@]]

if not qmath then

    qmath = {}
    local mt = {__index={}}

    local imath = require "imath"
    local Z = imath.new
    local gcd = imath.gcd

    local function rat(num, den)
        if not den then
            if type(num) == "table" and num.num and num.den then return num end
            den = 1
        end
        num, den = Z(num), Z(den)
        assert(den ~= 0, "(qmath) result undefined")
        if den < 0 then num, den = -num, -den end
        if num:iszero() then
            den = Z(1)
        else
            local d = gcd(num, den)
            num, den = num/d, den/d
        end
        return setmetatable({num=num, den=den}, mt)
    end

    local rat_zero = rat(0)
    local rat_one = rat(1)

    local function rat_tostring(r)
        if r.den:isone() then return tostring(r.num) end
        return ("%s/%s"):format(r.num, r.den)
    end

    local function compare(a, b)
        return (a.num*b.den):compare(b.num*a.den)
    end

    mt.__add = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den + b.num*a.den, a.den*b.den) end
    mt.__div = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den, a.den*b.num) end
    mt.__eq = function(a, b) a, b = rat(a), rat(b); return compare(a, b) == 0 end
    mt.__le = function(a, b) a, b = rat(a), rat(b); return compare(a, b) <= 0 end
    mt.__lt = function(a, b) a, b = rat(a), rat(b); return compare(a, b) < 0 end
    mt.__mul = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.num, a.den*b.den) end
    mt.__pow = function(a, b)
        if type(b) == "number" and math.type(b) == "float" then
            error("bad argument #2 to 'pow' (number has no integer representation)")
        end
        if b == 0 then return rat_one end
        if a == 0 then return rat_zero end
        if a == 1 then return rat_one end
        if b < 0 then
            b = -b
            return rat(a.den^b, a.num^b)
        end
        return rat(a.num^b, a.den^b)
    end
    mt.__sub = function(a, b) a, b = rat(a), rat(b); return rat(a.num*b.den - b.num*a.den, a.den*b.den) end
    mt.__tostring = rat_tostring
    mt.__unm = function(a) return rat(-a.num, a.den) end
    mt.__index.abs = function(a) return rat(a.num:abs(), a.den) end
    mt.__index.add = mt.__add
    mt.__index.compare = function(a, b) return compare(rat(a), rat(b)) end
    mt.__index.denom = function(a) return rat(a.den) end
    mt.__index.div = mt.__div
    mt.__index.int = function(a) return rat(a.num / a.den) end
    mt.__index.inv = function(a) return rat(a.den, a.num) end
    mt.__index.isinteger = function(a) return a.den:isone() end
    mt.__index.iszero = function(a) return a.num:iszero() end
    mt.__index.mul = mt.__mul
    mt.__index.neg = mt.__unm
    mt.__index.numer = function(a) return rat(a.num) end
    mt.__index.pow = mt.__pow
    mt.__index.sign = function(a) return compare(a, rat_zero) end
    mt.__index.sub = mt.__sub
    mt.__index.todecimal = function(a) return tostring(a.num // a.den) end
    mt.__index.tonumber = function(a) return a.num:tonumber()/a.den:tonumber() end

    qmath.abs = function(a) return rat(a):abs() end
    qmath.add = function(a, b) return rat(a) + rat(b) end
    qmath.compare = function(a, b) return rat(a):compare(rat(b)) end
    qmath.denom = function(a) return rat(a):denom() end
    qmath.div = function(a, b) return rat(a) / rat(b) end
    qmath.int = function(a) return rat(a):int() end
    qmath.inv = function(a) return rat(a):inv() end
    qmath.isinteger = function(a) return rat(a):isinteger() end
    qmath.iszero = function(a) return rat(a):iszero() end
    qmath.mul = function(a, b) return rat(a) * rat(b) end
    qmath.neg = function(a) return -rat(a) end
    qmath.new = rat
    qmath.numer = function(a) return rat(a):numer() end
    qmath.pow = function(a, b) return rat(a) ^ b end
    qmath.sign = function(a) return rat(a):sign() end
    qmath.sub = function(a, b) return rat(a) - rat(b) end
    qmath.todecimal = function(a) return rat(a):todecimal() end
    qmath.tonumber = function(a) return rat(a):tonumber() end
    qmath.tostring = mt.__tostring

end

--[[@@@
```lua
q = qmath.torat(x, [eps])
```
approximates a floating point number `x` with a rational value.
The rational number `q` is an approximation of `x` such that $|q - x| < eps$.
The default `eps` value is $10^{-6}$.
@@@]]

local rat = qmath.new
local floor = math.floor
local abs = math.abs

local function frac(a)
    local q = rat(a[#a])
    for i = #a-1, 1, -1 do
        q = a[i] + 1/q
    end
    return q
end

function qmath.torat(x, eps)
    eps = eps or 1e-6
    local x0 = x
    local a = {floor(x)}
    x = x - a[1]
    local q = frac(a)
    while abs(x0 - q:tonumber()) > eps and #a < 64 do
        local y = 1/x
        a[#a+1] = floor(y)
        x = y - a[#a]
        q = frac(a)
    end
    return q
end

return qmath
]=]),
["sh"] = lib("libluax/sh/sh.lua", [=[--[[
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

--@LIB

--[[------------------------------------------------------------------------@@@
## Shell
@@@]]

--[[@@@
```lua
local sh = require "sh"
```
@@@]]
local sh = {}

local F = require "F"

--[[@@@
```lua
sh.run(...)
```
Runs the command `...` with `os.execute`.
@@@]]

function sh.run(...)
    local cmd = F.flatten{...}:unwords()
    return os.execute(cmd)
end

--[[@@@
```lua
sh.read(...)
```
Runs the command `...` with `io.popen`.
When `sh.read` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `io.popen`.
@@@]]

function sh.read(...)
    local cmd = F.flatten{...}:unwords()
    local p, popen_err = io.popen(cmd, "r")
    if not p then return p, popen_err end
    local out = p:read("a")
    local ok, exit, ret = p:close()
    if ok then
        return out
    else
        return ok, exit, ret
    end
end

--[[@@@
```lua
sh.write(...)(data)
```
Runs the command `...` with `io.popen` and feeds `stdin` with `data`.
`sh.write` returns the same values returned by `os.execute`.
@@@]]

function sh.write(...)
    local cmd = F.flatten{...}:unwords()
    return function(data)
        local p, popen_err = io.popen(cmd, "w")
        if not p then return p, popen_err end
        p:write(data)
        return p:close()
    end
end

if pandoc then

--[[@@@
```lua
sh.pipe(...)(data)
```
Runs the command `...` with `pandoc.pipe` and feeds `stdin` with `data`.
When `sh.pipe` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `pandoc.pipe`.
@@@]]

    function sh.pipe(...)
        local cmd = F.flatten{...}
        return function(data)
            local ok, out = pcall(pandoc.pipe, cmd:head(), cmd:tail(), data)
            if not ok then return nil, out end
            return out
        end
    end

end

--[[@@@
``` lua
sh(...)
```
`sh` can be called as a function. `sh(...)` is a shortcut to `sh.read(...)`.
@@@]]
setmetatable(sh, {
    __call = function(_, ...) return sh.read(...) end,
})

return sh
]=]),
["sys"] = lib("libluax/sys/sys.lua", [=[--[[
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

--@LIB
local _, sys = pcall(require, "_sys")
sys = _ and sys or {
    libc = "lua",
}

local F = require "F"

local targets = F{
    {name="linux-x86_64",       uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86_64-musl",  uname_machine="x86_64",  os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"   },
    {name="linux-aarch64",      uname_machine="aarch64", os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so"   },
    {name="linux-aarch64-musl", uname_machine="aarch64", os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"   },
    {name="macos-x86_64",       uname_machine="x86_64",  os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      uname_machine="arm64",   os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    {name="windows-x86_64",     uname_machine="AMD64",   os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll"  },
}
targets : foreach(function(target) targets[target.name] = target end)

if sys.libc == "lua" then

    local function uname() return io.popen("uname -m", "r") : read "a" : trim() end

    -- the libraries extension in package.cpath is specific to the OS
    sys.so = package.cpath:match "%.[^%.]-$"
    sys.os = assert(targets : find(function(t) return t.so == sys.so end), "Unknown OS").os

    sys.arch = pandoc and pandoc.system.arch or
        (function()
            local machine = F.case(sys.os) {
                linux   = uname,
                macos   = uname,
                windows = function() return os.getenv "PROCESSOR_ARCHITECTURE" end,
            }()
            return assert(targets : find(function(t) return t.os==sys.os and t.uname_machine==machine end), "Unknown architecture").arch
        end)()

    local host = assert(targets : find(function(t) return t.os==sys.os and t.arch==sys.arch end), "Unknown platform")

    sys.exe  = host.exe
    sys.name = host.name

end

return setmetatable(sys, {
    __index = {
        targets = targets,
    },
})
]=]),
["term"] = lib("libluax/term/term.lua", [=[--[[
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
# Terminal

`term` provides some functions to deal with the terminal in a quite portable way.
It is heavily inspired by:

- [lua-term](https://github.com/hoelzro/lua-term/): Terminal operations for Lua
- [nocurses](https://github.com/osch/lua-nocurses/): A terminal screen manipulation library

```lua
local term = require "term"
```
@@@]]

local _, term = pcall(require, "_term")
term = _ and term

if not term then
    term = {}

    local sh = require "sh"

    if not term.isatty then

        local _isatty = nil

        function term.isatty()
            if _isatty == nil then
                _isatty = (sh.run("tty", "--silent", "2>/dev/null"))
            end
            return _isatty
        end

    end

    if not term.size then

        function term.size()
            local rows, cols = sh.read("stty", "size")
                : words() ---@diagnostic disable-line: undefined-field
                : map(tonumber):unpack()
            return {rows=rows, cols=cols}
        end

    end

end

local ESC = '\027'
local CSI = ESC..'['

--[[------------------------------------------------------------------------@@@
## Colors

The table `term.colors` contain objects that can be used to build
colorized string with ANSI sequences.

An object `term.color.X` can be used:

- as a string
- as a function
- in combination with other color attributes

``` lua
-- change colors in a string
" ... " .. term.color.X .. " ... "

-- change colors for a string and reset colors at the end of the string
term.color.X("...")

-- build a complex color with attributes
local c = term.color.red + term.color.italic + term.color.oncyan
```
@@@]]

local color_mt, color_reset
color_mt = {
    __tostring = function(self) return self.value end,
    __concat = function(self, other) return tostring(self)..tostring(other) end,
    __call = function(self, s) return self..s..color_reset end,
    __add = function(self, other) return setmetatable({value=self..other}, color_mt) end,
}
local function color(value) return setmetatable({value=CSI..tostring(value).."m"}, color_mt) end
--                                @@@`term.color` field     Description                         @@@
--                                @@@---------------------- ------------------------------------@@@
term.color = {
    -- attributes
    reset       = color(0),     --@@@reset                  reset the colors                    @@@
    clear       = color(0),     --@@@clear                  same as reset                       @@@
    default     = color(0),     --@@@default                same as reset                       @@@
    bright      = color(1),     --@@@bright                 bold or more intense                @@@
    bold        = color(1),     --@@@bold                   same as bold                        @@@
    dim         = color(2),     --@@@dim                    thiner or less intense              @@@
    italic      = color(3),     --@@@italic                 italic (sometimes inverse or blink) @@@
    underline   = color(4),     --@@@underline              underlined                          @@@
    blink       = color(5),     --@@@blink                  slow blinking (less than 150 bpm)   @@@
    fast        = color(6),     --@@@fast                   fast blinking (more than 150 bpm)   @@@
    reverse     = color(7),     --@@@reverse                swap foreground and background      @@@
    hidden      = color(8),     --@@@hidden                 hidden text                         @@@
    strike      = color(9),     --@@@strike                 strike or crossed-out               @@@
    -- foreground
    black       = color(30),    --@@@black                  black foreground                    @@@
    red         = color(31),    --@@@red                    red foreground                      @@@
    green       = color(32),    --@@@green                  green foreground                    @@@
    yellow      = color(33),    --@@@yellow                 yellow foreground                   @@@
    blue        = color(34),    --@@@blue                   blue foreground                     @@@
    magenta     = color(35),    --@@@magenta                magenta foreground                  @@@
    cyan        = color(36),    --@@@cyan                   cyan foreground                     @@@
    white       = color(37),    --@@@white                  white foreground                    @@@
    -- background
    onblack     = color(40),    --@@@onblack                black background                    @@@
    onred       = color(41),    --@@@onred                  red background                      @@@
    ongreen     = color(42),    --@@@ongreen                green background                    @@@
    onyellow    = color(43),    --@@@onyellow               yellow background                   @@@
    onblue      = color(44),    --@@@onblue                 blue background                     @@@
    onmagenta   = color(45),    --@@@onmagenta              magenta background                  @@@
    oncyan      = color(46),    --@@@oncyan                 cyan background                     @@@
    onwhite     = color(47),    --@@@onwhite                white background                    @@@
}

color_reset = term.color.reset

--[[------------------------------------------------------------------------@@@
## Cursor

The table `term.cursor` contains functions to change the shape of the cursor:

``` lua
-- turns the cursor into a blinking vertical thin bar
term.cursor.bar_blink()
```

@@@]]

local function cursor(shape)
    shape = CSI..shape..' q'
    return function()
        io.stdout:write(shape)
    end
end

--                                  @@@`term.cursor` field      Description                         @@@
--                                  @@@------------------------ ------------------------------------@@@
term.cursor = {
    reset           = cursor(0),  --@@@reset                    reset to the initial shape          @@@
    block_blink     = cursor(1),  --@@@block_blink              blinking block cursor               @@@
    block           = cursor(2),  --@@@block                    fixed block cursor                  @@@
    underline_blink = cursor(3),  --@@@underline_blink          blinking underline cursor           @@@
    underline       = cursor(4),  --@@@underline                fixed underline cursor              @@@
    bar_blink       = cursor(5),  --@@@bar_blink                blinking bar cursor                 @@@
    bar             = cursor(6),  --@@@bar                      fixed bar cursor                    @@@
}

--[[------------------------------------------------------------------------@@@
## Terminal

@@@]]

local function f(fmt)
    local function w(h, ...)
        if io.type(h) ~= 'file' then
            return w(io.stdout, h, ...)
        end
        return h:write(fmt:format(...))
    end
    return w
end

--[[@@@
``` lua
term.reset()
```
resets the colors and the cursor shape.
@@@]]
term.reset    = f(color_reset..     -- reset colors
                  CSI.."0 q"..      -- reset cursor shape
                  CSI..'?25h'       -- restore cursor
                 )

--[[@@@
``` lua
term.clear()
term.clearline()
term.cleareol()
term.clearend()
```
clears the terminal, the current line, the end of the current line or from the cursor to the end of the terminal.
@@@]]
term.clear       = f(CSI..'1;1H'..CSI..'2J')
term.clearline   = f(CSI..'2K'..CSI..'E')
term.cleareol    = f(CSI..'K')
term.clearend    = f(CSI..'J')

--[[@@@
``` lua
term.pos(row, col)
```
moves the cursor to the line `row` and the column `col`.
@@@]]
term.pos         = f(CSI..'%d;%dH')

--[[@@@
``` lua
term.save_pos()
term.restore_pos()
```
saves and restores the position of the cursor.
@@@]]
term.save_pos    = f(CSI..'s')
term.restore_pos = f(CSI..'u')

--[[@@@
``` lua
term.up([n])
term.down([n])
term.right([n])
term.left([n])
```
moves the cursor by `n` characters up, down, right or left.
@@@]]
term.up          = f(CSI..'%d;A')
term.down        = f(CSI..'%d;B')
term.right       = f(CSI..'%d;C')
term.left        = f(CSI..'%d;D')

--[[------------------------------------------------------------------------@@@
## Prompt

The prompt function is a basic prompt implementation
to display a prompt and get user inputs.

The use of [rlwrap](https://github.com/hanslub42/rlwrap)
is highly recommended for a better user experience on Linux.
@@@]]

--[[@@@
```lua
s = term.prompt(p)
```
prints `p` and waits for a user input
@@@]]

function term.prompt(p)
    if p and term.isatty() then
        io.write(p)
        io.flush()
    end
    return io.read "l"
end

return term
]=]),
["argparse"] = lib("ext/lua/argparse/argparse.lua", [==[-- The MIT License (MIT)

-- Copyright (c) 2013 - 2018 Peter Melnichenko
--                      2019 Paul Ouellette

-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local function deep_update(t1, t2)
   for k, v in pairs(t2) do
      if type(v) == "table" then
         v = deep_update({}, v)
      end

      t1[k] = v
   end

   return t1
end

-- A property is a tuple {name, callback}.
-- properties.args is number of properties that can be set as arguments
-- when calling an object.
local function class(prototype, properties, parent)
   -- Class is the metatable of its instances.
   local cl = {}
   cl.__index = cl

   if parent then
      cl.__prototype = deep_update(deep_update({}, parent.__prototype), prototype)
   else
      cl.__prototype = prototype
   end

   if properties then
      local names = {}

      -- Create setter methods and fill set of property names.
      for _, property in ipairs(properties) do
         local name, callback = property[1], property[2]

         cl[name] = function(self, value)
            if not callback(self, value) then
               self["_" .. name] = value
            end

            return self
         end

         names[name] = true
      end

      function cl.__call(self, ...)
         -- When calling an object, if the first argument is a table,
         -- interpret keys as property names, else delegate arguments
         -- to corresponding setters in order.
         if type((...)) == "table" then
            for name, value in pairs((...)) do
               if names[name] then
                  self[name](self, value)
               end
            end
         else
            local nargs = select("#", ...)

            for i, property in ipairs(properties) do
               if i > nargs or i > properties.args then
                  break
               end

               local arg = select(i, ...)

               if arg ~= nil then
                  self[property[1]](self, arg)
               end
            end
         end

         return self
      end
   end

   -- If indexing class fails, fallback to its parent.
   local class_metatable = {}
   class_metatable.__index = parent

   function class_metatable.__call(self, ...)
      -- Calling a class returns its instance.
      -- Arguments are delegated to the instance.
      local object = deep_update({}, self.__prototype)
      setmetatable(object, self)
      return object(...)
   end

   return setmetatable(cl, class_metatable)
end

local function typecheck(name, types, value)
   for _, type_ in ipairs(types) do
      if type(value) == type_ then
         return true
      end
   end

   error(("bad property '%s' (%s expected, got %s)"):format(name, table.concat(types, " or "), type(value)))
end

local function typechecked(name, ...)
   local types = {...}
   return {name, function(_, value) typecheck(name, types, value) end}
end

local multiname = {"name", function(self, value)
   typecheck("name", {"string"}, value)

   for alias in value:gmatch("%S+") do
      self._name = self._name or alias
      table.insert(self._aliases, alias)
      table.insert(self._public_aliases, alias)
      -- If alias contains '_', accept '-' also.
      if alias:find("_", 1, true) then
         table.insert(self._aliases, (alias:gsub("_", "-")))
      end
   end

   -- Do not set _name as with other properties.
   return true
end}

local multiname_hidden = {"hidden_name", function(self, value)
   typecheck("hidden_name", {"string"}, value)

   for alias in value:gmatch("%S+") do
      table.insert(self._aliases, alias)
      if alias:find("_", 1, true) then
         table.insert(self._aliases, (alias:gsub("_", "-")))
      end
   end

   return true
end}

local function parse_boundaries(str)
   if tonumber(str) then
      return tonumber(str), tonumber(str)
   end

   if str == "*" then
      return 0, math.huge
   end

   if str == "+" then
      return 1, math.huge
   end

   if str == "?" then
      return 0, 1
   end

   if str:match "^%d+%-%d+$" then
      local min, max = str:match "^(%d+)%-(%d+)$"
      return tonumber(min), tonumber(max)
   end

   if str:match "^%d+%+$" then
      local min = str:match "^(%d+)%+$"
      return tonumber(min), math.huge
   end
end

local function boundaries(name)
   return {name, function(self, value)
      typecheck(name, {"number", "string"}, value)

      local min, max = parse_boundaries(value)

      if not min then
         error(("bad property '%s'"):format(name))
      end

      self["_min" .. name], self["_max" .. name] = min, max
   end}
end

local actions = {}

local option_action = {"action", function(_, value)
   typecheck("action", {"function", "string"}, value)

   if type(value) == "string" and not actions[value] then
      error(("unknown action '%s'"):format(value))
   end
end}

local option_init = {"init", function(self)
   self._has_init = true
end}

local option_default = {"default", function(self, value)
   if type(value) ~= "string" then
      self._init = value
      self._has_init = true
      return true
   end
end}

local add_help = {"add_help", function(self, value)
   typecheck("add_help", {"boolean", "string", "table"}, value)

   if self._help_option_idx then
      table.remove(self._options, self._help_option_idx)
      self._help_option_idx = nil
   end

   if value then
      local help = self:flag()
         :description "Show this help message and exit."
         :action(function()
            print(self:get_help())
            os.exit(0)
         end)

      if value ~= true then
         help = help(value)
      end

      if not help._name then
         help "-h" "--help"
      end

      self._help_option_idx = #self._options
   end
end}

local Parser = class({
   _arguments = {},
   _options = {},
   _commands = {},
   _mutexes = {},
   _groups = {},
   _require_command = true,
   _handle_options = true
}, {
   args = 3,
   typechecked("name", "string"),
   typechecked("description", "string"),
   typechecked("epilog", "string"),
   typechecked("usage", "string"),
   typechecked("help", "string"),
   typechecked("require_command", "boolean"),
   typechecked("handle_options", "boolean"),
   typechecked("action", "function"),
   typechecked("command_target", "string"),
   typechecked("help_vertical_space", "number"),
   typechecked("usage_margin", "number"),
   typechecked("usage_max_width", "number"),
   typechecked("help_usage_margin", "number"),
   typechecked("help_description_margin", "number"),
   typechecked("help_max_width", "number"),
   add_help
})

local Command = class({
   _aliases = {},
   _public_aliases = {}
}, {
   args = 3,
   multiname,
   typechecked("description", "string"),
   typechecked("epilog", "string"),
   multiname_hidden,
   typechecked("summary", "string"),
   typechecked("target", "string"),
   typechecked("usage", "string"),
   typechecked("help", "string"),
   typechecked("require_command", "boolean"),
   typechecked("handle_options", "boolean"),
   typechecked("action", "function"),
   typechecked("command_target", "string"),
   typechecked("help_vertical_space", "number"),
   typechecked("usage_margin", "number"),
   typechecked("usage_max_width", "number"),
   typechecked("help_usage_margin", "number"),
   typechecked("help_description_margin", "number"),
   typechecked("help_max_width", "number"),
   typechecked("hidden", "boolean"),
   add_help
}, Parser)

local Argument = class({
   _minargs = 1,
   _maxargs = 1,
   _mincount = 1,
   _maxcount = 1,
   _defmode = "unused",
   _show_default = true
}, {
   args = 5,
   typechecked("name", "string"),
   typechecked("description", "string"),
   option_default,
   typechecked("convert", "function", "table"),
   boundaries("args"),
   typechecked("target", "string"),
   typechecked("defmode", "string"),
   typechecked("show_default", "boolean"),
   typechecked("argname", "string", "table"),
   typechecked("choices", "table"),
   typechecked("hidden", "boolean"),
   option_action,
   option_init
})

local Option = class({
   _aliases = {},
   _public_aliases = {},
   _mincount = 0,
   _overwrite = true
}, {
   args = 6,
   multiname,
   typechecked("description", "string"),
   option_default,
   typechecked("convert", "function", "table"),
   boundaries("args"),
   boundaries("count"),
   multiname_hidden,
   typechecked("target", "string"),
   typechecked("defmode", "string"),
   typechecked("show_default", "boolean"),
   typechecked("overwrite", "boolean"),
   typechecked("argname", "string", "table"),
   typechecked("choices", "table"),
   typechecked("hidden", "boolean"),
   option_action,
   option_init
}, Argument)

function Parser:_inherit_property(name, default)
   local element = self

   while true do
      local value = element["_" .. name]

      if value ~= nil then
         return value
      end

      if not element._parent then
         return default
      end

      element = element._parent
   end
end

function Argument:_get_argument_list()
   local buf = {}
   local i = 1

   while i <= math.min(self._minargs, 3) do
      local argname = self:_get_argname(i)

      if self._default and self._defmode:find "a" then
         argname = "[" .. argname .. "]"
      end

      table.insert(buf, argname)
      i = i+1
   end

   while i <= math.min(self._maxargs, 3) do
      table.insert(buf, "[" .. self:_get_argname(i) .. "]")
      i = i+1

      if self._maxargs == math.huge then
         break
      end
   end

   if i < self._maxargs then
      table.insert(buf, "...")
   end

   return buf
end

function Argument:_get_usage()
   local usage = table.concat(self:_get_argument_list(), " ")

   if self._default and self._defmode:find "u" then
      if self._maxargs > 1 or (self._minargs == 1 and not self._defmode:find "a") then
         usage = "[" .. usage .. "]"
      end
   end

   return usage
end

function actions.store_true(result, target)
   result[target] = true
end

function actions.store_false(result, target)
   result[target] = false
end

function actions.store(result, target, argument)
   result[target] = argument
end

function actions.count(result, target, _, overwrite)
   if not overwrite then
      result[target] = result[target] + 1
   end
end

function actions.append(result, target, argument, overwrite)
   result[target] = result[target] or {}
   table.insert(result[target], argument)

   if overwrite then
      table.remove(result[target], 1)
   end
end

function actions.concat(result, target, arguments, overwrite)
   if overwrite then
      error("'concat' action can't handle too many invocations")
   end

   result[target] = result[target] or {}

   for _, argument in ipairs(arguments) do
      table.insert(result[target], argument)
   end
end

function Argument:_get_action()
   local action, init

   if self._maxcount == 1 then
      if self._maxargs == 0 then
         action, init = "store_true", nil
      else
         action, init = "store", nil
      end
   else
      if self._maxargs == 0 then
         action, init = "count", 0
      else
         action, init = "append", {}
      end
   end

   if self._action then
      action = self._action
   end

   if self._has_init then
      init = self._init
   end

   if type(action) == "string" then
      action = actions[action]
   end

   return action, init
end

-- Returns placeholder for `narg`-th argument.
function Argument:_get_argname(narg)
   local argname = self._argname or self:_get_default_argname()

   if type(argname) == "table" then
      return argname[narg]
   else
      return argname
   end
end

function Argument:_get_choices_list()
   return "{" .. table.concat(self._choices, ",") .. "}"
end

function Argument:_get_default_argname()
   if self._choices then
      return self:_get_choices_list()
   else
      return "<" .. self._name .. ">"
   end
end

function Option:_get_default_argname()
   if self._choices then
      return self:_get_choices_list()
   else
      return "<" .. self:_get_default_target() .. ">"
   end
end

-- Returns labels to be shown in the help message.
function Argument:_get_label_lines()
   if self._choices then
      return {self:_get_choices_list()}
   else
      return {self._name}
   end
end

function Option:_get_label_lines()
   local argument_list = self:_get_argument_list()

   if #argument_list == 0 then
      -- Don't put aliases for simple flags like `-h` on different lines.
      return {table.concat(self._public_aliases, ", ")}
   end

   local longest_alias_length = -1

   for _, alias in ipairs(self._public_aliases) do
      longest_alias_length = math.max(longest_alias_length, #alias)
   end

   local argument_list_repr = table.concat(argument_list, " ")
   local lines = {}

   for i, alias in ipairs(self._public_aliases) do
      local line = (" "):rep(longest_alias_length - #alias) .. alias .. " " .. argument_list_repr

      if i ~= #self._public_aliases then
         line = line .. ","
      end

      table.insert(lines, line)
   end

   return lines
end

function Command:_get_label_lines()
   return {table.concat(self._public_aliases, ", ")}
end

function Argument:_get_description()
   if self._default and self._show_default then
      if self._description then
         return ("%s (default: %s)"):format(self._description, self._default)
      else
         return ("default: %s"):format(self._default)
      end
   else
      return self._description or ""
   end
end

function Command:_get_description()
   return self._summary or self._description or ""
end

function Option:_get_usage()
   local usage = self:_get_argument_list()
   table.insert(usage, 1, self._name)
   usage = table.concat(usage, " ")

   if self._mincount == 0 or self._default then
      usage = "[" .. usage .. "]"
   end

   return usage
end

function Argument:_get_default_target()
   return self._name
end

function Option:_get_default_target()
   local res

   for _, alias in ipairs(self._public_aliases) do
      if alias:sub(1, 1) == alias:sub(2, 2) then
         res = alias:sub(3)
         break
      end
   end

   res = res or self._name:sub(2)
   return (res:gsub("-", "_"))
end

function Option:_is_vararg()
   return self._maxargs ~= self._minargs
end

function Parser:_get_fullname(exclude_root)
   local parent = self._parent
   if exclude_root and not parent then
      return ""
   end
   local buf = {self._name}

   while parent do
      if not exclude_root or parent._parent then
         table.insert(buf, 1, parent._name)
      end
      parent = parent._parent
   end

   return table.concat(buf, " ")
end

function Parser:_update_charset(charset)
   charset = charset or {}

   for _, command in ipairs(self._commands) do
      command:_update_charset(charset)
   end

   for _, option in ipairs(self._options) do
      for _, alias in ipairs(option._aliases) do
         charset[alias:sub(1, 1)] = true
      end
   end

   return charset
end

function Parser:argument(...)
   local argument = Argument(...)
   table.insert(self._arguments, argument)
   return argument
end

function Parser:option(...)
   local option = Option(...)
   table.insert(self._options, option)
   return option
end

function Parser:flag(...)
   return self:option():args(0)(...)
end

function Parser:command(...)
   local command = Command():add_help(true)(...)
   command._parent = self
   table.insert(self._commands, command)
   return command
end

function Parser:mutex(...)
   local elements = {...}

   for i, element in ipairs(elements) do
      local mt = getmetatable(element)
      assert(mt == Option or mt == Argument, ("bad argument #%d to 'mutex' (Option or Argument expected)"):format(i))
   end

   table.insert(self._mutexes, elements)
   return self
end

function Parser:group(name, ...)
   assert(type(name) == "string", ("bad argument #1 to 'group' (string expected, got %s)"):format(type(name)))

   local group = {name = name, ...}

   for i, element in ipairs(group) do
      local mt = getmetatable(element)
      assert(mt == Option or mt == Argument or mt == Command,
         ("bad argument #%d to 'group' (Option or Argument or Command expected)"):format(i + 1))
   end

   table.insert(self._groups, group)
   return self
end

local usage_welcome = "Usage: "

function Parser:get_usage()
   if self._usage then
      return self._usage
   end

   local usage_margin = self:_inherit_property("usage_margin", #usage_welcome)
   local max_usage_width = self:_inherit_property("usage_max_width", 70)
   local lines = {usage_welcome .. self:_get_fullname()}

   local function add(s)
      if #lines[#lines]+1+#s <= max_usage_width then
         lines[#lines] = lines[#lines] .. " " .. s
      else
         lines[#lines+1] = (" "):rep(usage_margin) .. s
      end
   end

   -- Normally options are before positional arguments in usage messages.
   -- However, vararg options should be after, because they can't be reliable used
   -- before a positional argument.
   -- Mutexes come into play, too, and are shown as soon as possible.
   -- Overall, output usages in the following order:
   -- 1. Mutexes that don't have positional arguments or vararg options.
   -- 2. Options that are not in any mutexes and are not vararg.
   -- 3. Positional arguments - on their own or as a part of a mutex.
   -- 4. Remaining mutexes.
   -- 5. Remaining options.

   local elements_in_mutexes = {}
   local added_elements = {}
   local added_mutexes = {}
   local argument_to_mutexes = {}

   local function add_mutex(mutex, main_argument)
      if added_mutexes[mutex] then
         return
      end

      added_mutexes[mutex] = true
      local buf = {}

      for _, element in ipairs(mutex) do
         if not element._hidden and not added_elements[element] then
            if getmetatable(element) == Option or element == main_argument then
               table.insert(buf, element:_get_usage())
               added_elements[element] = true
            end
         end
      end

      if #buf == 1 then
         add(buf[1])
      elseif #buf > 1 then
         add("(" .. table.concat(buf, " | ") .. ")")
      end
   end

   local function add_element(element)
      if not element._hidden and not added_elements[element] then
         add(element:_get_usage())
         added_elements[element] = true
      end
   end

   for _, mutex in ipairs(self._mutexes) do
      local is_vararg = false
      local has_argument = false

      for _, element in ipairs(mutex) do
         if getmetatable(element) == Option then
            if element:_is_vararg() then
               is_vararg = true
            end
         else
            has_argument = true
            argument_to_mutexes[element] = argument_to_mutexes[element] or {}
            table.insert(argument_to_mutexes[element], mutex)
         end

         elements_in_mutexes[element] = true
      end

      if not is_vararg and not has_argument then
         add_mutex(mutex)
      end
   end

   for _, option in ipairs(self._options) do
      if not elements_in_mutexes[option] and not option:_is_vararg() then
         add_element(option)
      end
   end

   -- Add usages for positional arguments, together with one mutex containing them, if they are in a mutex.
   for _, argument in ipairs(self._arguments) do
      -- Pick a mutex as a part of which to show this argument, take the first one that's still available.
      local mutex

      if elements_in_mutexes[argument] then
         for _, argument_mutex in ipairs(argument_to_mutexes[argument]) do
            if not added_mutexes[argument_mutex] then
               mutex = argument_mutex
            end
         end
      end

      if mutex then
         add_mutex(mutex, argument)
      else
         add_element(argument)
      end
   end

   for _, mutex in ipairs(self._mutexes) do
      add_mutex(mutex)
   end

   for _, option in ipairs(self._options) do
      add_element(option)
   end

   if #self._commands > 0 then
      if self._require_command then
         add("<command>")
      else
         add("[<command>]")
      end

      add("...")
   end

   return table.concat(lines, "\n")
end

local function split_lines(s)
   if s == "" then
      return {}
   end

   local lines = {}

   if s:sub(-1) ~= "\n" then
      s = s .. "\n"
   end

   for line in s:gmatch("([^\n]*)\n") do
      table.insert(lines, line)
   end

   return lines
end

local function autowrap_line(line, max_length)
   -- Algorithm for splitting lines is simple and greedy.
   local result_lines = {}

   -- Preserve original indentation of the line, put this at the beginning of each result line.
   -- If the first word looks like a list marker ('*', '+', or '-'), add spaces so that starts
   -- of the second and the following lines vertically align with the start of the second word.
   local indentation = line:match("^ *")

   if line:find("^ *[%*%+%-]") then
      indentation = indentation .. " " .. line:match("^ *[%*%+%-]( *)")
   end

   -- Parts of the last line being assembled.
   local line_parts = {}

   -- Length of the current line.
   local line_length = 0

   -- Index of the next character to consider.
   local index = 1

   while true do
      local word_start, word_finish, word = line:find("([^ ]+)", index)

      if not word_start then
         -- Ignore trailing spaces, if any.
         break
      end

      local preceding_spaces = line:sub(index, word_start - 1)
      index = word_finish + 1

      if (#line_parts == 0) or (line_length + #preceding_spaces + #word <= max_length) then
         -- Either this is the very first word or it fits as an addition to the current line, add it.
         table.insert(line_parts, preceding_spaces) -- For the very first word this adds the indentation.
         table.insert(line_parts, word)
         line_length = line_length + #preceding_spaces + #word
      else
         -- Does not fit, finish current line and put the word into a new one.
         table.insert(result_lines, table.concat(line_parts))
         line_parts = {indentation, word}
         line_length = #indentation + #word
      end
   end

   if #line_parts > 0 then
      table.insert(result_lines, table.concat(line_parts))
   end

   if #result_lines == 0 then
      -- Preserve empty lines.
      result_lines[1] = ""
   end

   return result_lines
end

-- Automatically wraps lines within given array,
-- attempting to limit line length to `max_length`.
-- Existing line splits are preserved.
local function autowrap(lines, max_length)
   local result_lines = {}

   for _, line in ipairs(lines) do
      local autowrapped_lines = autowrap_line(line, max_length)

      for _, autowrapped_line in ipairs(autowrapped_lines) do
         table.insert(result_lines, autowrapped_line)
      end
   end

   return result_lines
end

function Parser:_get_element_help(element)
   local label_lines = element:_get_label_lines()
   local description_lines = split_lines(element:_get_description())

   local result_lines = {}

   -- All label lines should have the same length (except the last one, it has no comma).
   -- If too long, start description after all the label lines.
   -- Otherwise, combine label and description lines.

   local usage_margin_len = self:_inherit_property("help_usage_margin", 3)
   local usage_margin = (" "):rep(usage_margin_len)
   local description_margin_len = self:_inherit_property("help_description_margin", 25)
   local description_margin = (" "):rep(description_margin_len)

   local help_max_width = self:_inherit_property("help_max_width")

   if help_max_width then
      local description_max_width = math.max(help_max_width - description_margin_len, 10)
      description_lines = autowrap(description_lines, description_max_width)
   end

   if #label_lines[1] >= (description_margin_len - usage_margin_len) then
      for _, label_line in ipairs(label_lines) do
         table.insert(result_lines, usage_margin .. label_line)
      end

      for _, description_line in ipairs(description_lines) do
         table.insert(result_lines, description_margin .. description_line)
      end
   else
      for i = 1, math.max(#label_lines, #description_lines) do
         local label_line = label_lines[i]
         local description_line = description_lines[i]

         local line = ""

         if label_line then
            line = usage_margin .. label_line
         end

         if description_line and description_line ~= "" then
            line = line .. (" "):rep(description_margin_len - #line) .. description_line
         end

         table.insert(result_lines, line)
      end
   end

   return table.concat(result_lines, "\n")
end

local function get_group_types(group)
   local types = {}

   for _, element in ipairs(group) do
      types[getmetatable(element)] = true
   end

   return types
end

function Parser:_add_group_help(blocks, added_elements, label, elements)
   local buf = {label}

   for _, element in ipairs(elements) do
      if not element._hidden and not added_elements[element] then
         added_elements[element] = true
         table.insert(buf, self:_get_element_help(element))
      end
   end

   if #buf > 1 then
      table.insert(blocks, table.concat(buf, ("\n"):rep(self:_inherit_property("help_vertical_space", 0) + 1)))
   end
end

function Parser:get_help()
   if self._help then
      return self._help
   end

   local blocks = {self:get_usage()}

   local help_max_width = self:_inherit_property("help_max_width")

   if self._description then
      local description = self._description

      if help_max_width then
         description = table.concat(autowrap(split_lines(description), help_max_width), "\n")
      end

      table.insert(blocks, description)
   end

   -- 1. Put groups containing arguments first, then other arguments.
   -- 2. Put remaining groups containing options, then other options.
   -- 3. Put remaining groups containing commands, then other commands.
   -- Assume that an element can't be in several groups.
   local groups_by_type = {
      [Argument] = {},
      [Option] = {},
      [Command] = {}
   }

   for _, group in ipairs(self._groups) do
      local group_types = get_group_types(group)

      for _, mt in ipairs({Argument, Option, Command}) do
         if group_types[mt] then
            table.insert(groups_by_type[mt], group)
            break
         end
      end
   end

   local default_groups = {
      {name = "Arguments", type = Argument, elements = self._arguments},
      {name = "Options", type = Option, elements = self._options},
      {name = "Commands", type = Command, elements = self._commands}
   }

   local added_elements = {}

   for _, default_group in ipairs(default_groups) do
      local type_groups = groups_by_type[default_group.type]

      for _, group in ipairs(type_groups) do
         self:_add_group_help(blocks, added_elements, group.name .. ":", group)
      end

      local default_label = default_group.name .. ":"

      if #type_groups > 0 then
         default_label = "Other " .. default_label:gsub("^.", string.lower)
      end

      self:_add_group_help(blocks, added_elements, default_label, default_group.elements)
   end

   if self._epilog then
      local epilog = self._epilog

      if help_max_width then
         epilog = table.concat(autowrap(split_lines(epilog), help_max_width), "\n")
      end

      table.insert(blocks, epilog)
   end

   return table.concat(blocks, "\n\n")
end

function Parser:add_help_command(value)
   if value then
      assert(type(value) == "string" or type(value) == "table",
         ("bad argument #1 to 'add_help_command' (string or table expected, got %s)"):format(type(value)))
   end

   local help = self:command()
      :description "Show help for commands."
   help:argument "command"
      :description "The command to show help for."
      :args "?"
      :action(function(_, _, cmd)
         if not cmd then
            print(self:get_help())
            os.exit(0)
         else
            for _, command in ipairs(self._commands) do
               for _, alias in ipairs(command._aliases) do
                  if alias == cmd then
                     print(command:get_help())
                     os.exit(0)
                  end
               end
            end
         end
         help:error(("unknown command '%s'"):format(cmd))
      end)

   if value then
      help = help(value)
   end

   if not help._name then
      help "help"
   end

   help._is_help_command = true
   return self
end

function Parser:_is_shell_safe()
   if self._basename then
      if self._basename:find("[^%w_%-%+%.]") then
         return false
      end
   else
      for _, alias in ipairs(self._aliases) do
         if alias:find("[^%w_%-%+%.]") then
            return false
         end
      end
   end
   for _, option in ipairs(self._options) do
      for _, alias in ipairs(option._aliases) do
         if alias:find("[^%w_%-%+%.]") then
            return false
         end
      end
      if option._choices then
         for _, choice in ipairs(option._choices) do
            if choice:find("[%s'\"]") then
               return false
            end
         end
      end
   end
   for _, argument in ipairs(self._arguments) do
      if argument._choices then
         for _, choice in ipairs(argument._choices) do
            if choice:find("[%s'\"]") then
               return false
            end
         end
      end
   end
   for _, command in ipairs(self._commands) do
      if not command:_is_shell_safe() then
         return false
      end
   end
   return true
end

function Parser:add_complete(value)
   if value then
      assert(type(value) == "string" or type(value) == "table",
         ("bad argument #1 to 'add_complete' (string or table expected, got %s)"):format(type(value)))
   end

   local complete = self:option()
      :description "Output a shell completion script for the specified shell."
      :args(1)
      :choices {"bash", "zsh", "fish"}
      :action(function(_, _, shell)
         io.write(self["get_" .. shell .. "_complete"](self))
         os.exit(0)
      end)

   if value then
      complete = complete(value)
   end

   if not complete._name then
      complete "--completion"
   end

   return self
end

function Parser:add_complete_command(value)
   if value then
      assert(type(value) == "string" or type(value) == "table",
         ("bad argument #1 to 'add_complete_command' (string or table expected, got %s)"):format(type(value)))
   end

   local complete = self:command()
      :description "Output a shell completion script."
   complete:argument "shell"
      :description "The shell to output a completion script for."
      :choices {"bash", "zsh", "fish"}
      :action(function(_, _, shell)
         io.write(self["get_" .. shell .. "_complete"](self))
         os.exit(0)
      end)

   if value then
      complete = complete(value)
   end

   if not complete._name then
      complete "completion"
   end

   return self
end

local function base_name(pathname)
   return pathname:gsub("[/\\]*$", ""):match(".*[/\\]([^/\\]*)") or pathname
end

local function get_short_description(element)
   local short = element:_get_description():match("^(.-)%.%s")
   return short or element:_get_description():match("^(.-)%.?$")
end

function Parser:_get_options()
   local options = {}
   for _, option in ipairs(self._options) do
      for _, alias in ipairs(option._aliases) do
         table.insert(options, alias)
      end
   end
   return table.concat(options, " ")
end

function Parser:_get_commands()
   local commands = {}
   for _, command in ipairs(self._commands) do
      for _, alias in ipairs(command._aliases) do
         table.insert(commands, alias)
      end
   end
   return table.concat(commands, " ")
end

function Parser:_bash_option_args(buf, indent)
   local opts = {}
   for _, option in ipairs(self._options) do
      if option._choices or option._minargs > 0 then
         local compreply
         if option._choices then
            compreply = 'COMPREPLY=($(compgen -W "' .. table.concat(option._choices, " ") .. '" -- "$cur"))'
         else
            compreply = 'COMPREPLY=($(compgen -f -- "$cur"))'
         end
         table.insert(opts, (" "):rep(indent + 4) .. table.concat(option._aliases, "|") .. ")")
         table.insert(opts, (" "):rep(indent + 8) .. compreply)
         table.insert(opts, (" "):rep(indent + 8) .. "return 0")
         table.insert(opts, (" "):rep(indent + 8) .. ";;")
      end
   end

   if #opts > 0 then
      table.insert(buf, (" "):rep(indent) .. 'case "$prev" in')
      table.insert(buf, table.concat(opts, "\n"))
      table.insert(buf, (" "):rep(indent) .. "esac\n")
   end
end

function Parser:_bash_get_cmd(buf, indent)
   if #self._commands == 0 then
      return
   end

   table.insert(buf, (" "):rep(indent) .. 'args=("${args[@]:1}")')
   table.insert(buf, (" "):rep(indent) .. 'for arg in "${args[@]}"; do')
   table.insert(buf, (" "):rep(indent + 4) .. 'case "$arg" in')

   for _, command in ipairs(self._commands) do
      table.insert(buf, (" "):rep(indent + 8) .. table.concat(command._aliases, "|") .. ")")
      if self._parent then
         table.insert(buf, (" "):rep(indent + 12) .. 'cmd="$cmd ' .. command._name .. '"')
      else
         table.insert(buf, (" "):rep(indent + 12) .. 'cmd="' .. command._name .. '"')
      end
      table.insert(buf, (" "):rep(indent + 12) .. 'opts="$opts ' .. command:_get_options() .. '"')
      command:_bash_get_cmd(buf, indent + 12)
      table.insert(buf, (" "):rep(indent + 12) .. "break")
      table.insert(buf, (" "):rep(indent + 12) .. ";;")
   end

   table.insert(buf, (" "):rep(indent + 4) .. "esac")
   table.insert(buf, (" "):rep(indent) .. "done")
end

function Parser:_bash_cmd_completions(buf)
   local cmd_buf = {}
   if self._parent then
      self:_bash_option_args(cmd_buf, 12)
   end
   if #self._commands > 0 then
      table.insert(cmd_buf, (" "):rep(12) .. 'COMPREPLY=($(compgen -W "' .. self:_get_commands() .. '" -- "$cur"))')
   elseif self._is_help_command then
      table.insert(cmd_buf, (" "):rep(12)
         .. 'COMPREPLY=($(compgen -W "'
         .. self._parent:_get_commands()
         .. '" -- "$cur"))')
   end
   if #cmd_buf > 0 then
      table.insert(buf, (" "):rep(8) .. "'" .. self:_get_fullname(true) .. "')")
      table.insert(buf, table.concat(cmd_buf, "\n"))
      table.insert(buf, (" "):rep(12) .. ";;")
   end

   for _, command in ipairs(self._commands) do
      command:_bash_cmd_completions(buf)
   end
end

function Parser:get_bash_complete()
   self._basename = base_name(self._name)
   assert(self:_is_shell_safe())
   local buf = {([[
_%s() {
    local IFS=$' \t\n'
    local args cur prev cmd opts arg
    args=("${COMP_WORDS[@]}")
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="%s"
]]):format(self._basename, self:_get_options())}

   self:_bash_option_args(buf, 4)
   self:_bash_get_cmd(buf, 4)
   if #self._commands > 0 then
      table.insert(buf, "")
      table.insert(buf, (" "):rep(4) .. 'case "$cmd" in')
      self:_bash_cmd_completions(buf)
      table.insert(buf, (" "):rep(4) .. "esac\n")
   end

   table.insert(buf, ([=[
    if [[ "$cur" = -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    fi
}

complete -F _%s -o bashdefault -o default %s
]=]):format(self._basename, self._basename))

   return table.concat(buf, "\n")
end

function Parser:_zsh_arguments(buf, cmd_name, indent)
   if self._parent then
      table.insert(buf, (" "):rep(indent) .. "options=(")
      table.insert(buf, (" "):rep(indent + 2) .. "$options")
   else
      table.insert(buf, (" "):rep(indent) .. "local -a options=(")
   end

   for _, option in ipairs(self._options) do
      local line = {}
      if #option._aliases > 1 then
         if option._maxcount > 1 then
            table.insert(line, '"*"')
         end
         table.insert(line, "{" .. table.concat(option._aliases, ",") .. '}"')
      else
         table.insert(line, '"')
         if option._maxcount > 1 then
            table.insert(line, "*")
         end
         table.insert(line, option._name)
      end
      if option._description then
         local description = get_short_description(option):gsub('["%]:`$]', "\\%0")
         table.insert(line, "[" .. description .. "]")
      end
      if option._maxargs == math.huge then
         table.insert(line, ":*")
      end
      if option._choices then
         table.insert(line, ": :(" .. table.concat(option._choices, " ") .. ")")
      elseif option._maxargs > 0 then
         table.insert(line, ": :_files")
      end
      table.insert(line, '"')
      table.insert(buf, (" "):rep(indent + 2) .. table.concat(line))
   end

   table.insert(buf, (" "):rep(indent) .. ")")
   table.insert(buf, (" "):rep(indent) .. "_arguments -s -S \\")
   table.insert(buf, (" "):rep(indent + 2) .. "$options \\")

   if self._is_help_command then
      table.insert(buf, (" "):rep(indent + 2) .. '": :(' .. self._parent:_get_commands() .. ')" \\')
   else
      for _, argument in ipairs(self._arguments) do
         local spec
         if argument._choices then
            spec = ": :(" .. table.concat(argument._choices, " ") .. ")"
         else
            spec = ": :_files"
         end
         if argument._maxargs == math.huge then
            table.insert(buf, (" "):rep(indent + 2) .. '"*' .. spec .. '" \\')
            break
         end
         for _ = 1, argument._maxargs do
            table.insert(buf, (" "):rep(indent + 2) .. '"' .. spec .. '" \\')
         end
      end

      if #self._commands > 0 then
         table.insert(buf, (" "):rep(indent + 2) .. '": :_' .. cmd_name .. '_cmds" \\')
         table.insert(buf, (" "):rep(indent + 2) .. '"*:: :->args" \\')
      end
   end

   table.insert(buf, (" "):rep(indent + 2) .. "&& return 0")
end

function Parser:_zsh_cmds(buf, cmd_name)
   table.insert(buf, "\n_" .. cmd_name .. "_cmds() {")
   table.insert(buf, "  local -a commands=(")

   for _, command in ipairs(self._commands) do
      local line = {}
      if #command._aliases > 1 then
         table.insert(line, "{" .. table.concat(command._aliases, ",") .. '}"')
      else
         table.insert(line, '"' .. command._name)
      end
      if command._description then
         table.insert(line, ":" .. get_short_description(command):gsub('["`$]', "\\%0"))
      end
      table.insert(buf, "    " .. table.concat(line) .. '"')
   end

   table.insert(buf, '  )\n  _describe "command" commands\n}')
end

function Parser:_zsh_complete_help(buf, cmds_buf, cmd_name, indent)
   if #self._commands == 0 then
      return
   end

   self:_zsh_cmds(cmds_buf, cmd_name)
   table.insert(buf, "\n" .. (" "):rep(indent) .. "case $words[1] in")

   for _, command in ipairs(self._commands) do
      local name = cmd_name .. "_" .. command._name
      table.insert(buf, (" "):rep(indent + 2) .. table.concat(command._aliases, "|") .. ")")
      command:_zsh_arguments(buf, name, indent + 4)
      command:_zsh_complete_help(buf, cmds_buf, name, indent + 4)
      table.insert(buf, (" "):rep(indent + 4) .. ";;\n")
   end

   table.insert(buf, (" "):rep(indent) .. "esac")
end

function Parser:get_zsh_complete()
   self._basename = base_name(self._name)
   assert(self:_is_shell_safe())
   local buf = {("#compdef %s\n"):format(self._basename)}
   local cmds_buf = {}
   table.insert(buf, "_" .. self._basename .. "() {")
   if #self._commands > 0 then
      table.insert(buf, "  local context state state_descr line")
      table.insert(buf, "  typeset -A opt_args\n")
   end
   self:_zsh_arguments(buf, self._basename, 2)
   self:_zsh_complete_help(buf, cmds_buf, self._basename, 2)
   table.insert(buf, "\n  return 1")
   table.insert(buf, "}")

   local result = table.concat(buf, "\n")
   if #cmds_buf > 0 then
      result = result .. "\n" .. table.concat(cmds_buf, "\n")
   end
   return result .. "\n\n_" .. self._basename .. "\n"
end

local function fish_escape(string)
   return string:gsub("[\\']", "\\%0")
end

function Parser:_fish_get_cmd(buf, indent)
   if #self._commands == 0 then
      return
   end

   table.insert(buf, (" "):rep(indent) .. "set -e cmdline[1]")
   table.insert(buf, (" "):rep(indent) .. "for arg in $cmdline")
   table.insert(buf, (" "):rep(indent + 4) .. "switch $arg")

   for _, command in ipairs(self._commands) do
      table.insert(buf, (" "):rep(indent + 8) .. "case " .. table.concat(command._aliases, " "))
      table.insert(buf, (" "):rep(indent + 12) .. "set cmd $cmd " .. command._name)
      command:_fish_get_cmd(buf, indent + 12)
      table.insert(buf, (" "):rep(indent + 12) .. "break")
   end

   table.insert(buf, (" "):rep(indent + 4) .. "end")
   table.insert(buf, (" "):rep(indent) .. "end")
end

function Parser:_fish_complete_help(buf, basename)
   local prefix = "complete -c " .. basename
   table.insert(buf, "")

   for _, command in ipairs(self._commands) do
      local aliases = table.concat(command._aliases, " ")
      local line
      if self._parent then
         line = ("%s -n '__fish_%s_using_command %s' -xa '%s'")
            :format(prefix, basename, self:_get_fullname(true), aliases)
      else
         line = ("%s -n '__fish_%s_using_command' -xa '%s'"):format(prefix, basename, aliases)
      end
      if command._description then
         line = ("%s -d '%s'"):format(line, fish_escape(get_short_description(command)))
      end
      table.insert(buf, line)
   end

   if self._is_help_command then
      local line = ("%s -n '__fish_%s_using_command %s' -xa '%s'")
         :format(prefix, basename, self:_get_fullname(true), self._parent:_get_commands())
      table.insert(buf, line)
   end

   for _, option in ipairs(self._options) do
      local parts = {prefix}

      if self._parent then
         table.insert(parts, "-n '__fish_" .. basename .. "_seen_command " .. self:_get_fullname(true) .. "'")
      end

      for _, alias in ipairs(option._aliases) do
         if alias:match("^%-.$") then
            table.insert(parts, "-s " .. alias:sub(2))
         elseif alias:match("^%-%-.+") then
            table.insert(parts, "-l " .. alias:sub(3))
         end
      end

      if option._choices then
         table.insert(parts, "-xa '" .. table.concat(option._choices, " ") .. "'")
      elseif option._minargs > 0 then
         table.insert(parts, "-r")
      end

      if option._description then
         table.insert(parts, "-d '" .. fish_escape(get_short_description(option)) .. "'")
      end

      table.insert(buf, table.concat(parts, " "))
   end

   for _, command in ipairs(self._commands) do
      command:_fish_complete_help(buf, basename)
   end
end

function Parser:get_fish_complete()
   self._basename = base_name(self._name)
   assert(self:_is_shell_safe())
   local buf = {}

   if #self._commands > 0 then
      table.insert(buf, ([[
function __fish_%s_print_command
    set -l cmdline (commandline -poc)
    set -l cmd]]):format(self._basename))
      self:_fish_get_cmd(buf, 4)
      table.insert(buf, ([[
    echo "$cmd"
end

function __fish_%s_using_command
    test (__fish_%s_print_command) = "$argv"
    and return 0
    or return 1
end

function __fish_%s_seen_command
    string match -q "$argv*" (__fish_%s_print_command)
    and return 0
    or return 1
end]]):format(self._basename, self._basename, self._basename, self._basename))
   end

   self:_fish_complete_help(buf, self._basename)
   return table.concat(buf, "\n") .. "\n"
end

local function get_tip(context, wrong_name)
   local context_pool = {}
   local possible_name
   local possible_names = {}

   for name in pairs(context) do
      if type(name) == "string" then
         for i = 1, #name do
            possible_name = name:sub(1, i - 1) .. name:sub(i + 1)

            if not context_pool[possible_name] then
               context_pool[possible_name] = {}
            end

            table.insert(context_pool[possible_name], name)
         end
      end
   end

   for i = 1, #wrong_name + 1 do
      possible_name = wrong_name:sub(1, i - 1) .. wrong_name:sub(i + 1)

      if context[possible_name] then
         possible_names[possible_name] = true
      elseif context_pool[possible_name] then
         for _, name in ipairs(context_pool[possible_name]) do
            possible_names[name] = true
         end
      end
   end

   local first = next(possible_names)

   if first then
      if next(possible_names, first) then
         local possible_names_arr = {}

         for name in pairs(possible_names) do
            table.insert(possible_names_arr, "'" .. name .. "'")
         end

         table.sort(possible_names_arr)
         return "\nDid you mean one of these: " .. table.concat(possible_names_arr, " ") .. "?"
      else
         return "\nDid you mean '" .. first .. "'?"
      end
   else
      return ""
   end
end

local ElementState = class({
   invocations = 0
})

function ElementState:__call(state, element)
   self.state = state
   self.result = state.result
   self.element = element
   self.target = element._target or element:_get_default_target()
   self.action, self.result[self.target] = element:_get_action()
   return self
end

function ElementState:error(fmt, ...)
   self.state:error(fmt, ...)
end

function ElementState:convert(argument, index)
   local converter = self.element._convert

   if converter then
      local ok, err

      if type(converter) == "function" then
         ok, err = converter(argument)
      elseif type(converter[index]) == "function" then
         ok, err = converter[index](argument)
      else
         ok = converter[argument]
      end

      if ok == nil then
         self:error(err and "%s" or "malformed argument '%s'", err or argument)
      end

      argument = ok
   end

   return argument
end

function ElementState:default(mode)
   return self.element._defmode:find(mode) and self.element._default
end

local function bound(noun, min, max, is_max)
   local res = ""

   if min ~= max then
      res = "at " .. (is_max and "most" or "least") .. " "
   end

   local number = is_max and max or min
   return res .. tostring(number) .. " " .. noun ..  (number == 1 and "" or "s")
end

function ElementState:set_name(alias)
   self.name = ("%s '%s'"):format(alias and "option" or "argument", alias or self.element._name)
end

function ElementState:invoke()
   self.open = true
   self.overwrite = false

   if self.invocations >= self.element._maxcount then
      if self.element._overwrite then
         self.overwrite = true
      else
         local num_times_repr = bound("time", self.element._mincount, self.element._maxcount, true)
         self:error("%s must be used %s", self.name, num_times_repr)
      end
   else
      self.invocations = self.invocations + 1
   end

   self.args = {}

   if self.element._maxargs <= 0 then
      self:close()
   end

   return self.open
end

function ElementState:check_choices(argument)
   if self.element._choices then
      for _, choice in ipairs(self.element._choices) do
         if argument == choice then
            return
         end
      end
      local choices_list = "'" .. table.concat(self.element._choices, "', '") .. "'"
      local is_option = getmetatable(self.element) == Option
      self:error("%s%s must be one of %s", is_option and "argument for " or "", self.name, choices_list)
   end
end

function ElementState:pass(argument)
   self:check_choices(argument)
   argument = self:convert(argument, #self.args + 1)
   table.insert(self.args, argument)

   if #self.args >= self.element._maxargs then
      self:close()
   end

   return self.open
end

function ElementState:complete_invocation()
   while #self.args < self.element._minargs do
      self:pass(self.element._default)
   end
end

function ElementState:close()
   if self.open then
      self.open = false

      if #self.args < self.element._minargs then
         if self:default("a") then
            self:complete_invocation()
         else
            if #self.args == 0 then
               if getmetatable(self.element) == Argument then
                  self:error("missing %s", self.name)
               elseif self.element._maxargs == 1 then
                  self:error("%s requires an argument", self.name)
               end
            end

            self:error("%s requires %s", self.name, bound("argument", self.element._minargs, self.element._maxargs))
         end
      end

      local args

      if self.element._maxargs == 0 then
         args = self.args[1]
      elseif self.element._maxargs == 1 then
         if self.element._minargs == 0 and self.element._mincount ~= self.element._maxcount then
            args = self.args
         else
            args = self.args[1]
         end
      else
         args = self.args
      end

      self.action(self.result, self.target, args, self.overwrite)
   end
end

local ParseState = class({
   result = {},
   options = {},
   arguments = {},
   argument_i = 1,
   element_to_mutexes = {},
   mutex_to_element_state = {},
   command_actions = {}
})

function ParseState:__call(parser, error_handler)
   self.parser = parser
   self.error_handler = error_handler
   self.charset = parser:_update_charset()
   self:switch(parser)
   return self
end

function ParseState:error(fmt, ...)
   self.error_handler(self.parser, fmt:format(...))
end

function ParseState:switch(parser)
   self.parser = parser

   if parser._action then
      table.insert(self.command_actions, {action = parser._action, name = parser._name})
   end

   for _, option in ipairs(parser._options) do
      option = ElementState(self, option)
      table.insert(self.options, option)

      for _, alias in ipairs(option.element._aliases) do
         self.options[alias] = option
      end
   end

   for _, mutex in ipairs(parser._mutexes) do
      for _, element in ipairs(mutex) do
         if not self.element_to_mutexes[element] then
            self.element_to_mutexes[element] = {}
         end

         table.insert(self.element_to_mutexes[element], mutex)
      end
   end

   for _, argument in ipairs(parser._arguments) do
      argument = ElementState(self, argument)
      table.insert(self.arguments, argument)
      argument:set_name()
      argument:invoke()
   end

   self.handle_options = parser._handle_options
   self.argument = self.arguments[self.argument_i]
   self.commands = parser._commands

   for _, command in ipairs(self.commands) do
      for _, alias in ipairs(command._aliases) do
         self.commands[alias] = command
      end
   end
end

function ParseState:get_option(name)
   local option = self.options[name]

   if not option then
      self:error("unknown option '%s'%s", name, get_tip(self.options, name))
   else
      return option
   end
end

function ParseState:get_command(name)
   local command = self.commands[name]

   if not command then
      if #self.commands > 0 then
         self:error("unknown command '%s'%s", name, get_tip(self.commands, name))
      else
         self:error("too many arguments")
      end
   else
      return command
   end
end

function ParseState:check_mutexes(element_state)
   if self.element_to_mutexes[element_state.element] then
      for _, mutex in ipairs(self.element_to_mutexes[element_state.element]) do
         local used_element_state = self.mutex_to_element_state[mutex]

         if used_element_state and used_element_state ~= element_state then
            self:error("%s can not be used together with %s", element_state.name, used_element_state.name)
         else
            self.mutex_to_element_state[mutex] = element_state
         end
      end
   end
end

function ParseState:invoke(option, name)
   self:close()
   option:set_name(name)
   self:check_mutexes(option, name)

   if option:invoke() then
      self.option = option
   end
end

function ParseState:pass(arg)
   if self.option then
      if not self.option:pass(arg) then
         self.option = nil
      end
   elseif self.argument then
      self:check_mutexes(self.argument)

      if not self.argument:pass(arg) then
         self.argument_i = self.argument_i + 1
         self.argument = self.arguments[self.argument_i]
      end
   else
      local command = self:get_command(arg)
      self.result[command._target or command._name] = true

      if self.parser._command_target then
         self.result[self.parser._command_target] = command._name
      end

      self:switch(command)
   end
end

function ParseState:close()
   if self.option then
      self.option:close()
      self.option = nil
   end
end

function ParseState:finalize()
   self:close()

   for i = self.argument_i, #self.arguments do
      local argument = self.arguments[i]
      if #argument.args == 0 and argument:default("u") then
         argument:complete_invocation()
      else
         argument:close()
      end
   end

   if self.parser._require_command and #self.commands > 0 then
      self:error("a command is required")
   end

   for _, option in ipairs(self.options) do
      option.name = option.name or ("option '%s'"):format(option.element._name)

      if option.invocations == 0 then
         if option:default("u") then
            option:invoke()
            option:complete_invocation()
            option:close()
         end
      end

      local mincount = option.element._mincount

      if option.invocations < mincount then
         if option:default("a") then
            while option.invocations < mincount do
               option:invoke()
               option:close()
            end
         elseif option.invocations == 0 then
            self:error("missing %s", option.name)
         else
            self:error("%s must be used %s", option.name, bound("time", mincount, option.element._maxcount))
         end
      end
   end

   for i = #self.command_actions, 1, -1 do
      self.command_actions[i].action(self.result, self.command_actions[i].name)
   end
end

function ParseState:parse(args)
   for _, arg in ipairs(args) do
      local plain = true

      if self.handle_options then
         local first = arg:sub(1, 1)

         if self.charset[first] then
            if #arg > 1 then
               plain = false

               if arg:sub(2, 2) == first then
                  if #arg == 2 then
                     if self.options[arg] then
                        local option = self:get_option(arg)
                        self:invoke(option, arg)
                     else
                        self:close()
                     end

                     self.handle_options = false
                  else
                     local equals = arg:find "="
                     if equals then
                        local name = arg:sub(1, equals - 1)
                        local option = self:get_option(name)

                        if option.element._maxargs <= 0 then
                           self:error("option '%s' does not take arguments", name)
                        end

                        self:invoke(option, name)
                        self:pass(arg:sub(equals + 1))
                     else
                        local option = self:get_option(arg)
                        self:invoke(option, arg)
                     end
                  end
               else
                  for i = 2, #arg do
                     local name = first .. arg:sub(i, i)
                     local option = self:get_option(name)
                     self:invoke(option, name)

                     if i ~= #arg and option.element._maxargs > 0 then
                        self:pass(arg:sub(i + 1))
                        break
                     end
                  end
               end
            end
         end
      end

      if plain then
         self:pass(arg)
      end
   end

   self:finalize()
   return self.result
end

function Parser:error(msg)
   io.stderr:write(("%s\n\nError: %s\n"):format(self:get_usage(), msg))
   os.exit(1)
end

-- Compatibility with strict.lua and other checkers:
local default_cmdline = rawget(_G, "arg") or {}

function Parser:_parse(args, error_handler)
   return ParseState(self, error_handler):parse(args or default_cmdline)
end

function Parser:parse(args)
   return self:_parse(args, self.error)
end

local function xpcall_error_handler(err)
   return tostring(err) .. "\noriginal " .. debug.traceback("", 2):sub(2)
end

function Parser:pparse(args)
   local parse_error

   local ok, result = xpcall(function()
      return self:_parse(args, function(_, err)
         parse_error = err
         error(err, 0)
      end)
   end, xpcall_error_handler)

   if ok then
      return true, result
   elseif not parse_error then
      error(result, 0)
   else
      return false, parse_error
   end
end

local argparse = {}

argparse.version = "0.7.1"

setmetatable(argparse, {__call = function(_, ...)
   return Parser(default_cmdline[0]):add_help(true)(...)
end})

return argparse
]==]),
["cbor"] = lib("ext/lua/cbor/cbor.lua", [=[-- Concise Binary Object Representation (CBOR)
-- RFC 7049

local function softreq(pkg, field)
	local ok, mod = pcall(require, pkg);
	if not ok then return end
	if field then return mod[field]; end
	return mod;
end
local dostring = function(s)
	local ok, f = load(function()
		local ret = s;
		s = nil
		return ret;
	end);
	if ok and f then
		return f();
	end
end

local setmetatable = setmetatable;
local getmetatable = getmetatable;
local dbg_getmetatable = debug.getmetatable;
local assert = assert;
local error = error;
local type = type;
local pairs = pairs;
local ipairs = ipairs;
local tostring = tostring;
local s_char = string.char;
local t_concat = table.concat;
local t_sort = table.sort;
local m_floor = math.floor;
local m_abs = math.abs;
local m_huge = math.huge;
local m_max = math.max;
local maxint = math.maxinteger or 9007199254740992;
local minint = math.mininteger or -9007199254740992;
local NaN = 0/0;
local m_frexp = math.frexp;
local m_ldexp = math.ldexp or function (x, exp) return x * 2.0 ^ exp; end;
local m_type = math.type or function (n) return n % 1 == 0 and n <= maxint and n >= minint and "integer" or "float" end;
local s_pack = string.pack or softreq("struct", "pack");
local s_unpack = string.unpack or softreq("struct", "unpack");
local b_rshift = softreq("bit32", "rshift") or softreq("bit", "rshift") or
	dostring "return function(a,b) return a >> b end" or
	function (a, b) return m_max(0, m_floor(a / (2 ^ b))); end;

-- sanity check
if s_pack and s_pack(">I2", 0) ~= "\0\0" then
	s_pack = nil;
end
if s_unpack and s_unpack(">I2", "\1\2\3\4") ~= 0x102 then
	s_unpack = nil;
end

local _ENV = nil; -- luacheck: ignore 211

local encoder = {};

local function encode(obj, opts)
	return encoder[type(obj)](obj, opts);
end

-- Major types 0, 1 and length encoding for others
local function integer(num, m)
	if m == 0 and num < 0 then
		-- negative integer, major type 1
		num, m = - num - 1, 32;
	end
	if num < 24 then
		return s_char(m + num);
	elseif num < 2 ^ 8 then
		return s_char(m + 24, num);
	elseif num < 2 ^ 16 then
		return s_char(m + 25, b_rshift(num, 8), num % 0x100);
	elseif num < 2 ^ 32 then
		return s_char(m + 26,
			b_rshift(num, 24) % 0x100,
			b_rshift(num, 16) % 0x100,
			b_rshift(num, 8) % 0x100,
			num % 0x100);
	elseif num < 2 ^ 64 then
		local high = m_floor(num / 2 ^ 32);
		num = num % 2 ^ 32;
		return s_char(m + 27,
			b_rshift(high, 24) % 0x100,
			b_rshift(high, 16) % 0x100,
			b_rshift(high, 8) % 0x100,
			high % 0x100,
			b_rshift(num, 24) % 0x100,
			b_rshift(num, 16) % 0x100,
			b_rshift(num, 8) % 0x100,
			num % 0x100);
	end
	error "int too large";
end

if s_pack then
	function integer(num, m)
		local fmt;
		m = m or 0;
		if num < 24 then
			fmt, m = ">B", m + num;
		elseif num < 256 then
			fmt, m = ">BB", m + 24;
		elseif num < 65536 then
			fmt, m = ">BI2", m + 25;
		elseif num < 4294967296 then
			fmt, m = ">BI4", m + 26;
		else
			fmt, m = ">BI8", m + 27;
		end
		return s_pack(fmt, m, num);
	end
end

local simple_mt = {};
function simple_mt:__tostring() return self.name or ("simple(%d)"):format(self.value); end
function simple_mt:__tocbor() return self.cbor or integer(self.value, 224); end

local function simple(value, name, cbor)
	assert(value >= 0 and value <= 255, "bad argument #1 to 'simple' (integer in range 0..255 expected)");
	return setmetatable({ value = value, name = name, cbor = cbor }, simple_mt);
end

local tagged_mt = {};
function tagged_mt:__tostring() return ("%d(%s)"):format(self.tag, tostring(self.value)); end
function tagged_mt:__tocbor() return integer(self.tag, 192) .. encode(self.value); end

local function tagged(tag, value)
	assert(tag >= 0, "bad argument #1 to 'tagged' (positive integer expected)");
	return setmetatable({ tag = tag, value = value }, tagged_mt);
end

local null = simple(22, "null"); -- explicit null
local undefined = simple(23, "undefined"); -- undefined or nil
local BREAK = simple(31, "break", "\255");

-- Number types dispatch
function encoder.number(num)
	return encoder[m_type(num)](num);
end

-- Major types 0, 1
function encoder.integer(num)
	if num < 0 then
		return integer(-1 - num, 32);
	end
	return integer(num, 0);
end

-- Major type 7
function encoder.float(num)
	if num ~= num then -- NaN shortcut
		return "\251\127\255\255\255\255\255\255\255";
	end
	local sign = (num > 0 or 1 / num > 0) and 0 or 1;
	num = m_abs(num)
	if num == m_huge then
		return s_char(251, sign * 128 + 128 - 1) .. "\240\0\0\0\0\0\0";
	end
	local fraction, exponent = m_frexp(num)
	if fraction == 0 then
		return s_char(251, sign * 128) .. "\0\0\0\0\0\0\0";
	end
	fraction = fraction * 2;
	exponent = exponent + 1024 - 2;
	if exponent <= 0 then
		fraction = fraction * 2 ^ (exponent - 1)
		exponent = 0;
	else
		fraction = fraction - 1;
	end
	return s_char(251,
		sign * 2 ^ 7 + m_floor(exponent / 2 ^ 4) % 2 ^ 7,
		exponent % 2 ^ 4 * 2 ^ 4 +
		m_floor(fraction * 2 ^ 4 % 0x100),
		m_floor(fraction * 2 ^ 12 % 0x100),
		m_floor(fraction * 2 ^ 20 % 0x100),
		m_floor(fraction * 2 ^ 28 % 0x100),
		m_floor(fraction * 2 ^ 36 % 0x100),
		m_floor(fraction * 2 ^ 44 % 0x100),
		m_floor(fraction * 2 ^ 52 % 0x100)
	)
end

if s_pack then
	function encoder.float(num)
		return s_pack(">Bd", 251, num);
	end
end


-- Major type 2 - byte strings
function encoder.bytestring(s)
	return integer(#s, 64) .. s;
end

-- Major type 3 - UTF-8 strings
function encoder.utf8string(s)
	return integer(#s, 96) .. s;
end

-- Lua strings are byte strings
encoder.string = encoder.bytestring;

function encoder.boolean(bool)
	return bool and "\245" or "\244";
end

encoder["nil"] = function() return "\246"; end

function encoder.userdata(ud, opts)
	local mt = dbg_getmetatable(ud);
	if mt then
		local encode_ud = opts and opts[mt] or mt.__tocbor;
		if encode_ud then
			return encode_ud(ud, opts);
		end
	end
	error "can't encode userdata";
end

function encoder.table(t, opts)
	local mt = getmetatable(t);
	if mt then
		local encode_t = opts and opts[mt] or mt.__tocbor;
		if encode_t then
			return encode_t(t, opts);
		end
	end
	-- the table is encoded as an array iff when we iterate over it,
	-- we see successive integer keys starting from 1.  The lua
	-- language doesn't actually guarantee that this will be the case
	-- when we iterate over a table with successive integer keys, but
	-- due an implementation detail in PUC Rio Lua, this is what we
	-- usually observe.  See the Lua manual regarding the # (length)
	-- operator.  In the case that this does not happen, we will fall
	-- back to a map with integer keys, which becomes a bit larger.
	local array, map, i, p = { integer(#t, 128) }, { "\191" }, 1, 2;
	local is_array = true;
	for k, v in pairs(t) do
		is_array = is_array and i == k;
		i = i + 1;

		local encoded_v = encode(v, opts);
		array[i] = encoded_v;

		map[p], p = encode(k, opts), p + 1;
		map[p], p = encoded_v, p + 1;
	end
	-- map[p] = "\255";
	map[1] = integer(i - 1, 160);
	return t_concat(is_array and array or map);
end

-- Array or dict-only encoders, which can be set as __tocbor metamethod
function encoder.array(t, opts)
	local array = { };
	for i, v in ipairs(t) do
		array[i] = encode(v, opts);
	end
	return integer(#array, 128) .. t_concat(array);
end

function encoder.map(t, opts)
	local map, p, len = { "\191" }, 2, 0;
	for k, v in pairs(t) do
		map[p], p = encode(k, opts), p + 1;
		map[p], p = encode(v, opts), p + 1;
		len = len + 1;
	end
	-- map[p] = "\255";
	map[1] = integer(len, 160);
	return t_concat(map);
end
encoder.dict = encoder.map; -- COMPAT

function encoder.ordered_map(t, opts)
	local map = {};
	if not t[1] then -- no predefined order
		local i = 0;
		for k in pairs(t) do
			i = i + 1;
			map[i] = k;
		end
		t_sort(map);
	end
	for i, k in ipairs(t[1] and t or map) do
		map[i] = encode(k, opts) .. encode(t[k], opts);
	end
	return integer(#map, 160) .. t_concat(map);
end

encoder["function"] = function ()
	error "can't encode function";
end

-- Decoder
-- Reads from a file-handle like object
local function read_bytes(fh, len)
	return fh:read(len);
end

local function read_byte(fh)
	return fh:read(1):byte();
end

local function read_length(fh, mintyp)
	if mintyp < 24 then
		return mintyp;
	elseif mintyp < 28 then
		local out = 0;
		for _ = 1, 2 ^ (mintyp - 24) do
			out = out * 256 + read_byte(fh);
		end
		return out;
	else
		error "invalid length";
	end
end

local decoder = {};

local function read_type(fh)
	local byte = read_byte(fh);
	return b_rshift(byte, 5), byte % 32;
end

local function read_object(fh, opts)
	local typ, mintyp = read_type(fh);
	return decoder[typ](fh, mintyp, opts);
end

local function read_integer(fh, mintyp)
	return read_length(fh, mintyp);
end

local function read_negative_integer(fh, mintyp)
	return -1 - read_length(fh, mintyp);
end

local function read_string(fh, mintyp)
	if mintyp ~= 31 then
		return read_bytes(fh, read_length(fh, mintyp));
	end
	local out = {};
	local i = 1;
	local v = read_object(fh);
	while v ~= BREAK do
		out[i], i = v, i + 1;
		v = read_object(fh);
	end
	return t_concat(out);
end

local function read_unicode_string(fh, mintyp)
	return read_string(fh, mintyp);
	-- local str = read_string(fh, mintyp);
	-- if have_utf8 and not utf8.len(str) then
		-- TODO How to handle this?
	-- end
	-- return str;
end

local function read_array(fh, mintyp, opts)
	local out = {};
	if mintyp == 31 then
		local i = 1;
		local v = read_object(fh, opts);
		while v ~= BREAK do
			out[i], i = v, i + 1;
			v = read_object(fh, opts);
		end
	else
		local len = read_length(fh, mintyp);
		for i = 1, len do
			out[i] = read_object(fh, opts);
		end
	end
	return out;
end

local function read_map(fh, mintyp, opts)
	local out = {};
	local k;
	if mintyp == 31 then
		local i = 1;
		k = read_object(fh, opts);
		while k ~= BREAK do
			out[k], i = read_object(fh, opts), i + 1;
			k = read_object(fh, opts);
		end
	else
		local len = read_length(fh, mintyp);
		for _ = 1, len do
			k = read_object(fh, opts);
			out[k] = read_object(fh, opts);
		end
	end
	return out;
end

local tagged_decoders = {};

local function read_semantic(fh, mintyp, opts)
	local tag = read_length(fh, mintyp);
	local value = read_object(fh, opts);
	local postproc = opts and opts[tag] or tagged_decoders[tag];
	if postproc then
		return postproc(value);
	end
	return tagged(tag, value);
end

local function read_half_float(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit

	fraction = fraction + (exponent * 256) % 1024; -- copy two(?) bits from exponent to fraction
	exponent = b_rshift(exponent, 2) % 32; -- remove sign bit and two low bits from fraction;

	if exponent == 0 then
		return sign * m_ldexp(fraction, -24);
	elseif exponent ~= 31 then
		return sign * m_ldexp(fraction + 1024, exponent - 25);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return NaN;
	end
end

local function read_float(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit
	exponent = exponent * 2 % 256 + b_rshift(fraction, 7);
	fraction = fraction % 128;
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);

	if exponent == 0 then
		return sign * m_ldexp(exponent, -149);
	elseif exponent ~= 0xff then
		return sign * m_ldexp(fraction + 2 ^ 23, exponent - 150);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return NaN;
	end
end

local function read_double(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit

	exponent = exponent %  128 * 16 + b_rshift(fraction, 4);
	fraction = fraction % 16;
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);

	if exponent == 0 then
		return sign * m_ldexp(exponent, -149);
	elseif exponent ~= 0xff then
		return sign * m_ldexp(fraction + 2 ^ 52, exponent - 1075);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return NaN;
	end
end


if s_unpack then
	function read_float(fh) return s_unpack(">f", read_bytes(fh, 4)) end
	function read_double(fh) return s_unpack(">d", read_bytes(fh, 8)) end
end

local function read_simple(fh, value, opts)
	if value == 24 then
		value = read_byte(fh);
	end
	if value == 20 then
		return false;
	elseif value == 21 then
		return true;
	elseif value == 22 then
		return null;
	elseif value == 23 then
		return undefined;
	elseif value == 25 then
		return read_half_float(fh);
	elseif value == 26 then
		return read_float(fh);
	elseif value == 27 then
		return read_double(fh);
	elseif value == 31 then
		return BREAK;
	end
	if opts and opts.simple then
		return opts.simple(value);
	end
	return simple(value);
end

decoder[0] = read_integer;
decoder[1] = read_negative_integer;
decoder[2] = read_string;
decoder[3] = read_unicode_string;
decoder[4] = read_array;
decoder[5] = read_map;
decoder[6] = read_semantic;
decoder[7] = read_simple;

-- opts.more(n) -> want more data
-- opts.simple -> decode simple value
-- opts[int] -> tagged decoder
local function decode(s, opts)
	local fh = {};
	local pos = 1;

	local more;
	if type(opts) == "function" then
		more = opts;
	elseif type(opts) == "table" then
		more = opts.more;
	elseif opts ~= nil then
		error(("bad argument #2 to 'decode' (function or table expected, got %s)"):format(type(opts)));
	end
	if type(more) ~= "function" then
		function more()
			error "input too short";
		end
	end

	function fh:read(bytes)
		local ret = s:sub(pos, pos + bytes - 1);
		if #ret < bytes then
			ret = more(bytes - #ret, fh, opts);
			if ret then self:write(ret); end
			return self:read(bytes);
		end
		pos = pos + bytes;
		return ret;
	end

	function fh:write(bytes) -- luacheck: no self
		s = s .. bytes;
		if pos > 256 then
			s = s:sub(pos + 1);
			pos = 1;
		end
		return #bytes;
	end

	return read_object(fh, opts);
end

return {
	-- en-/decoder functions
	encode = encode;
	decode = decode;
	decode_file = read_object;

	-- tables of per-type en-/decoders
	type_encoders = encoder;
	type_decoders = decoder;

	-- special treatment for tagged values
	tagged_decoders = tagged_decoders;

	-- constructors for annotated types
	simple = simple;
	tagged = tagged;

	-- pre-defined simple values
	null = null;
	undefined = undefined;
};
--@LIB
]=]),
["inspect"] = lib("ext/lua/inspect/inspect.lua", [=[local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local inspect = {Options = {}, }

















inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
inspect.KEY = setmetatable({}, { __tostring = function() return 'inspect.KEY' end })
inspect.METATABLE = setmetatable({}, { __tostring = function() return 'inspect.METATABLE' end })

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

local _rawget
if rawget then
   _rawget = rawget
else
   _rawget = function(t, k) return t[k] end
end

local function rawpairs(t)
   return next, t, nil
end



local function smartQuote(str)
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end


local shortControlCharEscapes = {
   ["\a"] = "\\a", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r", ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes = { ["\127"] = "\127" }
for i = 0, 31 do
   local ch = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\" .. i
      longControlCharEscapes[ch] = fmt("\\%03d", i)
   end
end

local function escape(str)
   return (gsub(gsub(gsub(str, "\\", "\\\\"),
   "(%c)%f[0-9]", longControlCharEscapes),
   "%c", shortControlCharEscapes))
end

local luaKeywords = {
   ['and'] = true,
   ['break'] = true,
   ['do'] = true,
   ['else'] = true,
   ['elseif'] = true,
   ['end'] = true,
   ['false'] = true,
   ['for'] = true,
   ['function'] = true,
   ['goto'] = true,
   ['if'] = true,
   ['in'] = true,
   ['local'] = true,
   ['nil'] = true,
   ['not'] = true,
   ['or'] = true,
   ['repeat'] = true,
   ['return'] = true,
   ['then'] = true,
   ['true'] = true,
   ['until'] = true,
   ['while'] = true,
}

local function isIdentifier(str)
   return type(str) == "string" and
   not not str:match("^[_%a][_%a%d]*$") and
   not luaKeywords[str]
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
   return type(k) == "number" and
   flr(k) == k and
   1 <= (k) and
   k <= sequenceLength
end

local defaultTypeOrders = {
   ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

local function sortKeys(a, b)
   local ta, tb = type(a), type(b)


   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a) < (b)
   end

   local dta = defaultTypeOrders[ta] or 100
   local dtb = defaultTypeOrders[tb] or 100


   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)

   local seqLen = 1
   while _rawget(t, seqLen) ~= nil do
      seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countCycles(x, cycles)
   if type(x) == "table" then
      if cycles[x] then
         cycles[x] = cycles[x] + 1
      else
         cycles[x] = 1
         for k, v in rawpairs(x) do
            countCycles(k, cycles)
            countCycles(v, cycles)
         end
         countCycles(getmetatable(x), cycles)
      end
   end
end

local function makePath(path, a, b)
   local newPath = {}
   local len = #path
   for i = 1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process,
   item,
   path,
   visited)
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed = process(item, path)
   if type(processed) == "table" then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k, v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end
      setmetatable(processedCopy, mt)
      processed = processedCopy
   end
   return processed
end

local function puts(buf, str)
   buf.n = buf.n + 1
   buf[buf.n] = str
end



local Inspector = {}










local Inspector_mt = { __index = Inspector }

local function tabify(inspector)
   puts(inspector.buf, inspector.newline .. rep(inspector.indent, inspector.level))
end

function Inspector:getId(v)
   local id = self.ids[v]
   local ids = self.ids
   if not id then
      local tv = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

function Inspector:putValue(v)
   local buf = self.buf
   local tv = type(v)
   if tv == 'string' then
      puts(buf, smartQuote(escape(v)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
      tv == 'cdata' or tv == 'ctype' then
      puts(buf, tostring(v))
   elseif tv == 'table' and not self.ids[v] then
      local t = v

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(buf, tostring(t))
      elseif self.level >= self.depth then
         puts(buf, '{...}')
      else
         if self.cycles[t] > 1 then puts(buf, fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts(buf, '{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(buf, ',') end
            if i <= seqLen then
               puts(buf, ' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               tabify(self)
               if isIdentifier(k) then
                  puts(buf, k)
               else
                  puts(buf, "[")
                  self:putValue(k)
                  puts(buf, "]")
               end
               puts(buf, ' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
            if seqLen + keysLen > 0 then puts(buf, ',') end
            tabify(self)
            puts(buf, '<metatable> = ')
            self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then
            tabify(self)
         elseif seqLen > 0 then
            puts(buf, ' ')
         end

         puts(buf, '}')
      end

   else
      puts(buf, fmt('<%s %d>', tv, self:getId(v)))
   end
end




function inspect.inspect(root, options)
   options = options or {}

   local depth = options.depth or (math.huge)
   local newline = options.newline or '\n'
   local indent = options.indent or '  '
   local process = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local cycles = {}
   countCycles(root, cycles)

   local inspector = setmetatable({
      buf = { n = 0 },
      ids = {},
      cycles = cycles,
      depth = depth,
      level = 0,
      newline = newline,
      indent = indent,
   }, Inspector_mt)

   inspector:putValue(root)

   return table.concat(inspector.buf)
end

setmetatable(inspect, {
   __call = function(_, root, options)
      return inspect.inspect(root, options)
   end,
})

return inspect
--@LIB
]=]),
["json"] = lib("ext/lua/json/json.lua", [=[--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json
]=]),
["serpent"] = lib("ext/lua/serpent/serpent.lua", [=[local n, v = "serpent", "0.303" -- (C) 2012-18 Paul Kulchenko; MIT License
local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
local badtype = {thread = true, userdata = true, cdata = true}
local getmetatable = debug and debug.getmetatable or getmetatable
local pairs = function(t) return next, t end -- avoid using __pairs in Lua 5.2+
local keyword, globals, G = {}, {}, (_G or _ENV)
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g..'.'..k end end

local function s(t, opts)
  local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
  local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
  local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
  local maxlen, metatostring = tonumber(opts.maxlength), opts.metatostring
  local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
  local numformat = opts.numformat or "%.17g"
  local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
  local function gensym(val) return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
    -- tostring(val) is needed because __tostring may return a non-string value
    function(s) if not syms[s] then symn = symn+1; syms[s] = symn end return tostring(syms[s]) end)) end
  local function safestr(s) return type(s) == "number" and (huge and snum[tostring(s)] or numformat:format(s))
    or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
    or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
  -- handle radix changes in some locales
  if opts.fixradix and (".1f"):format(1.2) ~= "1.2" then
    local origsafestr = safestr
    safestr = function(s) return type(s) == "number"
      and (nohuge and snum[tostring(s)] or numformat:format(s):gsub(",",".")) or origsafestr(s)
    end
  end
  local function comment(s,l) return comm and (l or 0) < comm and ' --[['..select(2, pcall(tostring, s))..']]' or '' end
  local function globerr(s,l) return globals[s] and globals[s]..comment(s,l) or not fatal
    and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s)) end
  local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
    local n = name == nil and '' or name
    local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
    local safe = plain and n or '['..safestr(n)..']'
    return (path or '')..(plain and path and '.' or '')..safe, safe end
  local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n) -- k=keys, o=originaltable, n=padding
    local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
    local function padnum(d) return ("%0"..tostring(maxn).."d"):format(tonumber(d)) end
    table.sort(k, function(a,b)
      -- sort numeric keys first: k[key] is not nil for numerical keys
      return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
           < (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum)) end) end
  local function val2str(t, name, indent, insref, path, plainindex, level)
    local ttype, level, mt = type(t), (level or 0), getmetatable(t)
    local spath, sname = safename(path, name)
    local tag = plainindex and
      ((type(name) == "number") and '' or name..space..'='..space) or
      (name ~= nil and sname..space..'='..space or '')
    if seen[t] then -- already seen this element
      sref[#sref+1] = spath..space..'='..space..seen[t]
      return tag..'nil'..comment('ref', level)
    end
    -- protect from those cases where __tostring may fail
    if type(mt) == 'table' and metatostring ~= false then
      local to, tr = pcall(function() return mt.__tostring(t) end)
      local so, sr = pcall(function() return mt.__serialize(t) end)
      if (to or so) then -- knows how to serialize itself
        seen[t] = insref or spath
        t = so and sr or tr
        ttype = type(t)
      end -- new value falls through to be serialized
    end
    if ttype == "table" then
      if level >= maxl then return tag..'{}'..comment('maxlvl', level) end
      seen[t] = insref or spath
      if next(t) == nil then return tag..'{}'..comment(t, level) end -- table empty
      if maxlen and maxlen < 0 then return tag..'{}'..comment('maxlen', level) end
      local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
      for key = 1, maxn do o[key] = key end
      if not maxnum or #o < maxnum then
        local n = #o -- n = n + 1; o[n] is much faster than o[#o+1] on large tables
        for key in pairs(t) do
          if o[key] ~= key then n = n + 1; o[n] = key end
        end
      end
      if maxnum and #o > maxnum then o[maxnum+1] = nil end
      if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
      local sparse = sparse and #o > maxn -- disable sparsness if only numeric keys (shorter output)
      for n, key in ipairs(o) do
        local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
        if opts.valignore and opts.valignore[value] -- skip ignored values; do nothing
        or opts.keyallow and not opts.keyallow[key]
        or opts.keyignore and opts.keyignore[key]
        or opts.valtypeignore and opts.valtypeignore[type(value)] -- skipping ignored value types
        or sparse and value == nil then -- skipping nils; do nothing
        elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
          if not seen[key] and not globals[key] then
            sref[#sref+1] = 'placeholder'
            local sname = safename(iname, gensym(key)) -- iname is table for local variables
            sref[#sref] = val2str(key,sname,indent,sname,iname,true)
          end
          sref[#sref+1] = 'placeholder'
          local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
          sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
        else
          out[#out+1] = val2str(value,key,indent,nil,seen[t],plainindex,level+1)
          if maxlen then
            maxlen = maxlen - #out[#out]
            if maxlen < 0 then break end
          end
        end
      end
      local prefix = string.rep(indent or '', level)
      local head = indent and '{\n'..prefix..indent or '{'
      local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
      local tail = indent and "\n"..prefix..'}' or '}'
      return (custom and custom(tag,head,body,tail,level) or tag..head..body..tail)..comment(t, level)
    elseif badtype[ttype] then
      seen[t] = insref or spath
      return tag..globerr(t, level)
    elseif ttype == 'function' then
      seen[t] = insref or spath
      if opts.nocode then return tag.."function() --[[..skipped..]] end"..comment(t, level) end
      local ok, res = pcall(string.dump, t)
      local func = ok and "(load("..safestr(res)..",'@serialized'))"..comment(t, level)
      return tag..(func or globerr(t, level))
    else return tag..safestr(t) end -- handle all other types
  end
  local sepr = indent and "\n" or ";"..space
  local body = val2str(t, name, indent) -- this call also populates sref
  local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
  local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
  return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
end

local function deserialize(data, opts)
  local env = (opts and opts.safe == false) and G
    or setmetatable({}, {
        __index = function(t,k) return t end,
        __call = function(t,...) error("cannot call functions") end
      })
  local f, res = load('return '..data, nil, nil, env)
  if not f then f, res = load(data, nil, nil, env) end
  if not f then return f, res end
  return pcall(f)
end

local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
return { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v, serialize = s,
  load = deserialize,
  dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
  line = function(a, opts) return s(a, merge({sortkeys = true, comment = true}, opts)) end,
  block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = true}, opts)) end }
--@LIB
]=]),
}
table.insert(package.searchers, 2, function(name) return libs[name] end)
require "F"
require "crypt"
require "fs"
require "lz4"
require "lzw"
require "package_hook"
]===]),
["atexit"] = lib("atexit.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `atexit(func)`: execute `func` when the whole output is computed, before actually writing the output.
@@@]]

local _functions = {}

return setmetatable({}, {
    __call = function(_, func)
        table.insert(_functions, func)
    end,
    __index = {
        run = function(_)
            while #_functions > 0 do
                table.remove(_functions, #_functions)()
            end
        end,
    },
})
]=]),
["comment"] = lib("comment.lua", [====[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `comment(...)`: returns an empty string (useful for commenting some text)

E.g.:

?(false)
```
@comment [===[
This paragraph is a comment
and is not part of the output document.
]===]
```
?(true)
@@@]]

local F = require "F"

return F.const ""
]====]),
["convert"] = lib("convert.lua", [====[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

local flex = require "flex"

--[[@@@
* `convert(s, [opts])`:
  convert the string `s` from the format `opts.from` to the format `opts.to` and shifts the header levels by `opts.shift`.

This function requires a Pandoc Lua interpreter. The conversion is made by [Pandoc] itself.

The `opts` parameter is optional.
By default Pandoc converts documents from and to Markdown and the header level is not modified.

?(false)
The `convert` macro can also be called as a curried function (arguments can be swapped). E.g.:

    @convert {from="csv"} (script.python [===[
    # python script that produces a CVS document
    ]===])

Notice that `convert` can be implicitely called by `include` or `script` by giving the appropriate options. E.g.:

    @script.python {from="csv"} [===[
    # python script that produces a CVS document
    ]===]

?(true)
@@@]]

local convert = flex.str(function(content, opts)
    assert(pandoc, "The convert macro requires a Pandoc Lua interpreter")
    opts = opts or {}
    local doc = pandoc.read(tostring(content), opts.from)
    local div = pandoc.Div(doc.blocks)
    if opts.shift then
        div = pandoc.walk_block(div, {
            Header = function(h)
                h = h:clone()
                h.level = h.level + opts.shift
                return h
            end,
        })
    end
    return pandoc.write(pandoc.Pandoc(div.content), opts.to)
end)

local convert_if_required = function(content, opts)
    opts = opts or {}
    content = tostring(content)
    if opts.from or opts.to or opts.shift then
        content = tostring(convert(content)(opts))
    end
    return content
end

return setmetatable({}, {
    __call = function(_, ...) return convert(...) end,
    __index = {
        if_required = convert_if_required
    },
})
]====]),
["doc"] = lib("doc.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

local F = require "F"
local flex = require "flex"
local convert = require "convert"

--[[@@@
* `doc(filename, [opts])`: extract documentation fragments from the file `filename` (all fragments are concatenated).

    - `opts.pattern` is the Lua pattern used to identify the documentation fragments. The default pattern is `@("@".."@@(.-)@@".."@")`.
    - `opts.from` is the format of the documentation fragments (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.to` is the destination format of the documentation (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.shift` is the offset applied to the header levels. The default offset is `0`.

?(false)
The `doc` macro can also be called as a curried function (arguments can be swapped). E.g.:

    @doc "file.c" {pattern="///(.-)///"}

?(true)
@@@]]

local default_pattern = ("@"):rep(3).."(.-)"..("@"):rep(3)

return flex.str(function(filename, opts)
    opts = opts or {}
    local pattern = opts.pattern or default_pattern
    local content = ypp.with_inputfile(filename, function(full_filepath)
        local s = ypp.read_file(full_filepath)
        local output = F{}
        s:gsub(pattern, function(doc)
            output[#output+1] = ypp(doc)
        end)
        return output:unlines()
    end)
    content = convert.if_required(content, opts)
    return content
end)
]=]),
["file"] = lib("file.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `f = file(name)`: return a file object that can be used to create files incrementally.
  Files are only saved once ypp succeed
* `f(s)`: add `s` to the file
* `f:ypp(s)`: preprocess and add `s` to the file
@@@]]

local F = require "F"

local file = {}
local file_mt = {__index={}}
local file_object_mt = {__index={}}

local outputs = F{}
file_mt.__index.outputs = outputs

local files = F{}
file_mt.__index.files = files

function file_mt:__call(name)
    outputs[#outputs+1] = name
    local f = setmetatable(F{name=name}, file_object_mt)
    files[#files+1] = f
    return f
end

function file_object_mt:__call(...)
    self[#self+1] = F.flatten{...}
end

function file_object_mt.__index:ypp(...)
    self[#self+1] = F.flatten{...}:map(ypp)
end

function file_object_mt.__index:flush()
    fs.mkdirs(self.name:dirname())
    fs.write(self.name, F.flatten(self):str())
end

return setmetatable(file, file_mt)
]=]),
["flex"] = lib("flex.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LIB

local F = require "F"

-- A flex function is a curried function with a variable number of parameters.
-- It is implemented with a callable table.
-- The actual value is computed when evaluated as a string.
-- It takes several arguments:
--      - exactly one string (the argument)
--      - zero or many option tables (they are all merged until tostring is called)

-- e.g.:
--      function f(s, opt)
--          ...
--      end
--
--      g = flex(f)
--
--      g "foo" {x=1}       => calls f("foo", {x=1})
--      g {y=2} "foo" {x=1} => calls f("foo", {x=1, y=2})
--
--      h = g{z=3} -- kind of "partial application"
--
--      h "foo"             => calls f("foo", {z=3})
--      h "foo" {x=1}       => calls f("foo", {x=1, z=3})

local flex_str_mt = {}

function flex_str_mt:__call(x)
    local xmt = getmetatable(x)
    if type(x) ~= "table" or (xmt and xmt.__tostring) then
        -- called with a string or a table with a __tostring metamethod
        -- ==> store the string
        assert(self.s == F.Nil, "Multiple argument")
        return setmetatable({s=tostring(x), opt=self.opt, f=self.f}, flex_str_mt)
    else
        -- called with an option table
        -- ==> add the new options to the current ones
        return setmetatable({s=self.s, opt=self.opt:patch(x), f=self.f}, flex_str_mt)
    end
end

function flex_str_mt:__tostring()
    -- string value requested
    -- convert to string and call f on this string
    assert(self.s ~= F.Nil, "Missing argument")
    return tostring(self.f(tostring(self.s), self.opt))
end

function flex_str_mt:__index(k)
    -- string method requested but the object is not a string yet
    -- ==> make a string proxy
    if string[k] then
        return function(s, ...)
            return string[k](tostring(s), ...)
        end
    end
end

local function flex_str(f)
    return setmetatable({s=F.Nil, opt=F{}, f=f}, flex_str_mt)
end

-- flex_array is similar to flex_str but cumulates any number of parameters in an array

local flex_array_mt = {}

function flex_array_mt:__call(x)
    local xmt = getmetatable(x)
    if type(x) ~= "table" or (xmt and xmt.__tostring) then
        -- called with a string or a table with a __tostring metamethod
        -- ==> store the string
        return setmetatable({xs=self.xs..{x}, opt=self.opt, f=self.f}, flex_array_mt)
    else
        -- called with an option table
        -- ==> add the new options to the current ones
        return setmetatable({xs=self.xs, opt=self.opt:patch(x), f=self.f}, flex_array_mt)
    end
end

function flex_array_mt:__tostring()
    -- string value requested
    -- convert the result of f to a string
    return tostring(f(self.xs, self.opt))
end

local function flex_array(f)
    return setmetatable({xs=F{}, opt=F{}, f=f}, flex_array_mt)
end

return {
    str = flex_str,
    array = flex_array,
}
]=]),
["image"] = lib("image.lua", [====[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `image(render, ext)(source)`: use the command `render` to produce an image from the source `source` with the format `ext` (`"svg"`, `"png"` or `"pdf"`).
  `image` returns the name of the image (e.g. to point to the image once deployed) and the actual file path (e.g. to embed the image in the final document).

The `render` parameter is a string that defines the command to execute to generate the image.
It contains some parameters:

- `%i` is replaced by the name of the input document (temporary file containing `source`).
- `%o` is replaced by the name of the output image file (generated from a hash of `source`).

Images are generated in a directory given by:

- the environment variable `YPP_IMG` if it is defined
- the directory name of the output file if the `-o` option is given
- the `img` directory in the current directory

If `source` starts with a `@` (e.g. `@q'"@filename"'`) then the actual image source is read from the file `filename`.

The image link in the output document may have to be different than the
actual path in the file system. This happens when the documents are not
generated in the same path than the source document. Brackets can be used to
specify the part of the path that belongs to the generated image but not to the
link in the output document in `YPP_IMG`.
E.g. if `YPP_IMG=[prefix]path` then images will be generated in `prefix/path`
and the link used in the output document will be `path`.

The file format (extension) must be in `render`, after the `%o` tag (e.g.: `%o.png`).

If the program requires a specific input file extension, it can be specified in `render`,
after the `%i` tag (e.g.: `%i.xyz`).

Some render commands are predefined.
For each render `X` (which produces images in the default format)
there are 3 other render commands `X.svg`, `X.png` and `X.pdf` which explicitely specify the image format.
They can be used similaryly to `image`: `X(source)`.

An optional table can be given before `source` to set some options:

* `X {name="output_name"} (source)` renders `source` and save the image to a file named `output_name`.
  This can help distributing documents with user friendly image names.

* `X {pp=func} (source)` renders `func(source)` instead of `source`.
  E.g.: if `func` is `ypp` then `source` is preprocessed by `ypp` before being rendered.

@@[===[
    local engine = {
        circo = "Graphviz",
        dot = "Graphviz",
        fdp = "Graphviz",
        neato = "Graphviz",
        osage = "Graphviz",
        patchwork = "Graphviz",
        sfdp = "Graphviz",
        twopi = "Graphviz",
        actdiag = "Blockdiag",
        blockdiag = "Blockdiag",
        nwdiag = "Blockdiag",
        packetdiag = "Blockdiag",
        rackdiag = "Blockdiag",
        seqdiag = "Blockdiag",
        mmdc = "Mermaid",
        asy = "Asymptote",
        plantuml = "PlantUML",
        ditaa = "ditaa",
        gnuplot = "gnuplot",
        lsvg = "lsvg",
        octave = "octave",
    }
    local function cmp(x, y)
        assert(engine[x], x.." engine unknown")
        assert(engine[y], y.." engine unknown")
        if engine[x] == engine[y] then return x < y end
        return engine[x] < engine[y]
    end
    return F{
        "Image engine | ypp function | Example",
        "-------------|--------------|--------",
    }
    ..
    F.keys(image):sort(cmp):map(function(x)
        return ("[%s] | `%s` | `image.%s(source)`"):format(engine[x], x, x)
    end)
]===]

Example:

?(false)
``` markdown
![ypp image generation example](@image.dot [===[
digraph {
    rankdir=LR;
    input -> ypp -> output
    ypp -> image
}
]===])
```
?(true)

is rendered as

![ypp image generation example](@image.dot {name="image"} [===[
digraph {
    rankdir=LR;
    input -> ypp -> output
    ypp -> image
}
]===])

@@@]]

local F = require "F"
local fs = require "fs"
local sh = require "sh"

local output_path   -- actual directory where images are saved
local link_path     -- directory added to image filenames

local function parse_output_path(path)
    local prefix, link = path : match "^%[(.-)%](.*)"
    if prefix then
        output_path = fs.join(prefix, link)
        link_path = link
    else
        output_path = path
        link_path = path
    end
end

local function get_input_ext(s)
    return s:match("%%i(%.%w+)") or ""
end

local function get_ext(s, t)
    return s:match("%%o(%.%w+)") or t:match("%%o(%.%w+)") or ""
end

local function make_diagram_cmd(src, out, render)
    return render:gsub("%%i", src):gsub("%%o", out)
end

local function render_diagram(cmd)
    -- stdout shall be discarded otherwise ypp can not be used in a pipe
    assert(sh.read(cmd), "Diagram error")
end

local output_file -- filename given by the -o option

local function default_image_output()
    if not output_path then
        local env = os.getenv "YPP_IMG"
        parse_output_path(
            (env and env ~= "" and env)
            or (output_file and fs.join(fs.dirname(output_file), "img"))
            or "img")
    end
end

local function diagram(exe, render, default_ext)
    local template
    if type(render) == "table" then
        render, template = F.unpack(render)
    else
        template = "%s"
    end
    render = render
        : gsub("%%exe", exe or "%0")
        : gsub("%%ext", default_ext or "%0")
        : gsub("%%o", default_ext and ("%%o."..default_ext) or "%0")
    template = template
        : gsub("%%ext", default_ext or "%0")
        : gsub("%%o", default_ext and ("%%o."..default_ext) or "%0")
    render = F.I{ext=default_ext}(render)
    local render_image = function(contents, opts)
        local filename = contents:match("^@([^\n\r]+)$")
        if filename then
            contents = tostring(include.raw(filename))
        end
        contents = (opts.pp or F.id)(contents)
        local input_ext = get_input_ext(render)
        local ext = get_ext(render, template)
        local hash = crypt.hash(render..contents)
        default_image_output()
        fs.mkdirs(output_path)
        local out = fs.join(output_path, opts.name or hash)
        local link = fs.join(link_path, fs.basename(out))
        local meta = out..ext..".meta"
        local meta_content = F.unlines {
            "hash: "..hash,
            "render: "..render,
            "out: "..out,
            "link: "..link,
            "",
            (template : gsub("%%s", contents)),
        }
        local old_meta = fs.read(meta) or ""
        if not fs.is_file(out..ext) or meta_content ~= old_meta then
            fs.with_tmpdir(function(tmpdir)
                fs.mkdirs(fs.dirname(out))
                local name = fs.join(tmpdir, "diagram")
                local name_ext = name..input_ext
                local templated_contents = template
                    : gsub("%%o", out)
                    : gsub("%%s", contents)
                assert(fs.write(name_ext, templated_contents), "Can not create "..name_ext)
                assert(fs.write(meta, meta_content), "Can not create "..meta)
                local render_cmd = make_diagram_cmd(name, out, render)
                render_diagram(render_cmd)
            end)
        end
        return link..ext, out..ext
    end
    return function(param)
        if type(param) == "table" then
            local opts = param
            return function(contents)
                return render_image(contents, opts)
            end
        else
            local contents = param
            return render_image(contents, {})
        end
    end
end

local default_ext = "svg"

local PLANTUML = _G["PLANTUML"] or os.getenv "PLANTUML" or fs.join(fs.dirname(arg[0]), "plantuml.jar")
local DITAA = _G["DITAA"] or os.getenv "DITAA" or fs.join(fs.dirname(arg[0]), "ditaa.jar")

local graphviz = "%exe -T%ext -o %o %i"
local plantuml = "java -jar "..PLANTUML.." -pipe -charset UTF-8 -t%ext < %i > %o"
local asymptote = "%exe -f %ext -o %o %i"
local mermaid = "%exe --pdfFit -i %i -o %o"
local blockdiag = "%exe -a -T%ext -o %o %i"
local ditaa = "java -jar "..DITAA.." $(ext=='svg' and '--svg' or '') -o -e UTF-8 %i %o"
local gnuplot = "%exe -e 'set terminal %ext' -e 'set output \"%o\"' -c %i"
local lsvg = "%exe %i.lua -o %o"
local octave = { "octave --no-gui %i", 'figure("visible", "off")\n\n%s\nprint %o;' }

local function define(t)
    local self = {}
    local mt = {}
    for k, v in pairs(t) do
        if k:match "^__" then
            mt[k] = v
        else
            self[k] = v
        end
    end
    return setmetatable(self, mt)
end

local function instantiate(exe, render)
    return define {
        __call = function(_, ...) return diagram(exe, render, default_ext)(...) end,
        svg = diagram(exe, render, "svg"),
        png = diagram(exe, render, "png"),
        pdf = diagram(exe, render, "pdf"),
    }
end

return define {
    dot         = instantiate("dot", graphviz),
    neato       = instantiate("neato", graphviz),
    twopi       = instantiate("twopi", graphviz),
    circo       = instantiate("circo", graphviz),
    fdp         = instantiate("fdp", graphviz),
    sfdp        = instantiate("sfdp", graphviz),
    patchwork   = instantiate("patchwork", graphviz),
    osage       = instantiate("osage", graphviz),
    plantuml    = instantiate("plantuml", plantuml),
    asy         = instantiate("asy", asymptote),
    mmdc        = instantiate("mmdc", mermaid),
    actdiag     = instantiate("actdiag", blockdiag),
    blockdiag   = instantiate("blockdiag", blockdiag),
    nwdiag      = instantiate("nwdiag", blockdiag),
    packetdiag  = instantiate("packetdiag", blockdiag),
    rackdiag    = instantiate("rackdiag", blockdiag),
    seqdiag     = instantiate("seqdiag", blockdiag),
    ditaa       = instantiate("ditaa", ditaa),
    gnuplot     = instantiate("gnuplot", gnuplot),
    lsvg        = instantiate("lsvg", lsvg),
    octave      = instantiate("octave", octave),
    __call = function(_, render, ext) return diagram(nil, render, ext) end,
    __index = {
        format = function(fmt) default_ext = fmt end,
        output = function(path) output_file = path end,
    },
}
]====]),
["include"] = lib("include.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

local F = require "F"

local flex = require "flex"
local convert = require "convert"

--[[@@@
* `include(filename, [opts])`: include the file `filename`.

    - `opts.pattern` is the Lua pattern used to identify the part of the file to include. If the pattern is not given, the whole file is included.
    - `opts.from` is the format of the input file (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.to` is the destination format (e.g. `"markdown"`, `"rst"`, ...). The default format is Markdown.
    - `opts.shift` is the offset applied to the header levels. The default offset is `0`.

* `include.raw(filename, [opts])`: like `include` but the content of the file is not preprocessed with `ypp`.

?(false)
The `include` macro can also be called as a curried function (arguments can be swapped). E.g.:

    @include "file.csv" {from="csv"}
    @include {from="csv"} "file.csv"

?(true)
@@@]]

local function include(filename, opts, prepro)
    opts = opts or {}
    local content = ypp.with_inputfile(filename, function(full_filepath)
        local s = ypp.read_file(full_filepath)
        if opts.pattern then
            s = s:match(opts.pattern)
        end
        return prepro(s)
    end)
    content = convert.if_required(content, opts)
    return content
end

local flex_include     = flex.str(function(filename, opts) return include(filename, opts, ypp) end)
local flex_include_raw = flex.str(function(filename, opts) return include(filename, opts, F.id) end)

return setmetatable({
    raw = flex_include_raw,
}, {
    __call = function(_, ...) return flex_include(...) end,
})
]=]),
["parser"] = lib("parser.lua", [===[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LIB

local function format_value(x)
    local mt = getmetatable(x)
    if mt and mt.__tostring then return tostring(x) end
    if type(x) == "table" then return F.map(tostring, x):unlines() end
    return tostring(x)
end

local function traceback(tag, expr)
    if tag=="@" and expr:match("^[%w_.]*$") then return function() end end
    return function(message)
        local trace = F.flatten {
            arg[0]:basename()..": "..message,
            F(debug.traceback())
                : lines()
                : take_while(function(line)
                    return not line:find("[C]: in function 'xpcall'", 1, true)
                    and not line:find("src/parser%.lua:%d+: in local 'msgh'")
                end)
                : filter(function(line)
                    return not line:find("src/parser%.lua:%d+:")
                end),
        }
        io.stderr:write(trace:unlines())
        io.stderr:flush()
        os.exit(1)
    end
end

local function eval(s, tag, expr, state)
    if state.on then
        local msgh = traceback(tag, expr)
        local ok_compile, chunk, compile_error = xpcall(load, msgh, (tag=="@" and "return " or "")..expr, expr, "t")
        if not ok_compile then return s end -- load execution error
        if not chunk then -- compilation error
            msgh(compile_error)
            return s
        end
        local ok_eval, val = xpcall(chunk, msgh)
        if not ok_eval then return s end
        if val == nil and tag=="@" and expr:match("^[%w_]+$") then return s end
        if tag == "@@" then
            if val ~= nil then
                return format_value(val)
            else
                return ""
            end
        end
        return format_value(val)
    else
        return s
    end
end

-- a parser is a function that takes a string, a position and returns the start and stop of the next expression and the expression

local function parse_parentheses(s, i0)
    -- (...)
    local i1, expr, i2 = s:match("^%s*()(%b())()", i0)
    if expr then
        return i1, i2, expr:sub(2, -2)
    end
end

local function parse_brackets(s, i0)
    -- {...}
    local i1, expr, i2 = s:match("^%s*()(%b{})()", i0)
    if expr then
        return i1, i2, expr:sub(2, -2)
    end
end

local function parse_long_string(s, i0)
    -- [==[ ... ]==]
    local i1, sep, i2 = s:match("^%s*()%[(=-)%[()", i0)
    if sep then
        local i3, i4 = s:match("()%]"..sep.."%]()", i2)
        if i3 then
            return i1, i4, s:sub(i2, i3-1)
        end
    end
end

local function parse_quoted_string(s, i0, c)
    -- "..."
    local i1 = s:match('^%s*()'..c, i0)
    if i1 then
        local i = i1+1
        while i <= #s do
            if s:sub(i, i) == c then
                return i1, i+1, s:sub(i1+1, i-1)
            end
            if s:sub(i, i) == '\\' then
                i = i+1
            end
            i = i+1
        end
    end
end

local parse_sexpr

local function parse_expr(s, i0)
    -- E -> ident SE
    local i1, ident, i2 = s:match("^%s*()([%w_]+)()", i0)
    if ident then
        local i3 = parse_sexpr(s, i2)
        if i3 then return i1, i3, s:sub(i1, i3-1) end
    end
end

parse_sexpr = function(s, i0)
    -- SE -> [.:] E
    do
        local i1 = s:match("^%s*[.:]()", i0)
        if i1 then
            local _, i2, _ = parse_expr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> (...) SE
    do
        local _, i1, _ = parse_parentheses(s, i0)
        if i1 then
            local i2 = parse_sexpr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> {...} SE
    do
        local _, i1, _ = parse_brackets(s, i0)
        if i1 then
            local i2 = parse_sexpr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> "..." SE
    do
        local _, i1, _ = parse_quoted_string(s, i0, '"')
        if i1 then
            local i2 = parse_sexpr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> '...' SE
    do
        local _, i1, _ = parse_quoted_string(s, i0, "'")
        if i1 then
            local i2 = parse_sexpr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> [[...]] SE
    do
        local _, i1, _ = parse_long_string(s, i0)
        if i1 then
            local i2 = parse_sexpr(s, i1)
            if i2 then return i2 end
        end
    end
    -- SE -> nil
    do
        return i0
    end
end

local function parse_lhs(s, i0)
    -- LHS -> identifier ('.' identifier)*
    local i1, i2 = s:match("^%s*()[%w_]+()", i0)
    if i1 then
        local i = i2
        while true do
            local i3, i4 = s:match("^%s*()%.%s*[%w_]+()", i)
            if i3 then
                i = i4
            else
                return i1, i
            end
        end
    end
end

local atoms = {
    "^%s*()%-?%d+%.%d+e%-?%d+()",
    "^%s*()%-?%d+%.e%-?%d+()",
    "^%s*()%-?%.%d+e%-?%d+()",
    "^%s*()%-?%d+e%-?%d+()",
    "^%s*()%-?%d+%.%d+()",
    "^%s*()%-?%d+%.()",
    "^%s*()%-?%.%d+()",
    "^%s*()%-?%d+()",
    "^%s*()true()",
    "^%s*()false()",
}

local function parse_rhs(s, i0)
    -- RHS -> number | bool
    for _, atom in ipairs(atoms) do
        local i1, i2 = s:match(atom, i0)
        if i1 then return i1, i2 end
    end
    -- RHS = (...)
    do
        local i1, i2, _ = parse_parentheses(s, i0)
        if i1 then
            return i1, i2
        end
    end
    -- RHS = {...}
    do
        local i1, i2, _ = parse_brackets(s, i0)
        if i1 then
            return i1, i2
        end
    end
    -- RHS = "..."
    do
        local i1, i2, _ = parse_quoted_string(s, i0, '"')
        if i1 then
            return i1, i2
        end
    end
    -- RHS = '...'
    do
        local i1, i2, _ = parse_quoted_string(s, i0, "'")
        if i1 then
            return i1, i2
        end
    end
    -- RHS = [=[ ... ]=]
    do
        local i1, i2, _ = parse_long_string(s, i0)
        if i1 then
            return i1, i2
        end
    end
    -- RHS -> expr
    do
        local i1, i2, _ = parse_expr(s, i0)
        if i1 then
            return i1, i2
        end
    end
end

local function parse(s, i0, state)

    -- find the start of the next expression
    local i1, tag, i2 = s:match("()([@?/]+)()", i0)
    if not i1 then return #s+1, #s+1, "" end

    -- S -> "@/"
    if tag == "@/" then
        return i1, i2, state.on and "" or tag
    end

    -- S -> "?%b()"
    if tag == "?" then
        local _, i3, cond = parse_parentheses(s, i2)
        if cond then
            state.on = assert(load("return "..cond, cond, "t"))()
            return i1, i3, ""
        end
    end

    -- S -> "@@ LHS = RHS
    if tag == "@@" then
        local i3, i4 = parse_lhs(s, i2)
        if i3 then
            local i5 = s:match("^%s*=()", i4)
            if i5 then
                local i6, i7 = parse_rhs(s, i5)
                if i6 then
                    return i1, i7, eval(s:sub(i1, i7-1), tag, s:sub(i3, i7-1), state)
                end
            end
        end
    end

    -- S -> "@@?..."
    if tag == "@" or tag == "@@" then
        -- S -> "@@?(...)"
        do
            local _, i3, expr = parse_parentheses(s, i2)
            if expr then
                return i1, i3, eval(s:sub(i1, i3-1), tag, expr, state)
            end
        end
        -- S -> "@@?[==[...]==]"
        do
            local _, i3, expr = parse_long_string(s, i2)
            if expr then
                return i1, i3, eval(s:sub(i1, i3-1), tag, expr, state)
            end
        end
        -- S -> "@@?"expr
        do
            local _, i3, expr = parse_expr(s, i2)
            if expr then
                return i1, i3, eval(s:sub(i1, i3-1), tag, expr, state)
            end
        end

    end

    -- S -> {}
    return i2, i2, ""

end

return function(s)
    local ts = {}
    local state = {on=true}
    local i = 1
    while i <= #s do
        local i1, i2, out = parse(s, i, state)
        if i1 then
            if i1 > i then
                ts[#ts+1] = s:sub(i, i1-1)
            end
            ts[#ts+1] = out
            i = i2
        else
            ts[#ts+1] = s:sub(i, #s)
            i = #s+1
        end
    end
    return table.concat(ts)
end
]===]),
["q"] = lib("q.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `q(source)`: return `source` unpreprocessed.
  `q` is used to avoid macro execution in a portion of text.
@@@]]

local F = require "F"

return F.id
]=]),
["script"] = lib("script.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `script(cmd)(source)`: execute `cmd` to interpret `source`.
  `source` is first saved to a temporary file which name is added to the command `cmd`.
  If `cmd` contains `%s` then `%s` is replaces by the temporary script name.
  Otherwise the script name is appended to the command.
  An explicit file extension can be given after `%s` for languages that require
  specific file extensions (e.g. `%s.fs` for F#).

`script` also predefines shortcuts for some popular languages:

@@( local descr = {
        bat = "`command` (DOS/Windows)",
        cmd = "`cmd` (DOS/Windows)",
        sh = "sh",
        bash = "bash",
        zsh = "zsh",
    }
    return F.keys(script):map(function(lang)
        return ("- `script.%s(source)`: run a script with %s"):format(lang, descr[lang] or lang:cap())
    end)
)

Example:

?(false)
```
$\sum_{i=0}^100 = @script.python "print(sum(range(101)))"$
```
?(true)
is rendered as
```
$\sum_{i=0}^100 = @script.python "print(sum(range(101)))"$
```
@@@]]

local fs = require "fs"
local sh = require "sh"
local flex = require "flex"
local convert = require "convert"

local function make_script_cmd(cmd, arg, ext)
    arg = arg..ext
    local n1, n2
    cmd, n1 = cmd:gsub("%%s"..(ext~="" and "%"..ext or ""), arg)
    cmd, n2 = cmd:gsub("%%s", arg)
    if n1+n2 == 0 then cmd = cmd .. " " .. arg end
    return cmd
end

local function script_ext(cmd)
    local ext = cmd:match("%%s(%.%w+)") -- extension given by the command line
    return ext or ""
end

local function run(cmd)
    return flex.str(function(content, opts)
        content = tostring(content)
        return fs.with_tmpdir(function (tmpdir)
            local name = fs.join(tmpdir, "script")
            local ext = script_ext(cmd)
            fs.write(name..ext, content)
            local output = sh.read(make_script_cmd(cmd, name, ext))
            if output then
                output = output:gsub("%s*$", "")
                output = convert.if_required(output, opts)
                return output
            else
                error("script error")
            end
        end)
    end)
end

return setmetatable({
    python = run "python %s.py",
    lua = run "lua %s.lua",
    bash = run "bash %s.sh",
    zsh = run "zsh %s.sh",
    sh = run "sh %s.sh",
    cmd = run "cmd %s.cmd",
    bat = run "command %s.bat",
}, {
    __call = function(_, cmd) return run(cmd) end,
})
]=]),
["when"] = lib("when.lua", [====[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@LOAD

--[[@@@
* `when(cond)(text)`: emit `text` only if `cond` is true.

E.g.:

?(false)
```
@when(lang=="en")
[===[
The current language is English.
]===]
```
?(true)
@@@]]

local F = require "F"

return function(cond)
    return cond and ypp or F.const ""
end
]====]),
["_YPP_VERSION"] = lib("_YPP_VERSION.lua", [=[return [[0.11]] --@LOAD
]=]),
}
table.insert(package.searchers, 2, function(name) return libs[name] end)
require "luax"
_ENV["atexit"] = require "atexit"
_ENV["comment"] = require "comment"
_ENV["convert"] = require "convert"
_ENV["doc"] = require "doc"
_ENV["file"] = require "file"
_ENV["image"] = require "image"
_ENV["include"] = require "include"
_ENV["q"] = require "q"
_ENV["script"] = require "script"
_ENV["when"] = require "when"
_ENV["_YPP_VERSION"] = require "_YPP_VERSION"
return lib("ypp.lua", [=[--[[
This file is part of ypp.

ypp is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ypp is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ypp.  If not, see <https://www.gnu.org/licenses/>.

For further information about ypp you can visit
http://cdelord.fr/ypp
--]]

--@MAIN

--[[@@@
* `ypp(s)`: apply the `ypp` preprocessor to a string.
* `ypp.input_file()`: return the name of the current input file.
* `ypp.input_path()`: return the path of the current input file.
* `ypp.input_file(n)`: return the name of the nth input file in the current *include* stack.
* `ypp.input_path(n)`: return the path of the nth input file in the current *include* stack.
@@@]]

-- preload some LuaX modules
_G.F = require "F"
_G.crypt = require "crypt"
_G.fs = require "fs"
_G.sh = require "sh"
_G.sys = require "sys"

local F = _G.F
local fs = _G.fs

local ypp_mt = {__index={}}
local ypp = setmetatable({}, ypp_mt)
local known_input_files = F{}
local output_contents = F{}
local input_files = F{fs.join(fs.getcwd(), "-")} -- stack of input files (current branch from the root to the deepest included document)
local output_file = "-"

local function die(msg, ...)
    io.stderr:write("ypp: ", msg:format(...), "\n")
    os.exit(1)
end

local function load_script(filename)
    local modname = filename:gsub("%.lua$", "")
    _G[modname] = require(modname)
end

local function eval_expr(expr)
    assert(load(expr, expr, "t"))()
end

local function add_path(paths)
    if not paths then return end
    local dir_sep, template_sep, template, _ = F(package.config):lines():unpack()
    package.path = F.concat {
        paths:split(template_sep):map(function(path) return path..dir_sep..template..".lua" end),
        { package.path }
    } : str(template_sep)
end

local function process(content)
    output_contents[#output_contents+1] = ypp(content)
end

local function read_file(filename)
    local content
    if filename == "-" then
        content = io.stdin:read "a"
    else
        content = assert(fs.read(filename))
        known_input_files[#known_input_files+1] = filename:gsub("^"..fs.getcwd()..fs.sep, "")
    end
    return content
end

ypp.read_file = read_file

local function find_file(filename)
    local current_input_file = input_files:last()
    local input_path = fs.dirname(current_input_file)
    local full_filepath = F{
        fs.join(input_path, filename),
        filename,
    } : filter(fs.is_file) : head()
    assert(full_filepath, filename..": file not found")
    return full_filepath
end

ypp.find_file = find_file

local function with_inputfile(filename, func)
    if filename == "-" then return func(filename) end
    local full_filepath = find_file(filename)
    input_files[#input_files+1] = full_filepath
    local res = {func(full_filepath)}
    input_files[#input_files] = nil
    return F.unpack(res)
end

ypp.with_inputfile = with_inputfile

local function process_file(filename)
    return with_inputfile(filename, function(full_filepath)
        return process(read_file(full_filepath))
    end)
end

function ypp.input_file(level)
    return input_files[#input_files-(level or 0)]
end

function ypp.input_path(level)
    return fs.dirname(input_files[#input_files-(level or 0)])
end

function ypp.output_file()
    return output_file
end

function ypp_mt.__call(_, content)
    if type(content) == "table" then return F.map(ypp, content) end
    local parser = require "parser"
    return parser(content)
end

local function write_outputs(args)
    local content = output_contents:str()
    if not args.output or args.output == "-" then
        io.stdout:write(content)
    else
        fs.mkdirs(fs.dirname(args.output))
        fs.write(args.output, content)
    end
    local file = require "file"
    file.files:foreach(function(f) f:flush() end)
end

local function write_dep_file(args)
    if not (args.gendep or args.depfile or #args.targets>0) then return end
    local name = args.depfile or (args.output and fs.splitext(args.output)..".d")
    if not name then die("The dependency file name is unknown, use --MF or -o") end
    local function mklist(...)
        return F{...}:flatten():from_set(F.const(true)):keys()
            :filter(function(p) return p ~= "-" end)
            :map(function(p) return p:gsub("^%."..fs.sep, "") end)
            :sort()
            :unwords()
    end
    local scripts = F.values(package.modpath)
    local file = require "file"
    local deps = mklist(args.targets, args.output or {}, file.outputs).." : "..mklist(known_input_files, scripts)
    fs.mkdirs(fs.dirname(name))
    fs.write(name, deps.."\n")
end

local function parse_args()
    local parser = require "argparse"()
        : name "ypp"
        : description(("ypp %s\nYet a PreProcessor"):format(_YPP_VERSION))
        : epilog "For more information, see https://github.com/CDSoft/ypp"

    parser : flag "-v"
        : description "Show yyp version"
        : action(function(_, _, _, _) print(_YPP_VERSION); os.exit() end)

    parser : option "-l"
        : description "Execute a Lua script"
        : argname "script"
        : count "*"
        : action(function(_, _, name, _) load_script(name) end)

    parser : option "-e"
        : description "Execute a Lua expression"
        : argname "expression"
        : count "*"
        : action(function(_, _, expr, _) eval_expr(expr) end)

    parser : option "-p"
        : description "Add a path to package.path"
        : argname "path"
        : count "*"
        : action(function(_, _, path, _) add_path(path) end)

    local output = nil
    parser : option "-o"
        : description "Redirect the output to 'file'"
        : target "output"
        : argname "file"
        : action(function(_, _, path, _)
            output = path
            output_file = path
            require"image".output(output)
        end)

    parser : option "-t"
        : description "Set the default format of generated images"
        : target "image_format"
        : choices { "svg", "pdf", "png" }
        : action(function(_, _, fmt, _) require"image".format(fmt) end)

    parser : option "--MT"
        : description "Add `name` to the target list (implies `--MD`)"
        : target "targets"
        : argname "target"
        : count "*"

    parser : option "--MF"
        : description "Set the dependency file name (implies `--MD`)"
        : target "depfile"
        : argname "name"

    parser : flag "--MD"
        : description "Generate a dependency file"
        : target "gendep"

    parser : argument "input"
        : description "Input file"
        : args "*"
        : action(function(_, _, names, _)
            if #names == 0 then names = {"-"} end
            F.foreach(names, process_file)
        end)

    return F.patch(parser:parse(), {output=output})
end

_ENV.ypp = ypp
local args = parse_args()
require "atexit".run()
write_dep_file(args)
write_outputs(args)
]=])()
