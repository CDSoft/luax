#!/usr/bin/env -S lua --

-- Generated with LuaX
-- Copyright (C) 2021-2026 codeberg.org/cdsoft/luax, Christophe Delord

_LUAX_VERSION = "LuaX 10.3.1"

local function lib(path, src) return assert(load(src, '@$bang:'..path)) end
package.preload["F"] = lib("luax/F.lua", [==[--[[
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
https://codeberg.org/cdsoft/luax
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
In this case, F also defines the `__call` metamethod that takes a method name
and returns a function that actually calls the requested method.
E.g.:

```lua
t = F{foo = 12, mapk = 42} -- note that mapk is also a method of F tables

t:mapk(func)    -- fails because mapk is a field of t
t"mapk"(func)   -- works and is equivalent to F.mapk(func, t)
```

@@@]]

local getmetatable, setmetatable = getmetatable, setmetatable
local ipairs, pairs, next = ipairs, pairs, next
local load = load
local pcall = pcall
local rawequal, rawset = rawequal, rawset
local select = select
local tostring = tostring
local type = type

local t_concat = table.concat
local t_insert, t_remove = table.insert, table.remove
local t_sort = table.sort
local t_unpack = table.unpack

local s_byte, s_char = string.byte, string.char
local s_find, s_match, s_gmatch, s_gsub = string.find, string.match, string.gmatch, string.gsub
local s_format = string.format
local s_lower, s_upper = string.lower, string.upper
local s_rep = string.rep
local s_sub = string.sub

local s_bytes, s_chars
local s_cap
local s_take, s_drop
local s_head, s_tail
local s_init, s_last
local s_split

local abs = math.abs
local fmod = math.fmod
local math_type = math.type
local max = math.max

local mathx = require "mathx"
local copysign = mathx.copysign
local isnormal = mathx.isnormal

local F = {}

local mt = {
    __name = "F-table",
    __index = {},
}

function mt.__call(self, name)
    local method = mt.__index[name]
    return function(...) return method(self, ...) end
end

local F_clone
local F_concat, F_merge
local F_pairs
local F_keys
local F_head, F_tail
local F_init, F_last
local F_take, F_drop
local F_take_while, F_drop_while, F_drop_while_end
local Nil
local F_comp, F_op_eq, F_op_lt
local F_quot_rem, F_div_mod
local F_is_prefix_of, F_is_suffix_of, F_is_infix_of
local F_const
local F_length
local F_null
local F_map, F_from_set
local F_foreach
local F_filterk
local F_flatten
local F_zip
local F_minimum
local F_permutations

--[[------------------------------------------------------------------------@@@
## Standard types, and related functions
@@@]]

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
        local ks = F_keys(F_merge{a, b})
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
        local ks = F_keys(F_merge{a, b})
        for i = 1, #ks do
            local k = ks[i]
            if universal_ne(a[k], b[k]) then return true end
        end
        return false
    end
    return a ~= b
end

local function universal_comp(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return F_comp(type_rank[ta], type_rank[tb]) end
    if ta == "nil" then return 0 end
    if ta == "number" or ta == "string" or ta == "boolean" then return F_comp(a, b) end
    if ta == "table" then
        local ks = F_keys(F_merge{a, b})
        for i = 1, #ks do
            local k = ks[i]
            local ak = a[k]
            local bk = b[k]
            local order = universal_comp(ak, bk)
            if order ~= 0 then return order end
        end
        return 0
    end
    return F_comp(tostring(a), tostring(b))
end

local function universal_lt(a, b)
    return universal_comp(a, b) < 0
end

local function universal_le(a, b)
    return universal_comp(a, b) <= 0
end

local function universal_gt(a, b)
    return universal_comp(a, b) > 0
end

local function universal_ge(a, b)
    return universal_comp(a, b) >= 0
end

local function key_eq(a, b)
    return a == b
end

local function key_ne(a, b)
    return a ~= b
end

local function key_lt(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] < type_rank[tb] end
    return a < b
end

local function key_le(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] <= type_rank[tb] end
    return a <= b
end

local function key_gt(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] > type_rank[tb] end
    return a > b
end

local function key_ge(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return type_rank[ta] >= type_rank[tb] end
    return a >= b
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

F_op_eq = F.op.eq
F_op_lt = F.op.lt

--[[@@@
```lua
F.op.ueq(a, b)              -- a == b  (†)
F.op.une(a, b)              -- a ~= b  (†)
F.op.ult(a, b)              -- a < b   (†)
F.op.ule(a, b)              -- a <= b  (†)
F.op.ugt(a, b)              -- a > b   (†)
F.op.uge(a, b)              -- a >= b  (†)
```
> Universal comparison operators
  ((†) recursive comparisons on elements of possibly different Lua types)
@@@]]

F.op.ueq = universal_eq
F.op.une = universal_ne
F.op.ult = universal_lt
F.op.ule = universal_le
F.op.ugt = universal_gt
F.op.uge = universal_ge

--[[@@@
```lua
F.op.keq(a, b)              -- a == b  (†)
F.op.kne(a, b)              -- a ~= b  (†)
F.op.klt(a, b)              -- a < b   (†)
F.op.kle(a, b)              -- a <= b  (†)
F.op.kgt(a, b)              -- a > b   (†)
F.op.kge(a, b)              -- a >= b  (†)
```
> Universal comparison operators
  ((†) non recursive comparisons on elements of possibly different Lua types).
  The `kxx` functions are faster but less generic than `uxx`.
  They are more suitable for sorting keys (e.g. F.keys).
@@@]]

F.op.keq = key_eq
F.op.kne = key_ne
F.op.klt = key_lt
F.op.kle = key_le
F.op.kgt = key_gt
F.op.kge = key_ge

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
        local x = cases[val]
        if x ~= nil then return x end
        return cases[Nil]
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

function F.fst(xs) return xs[1] end
mt.__index.fst = F.fst

--[[@@@
```lua
F.snd(xs)
xs:snd()
```
> Extract the second component of a list.
@@@]]

function F.snd(xs) return xs[2] end
mt.__index.snd = F.snd

--[[@@@
```lua
F.thd(xs)
xs:thd()
```
> Extract the third component of a list.
@@@]]

function F.thd(xs) return xs[3] end
mt.__index.thd = F.thd

--[[@@@
```lua
F.nth(n, xs)
xs:nth(n)
```
> Extract the n-th component of a list.
@@@]]

function F.nth(n, xs) return xs[n] end
function mt.__index:nth(n) return F.nth(n, self) end

--[[------------------------------------------------------------------------@@@
### Basic type classes
@@@]]

--[[@@@
```lua
F.comp(a, b)
```
> Comparison (-1, 0, 1)
@@@]]

F_comp = function(a, b)
    if a < b then return -1 end
    if a > b then return 1 end
    return 0
end
F.comp = F_comp

--[[@@@
```lua
F.ucomp(a, b)
```
> Comparison (-1, 0, 1) (using universal comparison operators)
@@@]]

F.ucomp = universal_comp

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
function F.signum(a) return F_comp(a, 0) end

--[[@@@
```lua
F.quot(a, b)
```
> integer division truncated toward zero
@@@]]

function F.quot(a, b)
    return (a - fmod(a, b)) // b
end

--[[@@@
```lua
F.rem(a, b)
```
> integer remainder satisfying quot(a, b)*b + rem(a, b) == a, 0 <= rem(a, b) < abs(b)
@@@]]
F.rem = fmod

--[[@@@
```lua
F.quot_rem(a, b)
```
> simultaneous quot and rem
@@@]]

F_quot_rem = function(a, b)
    local r = fmod(a, b)
    local q = (a - r) // b
    return q, r
end
F.quot_rem = F_quot_rem

--[[@@@
```lua
F.div(a, b)
```
> integer division truncated toward negative infinity
@@@]]

function F.div(a, b)
    return a // b
end

--[[@@@
```lua
F.mod(a, b)
```
> integer modulus satisfying div(a, b)*b + mod(a, b) == a, 0 <= mod(a, b) < abs(b)
@@@]]

function F.mod(a, b)
    return a - b*(a//b)
end

--[[@@@
```lua
F.div_mod(a, b)
```
> simultaneous div and mod
@@@]]

F_div_mod = function(a, b)
    local q = a // b
    local r = a - b*q
    return q, r
end
F.div_mod = F_div_mod

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
F.log10(x), F.log2(x)
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
F.log10 = mathx.log10
F.log2 = mathx.log2
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
> returns a pair (n, f) such that x = n+f, and:
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
    return not isnormal(x)
end

--[[@@@
```lua
F.is_negative_zero(x)
```
> True if the argument is an IEEE negative zero
@@@]]

function F.is_negative_zero(x)
    return x == 0.0 and copysign(1, x) < 0
end

--[[@@@
```lua
F.atan2(y, x)
```
> computes the angle (from the positive x-axis) of the vector from the origin to the point (x, y).
@@@]]

F.atan2 = mathx.atan

--[[@@@
```lua
F.even(n)
F.odd(n)
```
> parity check
@@@]]

function F.even(n) return n&1 == 0 end

function F.odd(n) return n&1 == 1 end

--[[@@@
```lua
F.gcd(a, b)
F.lcm(a, b)
```
> Greatest Common Divisor and Least Common Multiple of a and b.
@@@]]

do

local function gcd(a, b)
    a, b = abs(a), abs(b)
    while b > 0 do
        a, b = b, a%b
    end
    return a
end

local function lcm(a, b)
    return abs(a // gcd(a, b) * b)
end

F.gcd, F.lcm = gcd, lcm

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

F_const = function(...)
    local val = {...}
    return function(...) ---@diagnostic disable-line:unused-vararg
        return t_unpack(val)
    end
end
F.const = F_const

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
    if n == 0 then
        return f
    elseif n == 1 then
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
        local xs = {...}
        return function(...)
            return f(t_unpack(F_concat{xs, {...}}))
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

do

local function err(msg, level, tb)
    level = (level or 1) + 2
    local info = debug.getinfo(level)
    local file = info.short_src
    local line = info.currentline

    msg = (function()
        if type(msg) == "string" then return msg end
        local msg_mt = getmetatable(msg)
        if msg_mt and msg_mt.__tostring then
            local str = tostring(msg)
            if type(str) == "string" then return str end
        end
        return string.format("(error object is a %s value)", type(msg))
    end)()

    msg = t_concat{arg[0] or "LuaX", ": ", file, ":", line, ": ", msg}
    io.stderr:write(tb and debug.traceback(msg, level) or msg, "\n")
    os.exit(1)
end

function F.error(message, level) err(message, level, true) end

function F.error_without_stack_trace(message, level) err(message, level, false) end

end

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
            if v then return t_unpack(v) end
            v = {f(k)}
            mem[k] = v
            return t_unpack(v)
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
            return t_unpack(cur[_value])
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

do

local default_show_options = {
    int = "%s",
    flt = "%s",
    indent = nil,
    lt = F.op.klt,
}

local keywords = {}
for _, k in ipairs {
    "and",       "break",     "do",        "else",      "elseif",    "end",
    "false",     "for",       "function",  "global",    "goto",      "if",
    "in",        "local",     "nil",       "not",       "or",        "repeat",
    "return",    "then",      "true",      "until",     "while",
} do keywords[k] = true end

function F.show(x, opt)

    opt = F_merge{default_show_options, opt}
    local opt_indent = opt.indent
    local opt_int = opt.int
    local opt_flt = opt.flt
    local opt_lt = opt.lt

    local tokens = {}
    local function emit(token) tokens[#tokens+1] = token end
    local function drop() t_remove(tokens) end

    local stack = {}
    local function push(val) stack[#stack + 1] = val end
    local function pop() t_remove(stack) end
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
                if opt_indent then tabs = tabs + opt_indent end
                local n = #val
                for i = 1, n do
                    fmt(val[i])
                    emit ", "
                end
                local first_field = true
                for k, v in F_pairs(val, opt_lt) do
                    if not (type(k) == "number" and math_type(k) == "integer" and 1 <= k and k <= #val) then
                        if first_field and opt_indent and n > 1 then drop() emit "," end
                        first_field = false
                        need_nl = opt_indent ~= nil
                        if opt_indent then emit "\n" emit(s_rep(" ", tabs)) end
                        if type(k) == "string" and s_match(k, "^[%a_][%w_]*$") and not keywords[k] then
                            emit(k)
                        else
                            emit "[" fmt(k) emit "]"
                        end
                        if opt_indent then emit " = " else emit "=" end
                        fmt(v)
                        if opt_indent then emit "," else emit ", " end
                        n = n + 1
                    end
                end
                if n > 0 and not need_nl then drop() end
                if need_nl then emit "\n" end
                if opt_indent then tabs = tabs - opt_indent end
                if opt_indent and need_nl then emit(s_rep(" ", tabs)) end
                emit "}"
                pop()
            end
        elseif type(val) == "number" then
            if math_type(val) == "integer" then
                emit(s_format(opt_int, val))
            elseif math_type(val) == "float" then
                emit(s_gsub(s_format(opt_flt, val), ",", "."))
            else
                emit(s_format("%s", val))
            end
        elseif type(val) == "string" then
            emit(s_format("%q", val))
        else
            emit(s_format("%s", val))
        end
    end

    fmt(x)
    return t_concat(tokens)

end
mt.__index.show = F.show

end

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
    local ret = F{pcall(chunk)}
    local status, value = ret:head(), ret:tail()
    if not status then return nil, value:unpack() end
    return value:unpack()
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

F_clone = function(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return setmetatable(t2, mt)
end
F.clone = F_clone
mt.__index.clone = F_clone

--[[@@@
```lua
F.deep_clone(t)
t:deep_clone()
```
> `F.deep_clone(t)` recursively clones `t`.
@@@]]

function F.deep_clone(t)
    local function go(t1)
        if type(t1) ~= "table" then return t1 end
        local t2 = {}
        for k, v in pairs(t1) do t2[k] = go(v) end
        return setmetatable(t2, getmetatable(t1))
    end
    return setmetatable(go(t), mt)
end
mt.__index.deep_clone = F.deep_clone

--[[@@@
```lua
F.rep(n, x)
```
> Returns a list of length n with x the value of every element.
@@@]]

function F.rep(n, x)
    local xs = {}
    for i = 1, n do
        xs[i] = x
    end
    return setmetatable(xs, mt)
end

--[[@@@
```lua
F.range(a)
F.range(a, b)
F.range(a, b, step)
```
> Returns a range [1, a], [a, b] or [a, a+step, ... b]
@@@]]

function F.range(a, b, step)
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
    return setmetatable(r, mt)
end

--[[@@@
```lua
F.concat{xs1, xs2, ... xsn}
F{xs1, xs2, ... xsn}:concat()
xs1 .. xs2
```
> concatenates lists
@@@]]

F_concat = function(xss)
    local ys = {}
    for i = 1, #xss do
        local xs = xss[i]
        for j = 1, #xs do
            ys[#ys+1] = xs[j]
        end
    end
    return setmetatable(ys, mt)
end
F.concat = F_concat
mt.__index.concat = F_concat

function mt.__concat(xs1, xs2)
    return F_concat{xs1, xs2}
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

do

local function default_leaf(x)
    -- by default, a table is a leaf if it has a metatable and is not an F' list
    local xmt = getmetatable(x)
    return xmt and xmt ~= mt
end

F_flatten = function(xs, leaf)
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
    return setmetatable(zs, mt)
end
F.flatten = F_flatten
mt.__index.flatten = F_flatten

end

--[=[@@@
```lua
F.str({s1, s2, ... sn}, [separator, [last_separator]])
ss:str([separator, [last_separator]])
```
> concatenates strings (separated with an optional separator) and returns a string.
@@@]=]

function F.str(ss, sep, last_sep)
    if last_sep then
        if #ss <= 1 then return ss[1] or "" end
        return t_concat({t_concat(ss, sep, 1, #ss-1), ss[#ss]}, last_sep)
    else
        return t_concat(ss, sep)
    end
end
mt.__index.str = F.str

--[[@@@
```lua
F.from_set(f, ks)
ks:from_set(f)
```
> Build a map from a set of keys and a function which for each key computes its value.
@@@]]

F_from_set = function(f, ks)
    local t = {}
    for i = 1, #ks do
        local k = ks[i]
        t[k] = f(k)
    end
    return setmetatable(t, mt)
end
F.from_set = F_from_set
mt.__index.from_set = function(ks, f) return F_from_set(f, ks) end

--[[@@@
```lua
F.from_list(kvs)
kvs:from_list()
```
> Build a map from a list of key/value pairs.
@@@]]

function F.from_list(kvs)
    local t = {}
    for i = 1, #kvs do
        local k, v = t_unpack(kvs[i])
        t[k] = v
    end
    return setmetatable(t, mt)
end
mt.__index.from_list = F.from_list

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
> `F.pairs` sorts keys using the function `comp_lt` or the default `<=` operator for keys (`F.op.klt`).
@@@]]

F.ipairs = ipairs
mt.__index.ipairs = ipairs

F_pairs = function(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local i = 0
    return function()
        i = i+1
        local k = ks[i]
        return k, t[k]
    end
end
F.pairs = F_pairs
mt.__index.pairs = F_pairs

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

F_keys = function(t, comp_lt)
    comp_lt = comp_lt or key_lt
    local ks = {}
    for k, _ in pairs(t) do ks[#ks+1] = k end
    t_sort(ks, comp_lt)
    return setmetatable(ks, mt)
end
F.keys = F_keys
mt.__index.keys = F_keys

function F.values(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local vs = {}
    for i = 1, #ks do vs[i] = t[ks[i]] end
    return setmetatable(vs, mt)
end
mt.__index.values = F.values

function F.items(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local kvs = {}
    for i = 1, #ks do
        local k = ks[i]
        kvs[i] = setmetatable({k, t[k]}, mt) end
    return setmetatable(kvs, mt)
end
mt.__index.items = F.items

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

F_head = function(xs) return xs[1] end
F.head = F_head
mt.__index.head = F.head

F_last = function(xs) return xs[#xs] end
F.last = F_last
mt.__index.last = F.last

--[[@@@
```lua
F.tail(xs)
xs:tail()
F.init(xs)
xs:init()
```
> returns the list after the head (tail) or before the last element (init).
@@@]]

F_tail = function(xs)
    if #xs == 0 then return nil end
    local tail = {}
    for i = 2, #xs do tail[#tail+1] = xs[i] end
    return setmetatable(tail, mt)
end
F.tail = F_tail
mt.__index.tail = F_tail

F_init = function(xs)
    if #xs == 0 then return nil end
    local init = {}
    for i = 1, #xs-1 do init[#init+1] = xs[i] end
    return setmetatable(init, mt)
end
F.init = F_init
mt.__index.init = F_init

--[[@@@
```lua
F.uncons(xs)
xs:uncons()
```
> returns the head and the tail of a list.
@@@]]

function F.uncons(xs) return F_head(xs), F_tail(xs) end
mt.__index.uncons = F.uncons

--[[@@@
```lua
F.unpack(xs, [ i, [j] ])
xs:unpack([ i, [j] ])
```
> returns the elements of xs between indices i and j
@@@]]

F.unpack = table.unpack
mt.__index.unpack = table.unpack

--[[@@@
```lua
F.take(n, xs)
xs:take(n)
```
> Returns the prefix of xs of length n.
@@@]]

F_take = function(n, xs)
    local ys = {}
    for i = 1, n do
        ys[i] = xs[i]
    end
    return setmetatable(ys, mt)
end
F.take = F_take
mt.__index.take = function(xs, n) return F_take(n, xs) end

--[[@@@
```lua
F.drop(n, xs)
xs:drop(n)
```
> Returns the suffix of xs after the first n elements.
@@@]]

F_drop = function(n, xs)
    local ys = {}
    for i = n+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return setmetatable(ys, mt)
end
F.drop = F_drop
mt.__index.drop = function(xs, n) return F_drop(n, xs) end

--[[@@@
```lua
F.split_at(n, xs)
xs:split_at(n)
```
> Returns a tuple where first element is xs prefix of length n and second element is the remainder of the list.
@@@]]

do

local function F_split_at(n, xs)
    return F_take(n, xs), F_drop(n, xs)
end
F.split_at = F_split_at
mt.__index.split_at = function(xs, n) return F_split_at(n, xs) end

end

--[[@@@
```lua
F.take_while(p, xs)
xs:take_while(p)
```
> Returns the longest prefix (possibly empty) of xs of elements that satisfy p.
@@@]]

F_take_while = function(p, xs)
    local ys = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[i] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt)
end
F.take_while = F_take_while
mt.__index.take_while = function(xs, p) return F_take_while(p, xs) end

--[[@@@
```lua
F.drop_while(p, xs)
xs:drop_while(p)
```
> Returns the suffix remaining after `take_while(p, xs)`{.lua}.
@@@]]

F_drop_while = function(p, xs)
    local zs = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmetatable(zs, mt)
end
F.drop_while = F_drop_while
mt.__index.drop_while = function(xs, p) return F_drop_while(p, xs) end

--[[@@@
```lua
F.drop_while_end(p, xs)
xs:drop_while_end(p)
```
> Drops the largest suffix of a list in which the given predicate holds for all elements.
@@@]]

F_drop_while_end = function(p, xs)
    local zs = {}
    local i = #xs
    while i > 0 and p(xs[i]) do
        i = i-1
    end
    for j = 1, i do
        zs[j] = xs[j]
    end
    return setmetatable(zs, mt)
end
F.drop_while_end = F_drop_while_end
mt.__index.drop_while_end = function(xs, p) return F_drop_while_end(p, xs) end

--[[@@@
```lua
F.span(p, xs)
xs:span(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that satisfy p and second element is the remainder of the list.
@@@]]

do

local function F_span(p, xs)
    local ys = {}
    local zs = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[i] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt), setmetatable(zs, mt)
end
F.span = F_span
mt.__index.span = function(xs, p) return F_span(p, xs) end

end

--[[@@@
```lua
F.break_(p, xs)
xs:break_(p)
```
> Returns a tuple where first element is longest prefix (possibly empty) of xs of elements that do not satisfy p and second element is the remainder of the list.
@@@]]

do

local function F_break(p, xs)
    local ys = {}
    local zs = {}
    local i = 1
    while i <= #xs and not p(xs[i]) do
        ys[i] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt), setmetatable(zs, mt)
end
F.break_ = F_break
mt.__index.break_ = function(xs, p) return F_break(p, xs) end

end

--[[@@@
```lua
F.strip_prefix(prefix, xs)
xs:strip_prefix(prefix)
```
> Drops the given prefix from a list.
@@@]]

do

local function F_strip_prefix(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return nil end
    end
    local ys = {}
    for i = #prefix+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return setmetatable(ys, mt)
end
F.strip_prefix = F_strip_prefix
mt.__index.strip_prefix = function(xs, prefix) return F_strip_prefix(prefix, xs) end

end

--[[@@@
```lua
F.strip_suffix(suffix, xs)
xs:strip_suffix(suffix)
```
> Drops the given suffix from a list.
@@@]]

do

local function F_strip_suffix(suffix, xs)
    for i = 1, #suffix do
        if xs[#xs-#suffix+i] ~= suffix[i] then return nil end
    end
    local ys = {}
    for i = 1, #xs-#suffix do
        ys[i] = xs[i]
    end
    return setmetatable(ys, mt)
end
F.strip_suffix = F_strip_suffix
mt.__index.strip_suffix = function(xs, suffix) return F_strip_suffix(suffix, xs) end

end

--[[@@@
```lua
F.group(xs, [comp_eq])
xs:group([comp_eq])
```
> Returns a list of lists such that the concatenation of the result is equal to the argument. Moreover, each sublist in the result contains only equal elements.
@@@]]

function F.group(xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
    local yss = {}
    if #xs == 0 then return setmetatable(yss, mt) end
    local y = xs[1]
    local ys = {y}
    for i = 2, #xs do
        local x = xs[i]
        if comp_eq(x, y) then
            ys[#ys+1] = x
        else
            yss[#yss+1] = setmetatable(ys, mt)
            y = x
            ys = {y}
        end
    end
    yss[#yss+1] = setmetatable(ys, mt)
    return setmetatable(yss, mt)
end
mt.__index.group = F.group

--[[@@@
```lua
F.inits(xs)
xs:inits()
```
> Returns all initial segments of the argument, shortest first.
@@@]]

function F.inits(xs)
    local yss = {}
    for i = 0, #xs do
        local ys = {}
        for j = 1, i do
            ys[j] = xs[j]
        end
        yss[#yss+1] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
end
mt.__index.inits = F.inits

--[[@@@
```lua
F.tails(xs)
xs:tails()
```
> Returns all final segments of the argument, longest first.
@@@]]

function F.tails(xs)
    local yss = {}
    for i = 1, #xs+1 do
        local ys = {}
        for j = i, #xs do
            ys[#ys+1] = xs[j]
        end
        yss[#yss+1] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
end
mt.__index.tails = F.tails

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

F_is_prefix_of = function(prefix, xs)
    for i = 1, #prefix do
        if xs[i] ~= prefix[i] then return false end
    end
    return true
end
F.is_prefix_of = F_is_prefix_of
mt.__index.is_prefix_of = F_is_prefix_of

--[[@@@
```lua
F.is_suffix_of(suffix, xs)
suffix:is_suffix_of(xs)
```
> Returns `true` iff `xs` ends with `suffix`
@@@]]

F_is_suffix_of = function(suffix, xs)
    for i = 1, #suffix do
        if xs[#xs-#suffix+i] ~= suffix[i] then return false end
    end
    return true
end
F.is_suffix_of = F_is_suffix_of
mt.__index.is_suffix_of = F_is_suffix_of

--[[@@@
```lua
F.is_infix_of(infix, xs)
infix:is_infix_of(xs)
```
> Returns `true` iff `xs` contains `infix`
@@@]]

F_is_infix_of = function(infix, xs)
    for i = 1, #xs-#infix+1 do
        local found = true
        for j = 1, #infix do
            if xs[i+j-1] ~= infix[j] then found = false; break end
        end
        if found then return true end
    end
    return false
end
F.is_infix_of = F_is_infix_of
mt.__index.is_infix_of = F_is_infix_of

--[[@@@
```lua
F.has_prefix(xs, prefix)
xs:has_prefix(prefix)
```
> Returns `true` iff `xs` starts with `prefix`
@@@]]

F.has_prefix = function(xs, prefix) return F_is_prefix_of(prefix, xs) end
mt.__index.has_prefix = F.has_prefix

--[[@@@
```lua
F.has_suffix(xs, suffix)
xs:has_suffix(suffix)
```
> Returns `true` iff `xs` ends with `suffix`
@@@]]

F.has_suffix = function(xs, suffix) return F_is_suffix_of(suffix, xs) end
mt.__index.has_suffix = F.has_suffix

--[[@@@
```lua
F.has_infix(xs, infix)
xs:has_infix(infix)
```
> Returns `true` iff `xs` caontains `infix`
@@@]]

F.has_infix = function(xs, infix) return F_is_infix_of(infix, xs) end
mt.__index.has_infix = F.has_infix

--[[@@@
```lua
F.is_subsequence_of(seq, xs)
seq:is_subsequence_of(xs)
```
> Returns `true` if all the elements of the first list occur, in order, in the second. The elements do not have to occur consecutively.
@@@]]

function  F.is_subsequence_of(seq, xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
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
end
mt.__index.is_subsequence_of = F.is_subsequence_of

--[[@@@
```lua
F.is_submap_of(t1, t2)
t1:is_submap_of(t2)
```
> returns true if all keys in t1 are in t2.
@@@]]

function F.is_submap_of(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] == nil then return false end
    end
    return true
end
mt.__index.is_submap_of = F.is_submap_of

--[[@@@
```lua
F.map_contains(t1, t2)
t1:map_contains(t2)
```
> returns true if all keys in t2 are in t1.
@@@]]

function F.map_contains(t1, t2)
    for k, _ in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end
mt.__index.map_contains = F.map_contains

--[[@@@
```lua
F.is_proper_submap_of(t1, t2)
t1:is_proper_submap_of(t2)
```
> returns true if all keys in t1 are in t2 and t1 keys and t2 keys are different.
@@@]]

function F.is_proper_submap_of(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] == nil then return false end
    end
    for k, _ in pairs(t2) do
        if t1[k] == nil then return true end
    end
    return false
end
mt.__index.is_proper_submap_of = F.is_proper_submap_of

--[[@@@
```lua
F.map_strictly_contains(t1, t2)
t1:map_strictly_contains(t2)
```
> returns true if all keys in t2 are in t1.
@@@]]

function F.map_strictly_contains(t1, t2)
    for k, _ in pairs(t2) do
        if t1[k] == nil then return false end
    end
    for k, _ in pairs(t1) do
        if t2[k] == nil then return true end
    end
    return false
end
mt.__index.map_strictly_contains = F.map_strictly_contains

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

do

local F_elem = function(x, xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
    for i = 1, #xs do
        if comp_eq(xs[i], x) then return true end
    end
    return false
end
F.elem = F_elem
mt.__index.elem = function(xs, x, comp_eq) return F_elem(x, xs, comp_eq) end

end

--[[@@@
```lua
F.not_elem(x, xs, [comp_eq])
xs:not_elem(x, [comp_eq])
```
> Returns `true` if x does not occur in xs (using the optional comp_eq function).
@@@]]

do

local function F_not_elem(x, xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
    for i = 1, #xs do
        if comp_eq(xs[i], x) then return false end
    end
    return true
end
F.not_elem = F_not_elem
mt.__index.not_elem = function(xs, x, comp_eq) return F_not_elem(x, xs, comp_eq) end

end

--[[@@@
```lua
F.lookup(x, xys, [comp_eq])
xys:lookup(x, [comp_eq])
```
> Looks up a key `x` in an association list (using the optional comp_eq function).
@@@]]

do

local function F_lookup(x, xys, comp_eq)
    comp_eq = comp_eq or F_op_eq
    for i = 1, #xys do
        if comp_eq(xys[i][1], x) then return xys[i][2] end
    end
    return nil
end
F.lookup = F_lookup
mt.__index.lookup = function(xys, x, comp_eq) return F_lookup(x, xys, comp_eq) end

end

--[[@@@
```lua
F.find(p, xs)
xs:find(p)
```
> Returns the leftmost element of xs matching the predicate p.
@@@]]

do

local function F_find(p, xs)
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then return x end
    end
    return nil
end
F.find = F_find
mt.__index.find = function(xs, p) return F_find(p, xs) end

end

--[[@@@
```lua
F.filter(p, xs)
xs:filter(p)
```
> Returns the list of those elements that satisfy the predicate p(x).
@@@]]

local function F_filter(p, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x end
    end
    return setmetatable(ys, mt)
end
F.filter = F_filter
mt.__index.filter = function(xs, p) return F_filter(p, xs) end

--[[@@@
```lua
F.filter_eq(y, xs)
xs:filter_eq(y)
F.filter_ne(y, xs)
xs:filter_ne(y)
F.filter_lt(y, xs)
xs:filter_lt(y)
F.filter_le(y, xs)
xs:filter_le(y)
F.filter_gt(y, xs)
xs:filter_gt(y)
F.filter_ge(y, xs)
xs:filter_ge(y)
```
> Returns the list of those elements that satisfy the predicate
  F.op.eq(x, y), f.op.ne(x, y), f.op.lt(x, y), f.op.le(x, y), f.op.gt(x, y), f.op.ge(x, y).
@@@]]

--[[@@@
```lua
F.filter_ueq(y, xs)
xs:filter_ueq(y)
F.filter_une(y, xs)
xs:filter_une(y)
F.filter_ult(y, xs)
xs:filter_ult(y)
F.filter_ule(y, xs)
xs:filter_ule(y)
F.filter_ugt(y, xs)
xs:filter_ugt(y)
F.filter_uge(y, xs)
xs:filter_uge(y)
```
> Returns the list of those elements that satisfy the predicate
  F.op.ueq(x, y), f.op.une(x, y), f.op.ult(x, y), f.op.ule(x, y), f.op.ugt(x, y), f.op.uge(x, y).
@@@]]

--[[@@@
```lua
F.filter_keq(y, xs)
xs:filter_keq(y)
F.filter_kne(y, xs)
xs:filter_kne(y)
F.filter_klt(y, xs)
xs:filter_klt(y)
F.filter_kle(y, xs)
xs:filter_kle(y)
F.filter_kgt(y, xs)
xs:filter_kgt(y)
F.filter_kge(y, xs)
xs:filter_kge(y)
```
> Returns the list of those elements that satisfy the predicate
  F.op.keq(x, y), f.op.kne(x, y), f.op.klt(x, y), f.op.kle(x, y), f.op.kgt(x, y), f.op.kge(x, y).
@@@]]

for _, op in ipairs{"eq", "ne", "lt", "le", "gt", "ge"} do
    for _, t in ipairs{"", "u", "k"} do
        local f = F.op[t..op]
        F["filter_"..t..op]          = function(y, xs) return F_filter(function(x) return f(x, y) end, xs) end
        mt.__index["filter_"..t..op] = function(xs, y) return F_filter(function(x) return f(x, y) end, xs) end
    end
end

--[[@@@
```lua
F.filteri(p, xs)
xs:filteri(p)
```
> Returns the list of those elements that satisfy the predicate p(i, x).
@@@]]

do

local function F_filteri(p, xs)
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(i, x) then ys[#ys+1] = x end
    end
    return setmetatable(ys, mt)
end
F.filteri = F_filteri
mt.__index.filteri = function(xs, p) return F_filteri(p, xs) end

end

--[[@@@
```lua
F.filter2t(p, xs)
xs:filter2t(p)
```
> filters the elements of `xs` with `p` and returns the table `{p(xs[1])=xs[1], p(xs[2])=xs[2], ...}`
> where `p(x)` is a predicate that returns the key for `x` in the returned table (`nil` to reject `x`).
@@@]]

do

local function F_filter2t(p, xs)
    local t = {}
    for i = 1, #xs do
        local v = xs[i]
        local k = p(v)
        if k~=nil then rawset(t, k, v) end
    end
    return setmetatable(t, mt)
end
F.filter2t = F_filter2t
mt.__index.filter2t = function(xs, p) return F_filter2t(p, xs) end

end

--[[@@@
```lua
F.filteri2t(p, xs)
xs:filteri2t(p)
```
> filters the elements of `xs` with `p` and returns the table `{p(1, xs[1])=xs[1], p(2, xs[2])=xs[2], ...}`
> where `p(i, x)` is a predicate that returns the key for `x` in the returned table (`nil` to reject `x`).
@@@]]

do

local function F_filteri2t(p, xs)
    local t = {}
    for i = 1, #xs do
        local v = xs[i]
        local k = p(i, v)
        if k~=nil then rawset(t, k, v) end
    end
    return setmetatable(t, mt)
end
F.filteri2t = F_filteri2t
mt.__index.filteri2t = function(xs, p) return F_filteri2t(p, xs) end

end

--[[@@@
```lua
F.filtert(p, t)
t:filtert(p)
```
> Returns the table of those values that satisfy the predicate p(v).
@@@]]

do

local function F_filtert(p, t)
    local t2 = {}
    for k, v in pairs(t) do
        if p(v) then t2[k] = v end
    end
    return setmetatable(t2, mt)
end
F.filtert = F_filtert
mt.__index.filtert = function(t, p) return F_filtert(p, t) end

end

--[[@@@
```lua
F.filterk(p, t)
t:filterk(p)
```
> Returns the table of those values that satisfy the predicate p(k, v).
@@@]]

F_filterk = function(p, t)
    local t2 = {}
    for k, v in pairs(t) do
        if p(k, v) then t2[k] = v end
    end
    return setmetatable(t2, mt)
end
F.filterk = F_filterk
mt.__index.filterk = function(t, p) return F_filterk(p, t) end

-- filtert2a
-- filterk2a

--[[@@@
```lua
F.filtert2a(p, t)
t:filtert2a(p)
```
> filters `t` with `p` and returns the array `{t[k1], t[k2], ...}` for all `t[ki]` that satisfy `p(t[ki])`.
@@@]]

do

local function F_filtert2a(p, t)
    local ys = {}
    for _, v in F_pairs(t) do
        if p(v) then ys[#ys+1] = v end
    end
    return setmetatable(ys, mt)
end
F.filtert2a = F_filtert2a
mt.__index.filtert2a = function(t, p) return F_filtert2a(p, t) end

end

--[[@@@
```lua
F.filterk2a(f, t)
t:filterk2a(f)
```
> filters `t` with `p` and returns the array `{t[k1], t[k2], ...}` for all `t[ki]` that satisfy `p(ki, t[ki])`.
@@@]]

do

local function F_filterk2a(p, t)
    local ys = {}
    for k, v in F_pairs(t) do
        if p(k, v) then ys[#ys+1] = v end
    end
    return setmetatable(ys, mt)
end
F.filterk2a = F_filterk2a
mt.__index.filterk2a = function(t, p) return F_filterk2a(p, t) end

end

--[[@@@
```lua
F.restrict_keys(t, ks)
t:restrict_keys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

function F.restrict_keys(t, ks)
    local kset = F_from_set(F_const(true), ks)
    local function p(k, _) return kset[k] end
    return F_filterk(p, t)
end
mt.__index.restrict_keys = F.restrict_keys

--[[@@@
```lua
F.without_keys(t, ks)
t:without_keys(ks)
```
> Remove all keys in a list from a map.
@@@]]

function F.without_keys(t, ks)
    local kset = F_from_set(F_const(true), ks)
    local function p(k, _) return not kset[k] end
    return F_filterk(p, t)
end
mt.__index.without_keys = F.without_keys

--[[@@@
```lua
F.partition(p, xs)
xs:partition(p)
```
> Returns the pair of lists of elements which do and do not satisfy the predicate, respectively.
@@@]]

do

local function F_partition(p, xs)
    local ys = {}
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        if p(x) then ys[#ys+1] = x else zs[#zs+1] = x end
    end
    return setmetatable(ys, mt), setmetatable(zs, mt)
end
F.partition = F_partition
mt.__index.partition = function(xs, p) return F_partition(p, xs) end

end

--[[@@@
```lua
F.table_partition(p, t)
t:table_partition(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

do

local function F_table_partition(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(v) then t1[k] = v else t2[k] = v end
    end
    return setmetatable(t1, mt), setmetatable(t2, mt)
end
F.table_partition = F_table_partition
mt.__index.table_partition = function(t, p) return F_table_partition(p, t) end

end

--[[@@@
```lua
F.table_partition_with_key(p, t)
t:table_partition_with_key(p)
```
> Partition the map according to a predicate. The first map contains all elements that satisfy the predicate, the second all elements that fail the predicate.
@@@]]

do

local function F_table_partition_with_key(p, t)
    local t1, t2 = {}, {}
    for k, v in pairs(t) do
        if p(k, v) then t1[k] = v else t2[k] = v end
    end
    return setmetatable(t1, mt), setmetatable(t2, mt)
end
F.table_partition_with_key = F_table_partition_with_key
mt.__index.table_partition_with_key = function(t, p) return F_table_partition_with_key(p, t) end

end

--[[@@@
```lua
F.elem_index(x, xs)
xs:elem_index(x)
```
> Returns the index of the first element in the given list which is equal to the query element.
@@@]]

do

local function F_elem_index(x, xs)
    for i = 1, #xs do
        if x == xs[i] then return i end
    end
    return nil
end
F.elem_index = F_elem_index
mt.__index.elem_index = function(xs, x) return F_elem_index(x, xs) end

end

--[[@@@
```lua
F.elem_indices(x, xs)
xs:elem_indices(x)
```
> Returns the indices of all elements equal to the query element, in ascending order.
@@@]]

do

local function F_elem_indices(x, xs)
    local indices = {}
    for i = 1, #xs do
        if x == xs[i] then indices[#indices+1] = i end
    end
    return setmetatable(indices, mt)
end
F.elem_indices = F_elem_indices
mt.__index.elem_indices = function(xs, x) return F_elem_indices(x, xs) end

end

--[[@@@
```lua
F.find_index(p, xs)
xs:find_index(p)
```
> Returns the index of the first element in the list satisfying the predicate.
@@@]]

do

local function F_find_index(p, xs)
    for i = 1, #xs do
        if p(xs[i]) then return i end
    end
    return nil
end
F.find_index = F_find_index
mt.__index.find_index = function(xs, p) return F_find_index(p, xs) end

end

--[[@@@
```lua
F.find_indices(p, xs)
xs:find_indices(p)
```
> Returns the indices of all elements satisfying the predicate, in ascending order.
@@@]]

do

local function F_find_indices(p, xs)
    local indices = {}
    for i = 1, #xs do
        if p(xs[i]) then indices[#indices+1] = i end
    end
    return setmetatable(indices, mt)
end
F.find_indices = F_find_indices
mt.__index.find_indices = function(xs, p) return F_find_indices(p, xs) end

end

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

F_null = function(t)
    return next(t) == nil
end
F.null = F_null
mt.__index.null = F_null

--[[@@@
```lua
#xs
F.length(xs)
xs:length()
```
> Length of a list.
@@@]]

F_length = function(xs)
    return #xs
end
F.length = F_length
mt.__index.length = F_length

--[[@@@
```lua
F.size(t)
t:size()
```
> Size of a table (number of (key, value) pairs).
@@@]]

function F.size(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n+1
    end
    return n
end
mt.__index.size = F.size

--[[------------------------------------------------------------------------@@@
## Table transformations
@@@]]

--[[@@@
```lua
F.map(f, xs)
xs:map(f)
```
> maps `f` to the elements of `xs` and returns `{f(xs[1]), f(xs[2]), ...}`
> (`nil` values are ignored)
@@@]]

F_map = function(f, xs)
    local ys = {}
    for i = 1, #xs do ys[#ys+1] = f(xs[i]) end
    return setmetatable(ys, mt)
end
F.map = F_map
mt.__index.map = function(xs, f) return F_map(f, xs) end

--[[@@@
```lua
F.mapi(f, xs)
xs:mapi(f)
```
> maps `f` to the indices and elements of `xs` and returns `{f(1, xs[1]), f(2, xs[2]), ...}`
> (`nil` values are ignored)
@@@]]

do

local function F_mapi(f, xs)
    local ys = {}
    for i = 1, #xs do ys[#ys+1] = f(i, xs[i]) end
    return setmetatable(ys, mt)
end
F.mapi = F_mapi
mt.__index.mapi = function(xs, f) return F_mapi(f, xs) end

end

--[[@@@
```lua
F.map2t(f, xs)
xs:map2t(f)
```
> maps `f` to the elements of `xs` and returns the table `{fk(xs[1])=fv(xs[1]), fk(xs[2])=fv(xs[2]), ...}`
> where `f(x)` returns two values `fk(x), fv(x)` used as the keys and values of the returned table.
> (`nil` values are ignored)
@@@]]

do

local function F_map2t(f, xs)
    local t = {}
    for i = 1, #xs do
        local k, v = f(xs[i])
        if k~=nil then rawset(t, k, v) end
    end
    return setmetatable(t, mt)
end
F.map2t = F_map2t
mt.__index.map2t = function(xs, f) return F_map2t(f, xs) end

end

--[[@@@
```lua
F.mapi2t(f, xs)
xs:mapi2t(f)
```
> maps `f` to the indices and elements of `xs` and returns `{fk(1, xs[1])=fv(1, xs[1]), fk(2, xs[2])=fv(2, xs[2]), ...}`
> where `f(i, x)` returns two values `fk(i, x), fv(i, x)` used as the keys and values of the returned table.
> (`nil` values are ignored)
@@@]]

do

local function F_mapi2t(f, xs)
    local t = {}
    for i = 1, #xs do
        local k, v = f(i, xs[i])
        if k~=nil then rawset(t, k, v) end
    end
    return setmetatable(t, mt)
end
F.mapi2t = F_mapi2t
mt.__index.mapi2t = function(xs, f) return F_mapi2t(f, xs) end

end

--[[@@@
```lua
F.mapt(f, t)
t:mapt(f)
```
> maps `f` to the values of `t` and returns `{k1=f(t[k1]), k2=f(t[k2]), ...}`
> (`nil` values are ignored)
@@@]]

do

local function F_mapt(f, t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = f(v) end
    return setmetatable(t2, mt)
end
F.mapt = F_mapt
mt.__index.mapt = function(t, f) return F_mapt(f, t) end

end

--[[@@@
```lua
F.mapk(f, t)
t:mapk(f)
```
> maps `f` to the keys and values of `t` and returns `{k1=f(k1, t[k1]), k2=f(k2, t[k2]), ...}`
> (`nil` values are ignored)
@@@]]

do

local function F_mapk(f, t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = f(k, v) end
    return setmetatable(t2, mt)
end
F.mapk = F_mapk
mt.__index.mapk = function(t, f) return F_mapk(f, t) end

end

--[[@@@
```lua
F.mapt2a(f, t)
t:mapt2a(f)
```
> maps `f` to the values of `t` and returns the array `{f(t[k1]), f(t[k2]), ...}`
> (`nil` values are ignored)
@@@]]

do

local function F_mapt2a(f, t)
    local ys = {}
    for _, v in F_pairs(t) do ys[#ys+1] = f(v) end
    return setmetatable(ys, mt)
end
F.mapt2a = F_mapt2a
mt.__index.mapt2a = function(t, f) return F_mapt2a(f, t) end

end

--[[@@@
```lua
F.mapk2a(f, t)
t:mapk2a(f)
```
> maps `f` to the keys and the values of `t` and returns the array `{f(k1, t[k1]), f(k2, t[k2]), ...}`
> (`nil` values are ignored)
@@@]]

do

local function F_mapk2a(f, t)
    local ys = {}
    for k, v in F_pairs(t) do ys[#ys+1] = f(k, v) end
    return setmetatable(ys, mt)
end
F.mapk2a = F_mapk2a
mt.__index.mapk2a = function(t, f) return F_mapk2a(f, t) end

end

--[[@@@
```lua
F.reverse(xs)
xs:reverse()
```
> reverses the order of a list
@@@]]

function F.reverse(xs)
    local ys = {}
    for i = #xs, 1, -1 do ys[#ys+1] = xs[i] end
    return setmetatable(ys, mt)
end
mt.__index.reverse = F.reverse

--[[@@@
```lua
F.transpose(xss)
xss:transpose()
```
> Transposes the rows and columns of its argument.
@@@]]

function F.transpose(xss)
    local N = #xss
    local M = max(t_unpack(F_map(F_length, xss)))
    local yss = {}
    for j = 1, M do
        local ys = {}
        for i = 1, N do ys[i] = xss[i][j] end
        yss[j] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
end
mt.__index.transpose = F.transpose

--[[@@@
```lua
F.update(f, k, t)
t:update(f, k)
```
> Updates the value `x` at `k`. If `f(x)` is nil, the element is deleted. Otherwise the key `k` is bound to the value `f(x)`.
>
> **Warning**: in-place modification.
@@@]]

do

local function F_update(f, k, t)
    t[k] = f(t[k])
    return t
end
F.update = F_update
mt.__index.update = function(t, f, k) return F_update(f, k, t) end

end

--[[@@@
```lua
F.updatek(f, k, t)
t:updatek(f, k)
```
> Updates the value `x` at `k`. If `f(k, x)` is nil, the element is deleted. Otherwise the key `k` is bound to the value `f(k, x)`.
>
> **Warning**: in-place modification.
@@@]]

do

local function F_updatek(f, k, t)
    t[k] = f(k, t[k])
    return t
end
F.updatek = F_updatek
mt.__index.updatek = function(t, f, k) return F_updatek(f, k, t) end

end

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

F_foreach = function(xs, f)
    for i = 1, #xs do f(xs[i]) end
end
F.foreach = F_foreach
mt.__index.foreach = F_foreach

--[[@@@
```lua
F.foreachi(xs, f)
xs:foreachi(f)
```
> calls `f` with the indices and elements of `xs` (`f(i, xi)` for `xi` in `xs`)
@@@]]

function F.foreachi(xs, f)
    for i = 1, #xs do f(i, xs[i]) end
end
mt.__index.foreachi = F.foreachi

--[[@@@
```lua
F.foreacht(t, f)
t:foreacht(f)
```
> calls `f` with the values of `t` (`f(v)` for `v` in `t` such that `v = t[k]`)
@@@]]

function F.foreacht(t, f)
    for _, v in F_pairs(t) do f(v) end
end
mt.__index.foreacht = F.foreacht

--[[@@@
```lua
F.foreachk(t, f)
t:foreachk(f)
```
> calls `f` with the keys and values of `t` (`f(k, v)` for (`k`, `v`) in `t` such that `v = t[k]`)
@@@]]

function F.foreachk(t, f)
    for k, v in F_pairs(t) do f(k, v) end
end
mt.__index.foreachk = F.foreachk

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

do

local function F_fold(fzx, z, xs)
    for i = 1, #xs do
        z = fzx(z, xs[i])
    end
    return z
end
F.fold = F_fold
mt.__index.fold = function(xs, fzx, z) return F_fold(fzx, z, xs) end

end

--[[@@@
```lua
F.foldi(f, x, xs)
xs:foldi(f, x)
```
> Left-associative fold of a list (`f(...f(f(x, 1, xs[1]), 2, xs[2]), ...)`).
@@@]]

do

local function F_foldi(fzx, z, xs)
    for i = 1, #xs do
        z = fzx(z, i, xs[i])
    end
    return z
end
F.foldi = F_foldi
mt.__index.foldi = function(xs, fzx, z) return F_foldi(fzx, z, xs) end

end

--[[@@@
```lua
F.fold1(f, xs)
xs:fold1(f)
```
> Left-associative fold of a list, the initial value is `xs[1]`.
@@@]]

do

local function F_fold1(fzx, xs)
    local z = xs[1]
    for i = 2, #xs do
        z = fzx(z, xs[i])
    end
    return z
end
F.fold1 = F_fold1
mt.__index.fold1 = function(xs, fzx) return F_fold1(fzx, xs) end

end

--[[@@@
```lua
F.foldt(f, x, t)
t:foldt(f, x)
```
> Left-associative fold of a table (in the order given by F.pairs).
@@@]]

do

local function F_foldt(fzx, z, t)
    for _, v in F_pairs(t) do
        z = fzx(z, v)
    end
    return z
end
F.foldt = F_foldt
mt.__index.foldt = function(t, fzx, z) return F_foldt(fzx, z, t) end

end

--[[@@@
```lua
F.foldk(f, x, t)
t:foldk(f, x)
```
> Left-associative fold of a table (in the order given by F.pairs).
@@@]]

do

local function F_foldk(fzx, z, t)
    for k, v in F_pairs(t) do
        z = fzx(z, k, v)
    end
    return z
end
F.foldk = F_foldk
mt.__index.foldk = function(t, fzx, z) return F_foldk(fzx, z, t) end

end

--[[@@@
```lua
F.land(bs)
bs:land()
```
> Returns the conjunction of a container of booleans.
@@@]]

function F.land(bs)
    for i = 1, #bs do if not bs[i] then return false end end
    return true
end
mt.__index.land = F.land

--[[@@@
```lua
F.lor(bs)
bs:lor()
```
> Returns the disjunction of a container of booleans.
@@@]]

function F.lor(bs)
    for i = 1, #bs do if bs[i] then return true end end
    return false
end
mt.__index.lor = F.lor

--[[@@@
```lua
F.any(p, xs)
xs:any(p)
```
> Determines whether any element of the structure satisfies the predicate.
@@@]]

do

local function F_any(p, xs)
    for i = 1, #xs do if p(xs[i]) then return true end end
    return false
end
F.any = F_any
mt.__index.any = function(xs, p) return F_any(p, xs) end

end

--[[@@@
```lua
F.all(p, xs)
xs:all(p)
```
> Determines whether all elements of the structure satisfy the predicate.
@@@]]

do

local function F_all(p, xs)
    for i = 1, #xs do if not p(xs[i]) then return false end end
    return true
end
F.all = F_all
mt.__index.all = function(xs, p) return F_all(p, xs) end

end

--[[@@@
```lua
F.sum(xs)
xs:sum()
```
> Returns the sum of the numbers of a structure.
@@@]]

function F.sum(xs)
    local s = 0
    for i = 1, #xs do s = s + xs[i] end
    return s
end
mt.__index.sum = F.sum

--[[@@@
```lua
F.product(xs)
xs:product()
```
> Returns the product of the numbers of a structure.
@@@]]

function F.product(xs)
    local p = 1
    for i = 1, #xs do p = p * xs[i] end
    return p
end
mt.__index.product = F.product

--[[@@@
```lua
F.maximum(xs, [comp_lt])
xs:maximum([comp_lt])
```
> The largest element of a non-empty structure, according to the optional comparison function.
@@@]]

function F.maximum(xs, comp_lt)
    if #xs == 0 then return nil end
    comp_lt = comp_lt or F_op_lt
    local xmax = xs[1]
    for i = 2, #xs do
        if not comp_lt(xs[i], xmax) then xmax = xs[i] end
    end
    return xmax
end
mt.__index.maximum = F.maximum

--[[@@@
```lua
F.minimum(xs, [comp_lt])
xs:minimum([comp_lt])
```
> The least element of a non-empty structure, according to the optional comparison function.
@@@]]

F_minimum = function(xs, comp_lt)
    if #xs == 0 then return nil end
    comp_lt = comp_lt or F_op_lt
    local min = xs[1]
    for i = 2, #xs do
        if comp_lt(xs[i], min) then min = xs[i] end
    end
    return min
end
F.minimum = F_minimum
mt.__index.minimum = F_minimum

--[[@@@
```lua
F.scan(f, x, xs)
xs:scan(f, x)
```
> Similar to `fold` but returns a list of successive reduced values from the left.
@@@]]

do

local function F_scan(fzx, z, xs)
    local zs = {z}
    for i = 1, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return setmetatable(zs, mt)
end
F.scan = F_scan
mt.__index.scan = function(xs, fzx, z) return F_scan(fzx, z, xs) end

end

--[[@@@
```lua
F.scan1(f, xs)
xs:scan1(f)
```
> Like `scan` but the initial value is `xs[1]`.
@@@]]

do

local function F_scan1(fzx, xs)
    local z = xs[1]
    local zs = {z}
    for i = 2, #xs do
        z = fzx(z, xs[i])
        zs[#zs+1] = z
    end
    return setmetatable(zs, mt)
end
F.scan1 = F_scan1
mt.__index.scan1 = function(xs, fzx) return F_scan1(fzx, xs) end

end

--[[@@@
```lua
F.concat_map(f, xs)
xs:concat_map(f)
```
> Map a function over all the elements of a container and concatenate the resulting lists.
@@@]]

do

local function F_concat_map(fx, xs)
    return F_concat(F_map(fx, xs))
end
F.concat_map = F_concat_map
mt.__index.concat_map = function(xs, fx) return F_concat_map(fx, xs) end

end

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

F_zip = function(xss, f)
    local yss = {}
    local ns = F_minimum(F_map(F_length, xss))
    if f then
        for i = 1, ns do
            local ys = F_map(function(xs) return xs[i] end, xss)
            yss[i] = f(t_unpack(ys))
        end
    else
        for i = 1, ns do
            local ys = F_map(function(xs) return xs[i] end, xss)
            yss[i] = ys
        end
    end
    return setmetatable(yss, mt)
end
F.zip = F_zip
mt.__index.zip = F_zip

--[[@@@
```lua
F.unzip(xss)
xss:unzip()
```
> Transforms a list of n-tuples into n lists
@@@]]

function F.unzip(xss)
    return t_unpack(F_zip(xss))
end
mt.__index.unzip = F.unzip

--[[@@@
```lua
F.zip_with(f, xss)
xss:zip_with(f)
```
> `zip_with` generalises `zip` by zipping with the function given as the first argument, instead of a tupling function.
@@@]]

function F.zip_with(f, xss) return F_zip(xss, f) end
mt.__index.zip_with = F_zip

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

function F.nub(xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
    local ys = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(x, ys[j]) then found = true; break end
        end
        if not found then ys[#ys+1] = x end
    end
    return setmetatable(ys, mt)
end
mt.__index.nub = F.nub

--[[@@@
```lua
F.delete(x, xs, [comp_eq])
xs:delete(x, [comp_eq])
```
> Removes the first occurrence of x from its list argument, according to the optional comp_eq function.
@@@]]

do

local function F_delete(x, xs, comp_eq)
    comp_eq = comp_eq or F_op_eq
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
    return setmetatable(ys, mt)
end
F.delete = F_delete
mt.__index.delete = function(xs, x, comp_eq) return F_delete(x, xs, comp_eq) end

end

--[[@@@
```lua
F.difference(xs, ys, [comp_eq])
xs:difference(ys, [comp_eq])
```
> Returns the list difference. In `difference(xs, ys)`{.lua} the first occurrence of each element of ys in turn (if any) has been removed from xs, according to the optional comp_eq function.
@@@]]

function F.difference(xs, ys, comp_eq)
    comp_eq = comp_eq or F_op_eq
    local zs = {}
    ys = {t_unpack(ys)}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(ys[j], x) then
                found = true
                t_remove(ys, j)
                break
            end
        end
        if not found then zs[#zs+1] = x end
    end
    return setmetatable(zs, mt)
end
mt.__index.difference = F.difference

--[[@@@
```lua
F.union(xs, ys, [comp_eq])
xs:union(ys, [comp_eq])
```
> Returns the list union of the two lists. Duplicates, and elements of the first list, are removed from the the second list, but if the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

function F.union(xs, ys, comp_eq)
    comp_eq = comp_eq or F_op_eq
    local zs = {t_unpack(xs)}
    for i = 1, #ys do
        local y = ys[i]
        local found = false
        for j = 1, #zs do
            if comp_eq(y, zs[j]) then found = true; break end
        end
        if not found then zs[#zs+1] = y end
    end
    return setmetatable(zs, mt)
end
mt.__index.union = F.union

--[[@@@
```lua
F.intersection(xs, ys, [comp_eq])
xs:intersection(ys, [comp_eq])
```
> Returns the list intersection of two lists. If the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

function F.intersection(xs, ys, comp_eq)
    comp_eq = comp_eq or F_op_eq
    local zs = {}
    for i = 1, #xs do
        local x = xs[i]
        local found = false
        for j = 1, #ys do
            if comp_eq(x, ys[j]) then found = true; break end
        end
        if found then zs[#zs+1] = x end
    end
    return setmetatable(zs, mt)
end
mt.__index.intersection = F.intersection

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

F_merge = function(ts)
    local u = {}
    for i = 1, #ts do
        for k, v in pairs(ts[i]) do u[k] = v end
    end
    return setmetatable(u, mt)
end
F.merge = F_merge
mt.__index.merge = F_merge

F.table_union = F_merge
mt.__index.table_union = F_merge

--[[@@@
```lua
F.merge_with(f, ts)
ts:merge_with(f)
F.table_union_with(f, ts)
ts:table_union_with(f)
```
> Right-biased union of tables with a combining function.
@@@]]

do

local function F_merge_with(f, ts)
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
    return setmetatable(u, mt)
end
F.merge_with = F_merge_with
mt.__index.merge_with = function(ts, f) return F_merge_with(f, ts) end

F.table_union_with = F_merge_with
mt.__index.table_union_with = mt.__index.merge_with

end

--[[@@@
```lua
F.merge_with_key(f, ts)
ts:merge_with_key(f)
F.table_union_with_key(f, ts)
ts:table_union_with_key(f)
```
> Right-biased union of tables with a combining function.
@@@]]

do

local function F_merge_with_key(f, ts)
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
    return setmetatable(u, mt)
end
F.merge_with_key = F_merge_with_key
mt.__index.merge_with_key = function(ts, f) return F_merge_with_key(f, ts) end

F.table_union_with_key = F_merge_with_key
mt.__index.table_union_with_key = mt.__index.merge_with_key

end

--[[@@@
```lua
F.table_difference(t1, t2)
t1:table_difference(t2)
```
> Difference of two maps. Return elements of the first map not existing in the second map.
@@@]]

function F.table_difference(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] == nil then t[k] = v end end
    return setmetatable(t, mt)
end
mt.__index.table_difference = F.table_difference

--[[@@@
```lua
F.table_difference_with(f, t1, t2)
t1:table_difference_with(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

do

local function F_table_difference_with(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(v1, v2)
        end
    end
    return setmetatable(t, mt)
end
F.table_difference_with = F_table_difference_with
mt.__index.table_difference_with = function(t1, f, t2) return F_table_difference_with(f, t1, t2) end

end

--[[@@@
```lua
F.table_difference_with_key(f, t1, t2)
t1:table_difference_with_key(f, t2)
```
> Union with a combining function.
@@@]]

do

local function F_table_difference_with_key(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            t[k] = v1
        else
            t[k] = f(k, v1, v2)
        end
    end
    return setmetatable(t, mt)
end
F.table_difference_with_key = F_table_difference_with_key
mt.__index.table_difference_with_key = function(t1, f, t2) return F_table_difference_with_key(f, t1, t2) end

end

--[[@@@
```lua
F.table_intersection(t1, t2)
t1:table_intersection(t2)
```
> Intersection of two maps. Return data in the first map for the keys existing in both maps.
@@@]]

function F.table_intersection(t1, t2)
    local t = {}
    for k, v in pairs(t1) do if t2[k] ~= nil then t[k] = v end end
    return setmetatable(t, mt)
end
mt.__index.table_intersection = F.table_intersection

--[[@@@
```lua
F.table_intersection_with(f, t1, t2)
t1:table_intersection_with(f, t2)
```
> Difference with a combining function. When two equal keys are encountered, the combining function is applied to the values of these keys.
@@@]]

do

local function F_table_intersection_with(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(v1, v2)
        end
    end
    return setmetatable(t, mt)
end
F.table_intersection_with = F_table_intersection_with
mt.__index.table_intersection_with = function(t1, f, t2) return F_table_intersection_with(f, t1, t2) end

end

--[[@@@
```lua
F.table_intersection_with_key(f, t1, t2)
t1:table_intersection_with_key(f, t2)
```
> Union with a combining function.
@@@]]

do

local function F_table_intersection_with_key(f, t1, t2)
    local t = {}
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        if v2 ~= nil then
            t[k] = f(k, v1, v2)
        end
    end
    return setmetatable(t, mt)
end
F.table_intersection_with_key = F_table_intersection_with_key
mt.__index.table_intersection_with_key = function(t1, f, t2) return F_table_intersection_with_key(f, t1, t2) end

end

--[[@@@
```lua
F.disjoint(t1, t2)
t1:disjoint(t2)
```
> Check the intersection of two maps is empty.
@@@]]

function F.disjoint(t1, t2)
    for k, _ in pairs(t1) do if t2[k] ~= nil then return false end end
    return true
end
mt.__index.disjoint = F.disjoint

--[[@@@
```lua
F.table_compose(t1, t2)
t1:table_compose(t2)
```
> Relate the keys of one map to the values of the other, by using the values of the former as keys for lookups in the latter.
@@@]]

function F.table_compose(t1, t2)
    local t = {}
    for k2, v2 in pairs(t2) do
        local v1 = t1[v2]
        t[k2] = v1
    end
    return setmetatable(t, mt)
end
mt.__index.table_compose = F.table_compose

--[[@@@
```lua
F.Nil
```
> `F.Nil` is a singleton used to represent `nil` (see `F.patch`)
@@@]]
Nil = setmetatable({}, {
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

do

local function F_patch(t1, t2)
    if t2 == nil then return t1 end -- value not patched
    if t2 == Nil then return nil end -- remove t1
    if type(t1) ~= "table" then return t2 end -- replace a scalar field by a scalar or a table
    if type(t2) ~= "table" then return t2 end -- a scalar replaces a scalar or a table
    local t = {}
    -- patch fields from t1 with values from t2
    for k, v1 in pairs(t1) do
        local v2 = t2[k]
        t[k] = F_patch(v1, v2)
    end
    -- add new values from t2
    for k, v2 in pairs(t2) do
        local v1 = t1[k]
        if v1 == nil then
            t[k] = v2
        end
    end
    return setmetatable(t, mt)
end

F.patch = F_patch
mt.__index.patch = F_patch

end

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

function F.sort(xs, comp_lt)
    local ys = {}
    for i = 1, #xs do ys[i] = xs[i] end
    t_sort(ys, comp_lt)
    return setmetatable(ys, mt)
end
mt.__index.sort = F.sort

--[[@@@
```lua
F.sort_on(f, xs, [comp_lt])
xs:sort_on(f, [comp_lt])
```
> Sorts a list by comparing the results of a key function applied to each element, according to the optional comp_lt function.
@@@]]

do

local function F_sort_on(f, xs, comp_lt)
    comp_lt = comp_lt or F_op_lt
    local ys = {}
    for i = 1, #xs do ys[i] = {f(xs[i]), xs[i]} end
    t_sort(ys, function(a, b) return comp_lt(a[1], b[1]) end)
    local zs = {}
    for i = 1, #ys do zs[i] = ys[i][2] end
    return setmetatable(zs, mt)
end
F.sort_on = F_sort_on
mt.__index.sort_on = function(xs, f, comp_lt) return F_sort_on(f, xs, comp_lt) end

end

--[[@@@
```lua
F.insert(x, xs, [comp_lt])
xs:insert(x, [comp_lt])
```
> Inserts the element into the list at the first position where it is less than or equal to the next element, according to the optional comp_lt function.
@@@]]

do

local function F_insert(x, xs, comp_lt)
    comp_lt = comp_lt or F_op_lt
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
    return setmetatable(ys, mt)
end
F.insert = F_insert
mt.__index.insert = function(xs, x, comp_lt) return F_insert(x, xs, comp_lt) end

end

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

do

local function F_subsequences(xs)
    if F_null(xs) then return setmetatable({{}}, mt) end
    local inits = F_subsequences(F_init(xs))
    local last = F_last(xs)
    return inits .. F_map(function(seq) return F_concat{seq, {last}} end, inits)
end
F.subsequences = F_subsequences
mt.__index.subsequences = F_subsequences

end

--[[@@@
```lua
F.permutations(xs)
xs:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]

F_permutations = function(xs)
    local perms = {}
    local n = #xs
    xs = F_clone(xs)
    local function permute(k)
        if k > n then perms[#perms+1] = F_clone(xs)
        else
            for i = k, n do
                xs[k], xs[i] = xs[i], xs[k]
                permute(k+1)
                xs[k], xs[i] = xs[i], xs[k]
            end
        end
    end
    permute(1)
    return setmetatable(perms, mt)
end
F.permutations = F_permutations
mt.__index.permutations = F_permutations

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

s_chars = function(s, i, j)
    return F_map(s_char, s_bytes(s, i, j))
end
string.chars = s_chars

--[[@@@
```lua
string.bytes(s, i, j)
s:bytes(i, j)
```
> Returns the list of byte codes of a string between indices i and j, or the whole string if i and j are not provided.
@@@]]

s_bytes = function(s, i, j)
    return setmetatable({s_byte(s, i or 1, j or -1)}, mt)
end
string.bytes = s_bytes

--[[@@@
```lua
string.head(s)
s:head()
```
> Extract the first element of a string.
@@@]]

s_head = function(s)
    if #s == 0 then return nil end
    return s_sub(s, 1, 1)
end
string.head = s_head

--[[@@@
```lua
sting.last(s)
s:last()
```
> Extract the last element of a string.
@@@]]

s_last = function(s)
    if #s == 0 then return nil end
    return s_sub(s, -1)
end
string.last = s_last

--[[@@@
```lua
string.tail(s)
s:tail()
```
> Extract the elements after the head of a string
@@@]]

s_tail = function(s)
    if #s == 0 then return nil end
    return s_sub(s, 2)
end
string.tail = s_tail

--[[@@@
```lua
string.init(s)
s:init()
```
> Return all the elements of a string except the last one.
@@@]]

s_init = function(s)
    if #s == 0 then return nil end
    return s_sub(s, 1, -2)
end
string.init = s_init

--[[@@@
```lua
string.uncons(s)
s:uncons()
```
> Decompose a string into its head and tail.
@@@]]

function string.uncons(s)
    return s_head(s), s_tail(s)
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
    local cs = {}
    for i = 1, #s-1 do
        cs[#cs+1] = s_sub(s, i, i)
        cs[#cs+1] = c
    end
    cs[#cs+1] = s_sub(s, -1)
    return t_concat(cs)
end

--[[@@@
```lua
string.intercalate(s, ss)
s:intercalate(ss)
```
> Inserts the string s in between the strings in ss and concatenates the result.
@@@]]

function string.intercalate(s, ss)
    return t_concat(ss, s)
end

--[[@@@
```lua
string.subsequences(s)
s:subsequences()
```
> Returns the list of all subsequences of the argument.
@@@]]

local function s_subsequences(s)
    if s=="" then return {""} end
    local inits = s_subsequences(s_init(s))
    local last = s_last(s)
    return inits .. F_map(function(seq) return seq..last end, inits)
end
string.subsequences = s_subsequences

--[[@@@
```lua
string.permutations(s)
s:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]

function string.permutations(s)
    return F_map(t_concat, F_permutations(s_chars(s)))
end

--[[@@@
```lua
string.take(s, n)
s:take(n)
```
> Returns the prefix of s of length n.
@@@]]

s_take = function(s, n)
    if n <= 0 then return "" end
    return s_sub(s, 1, n)
end
string.take = s_take

--[[@@@
```lua
string.drop(s, n)
s:drop(n)
```
> Returns the suffix of s after the first n elements.
@@@]]

s_drop = function(s, n)
    if n <= 0 then return s end
    return s_sub(s, n+1)
end
string.drop = s_drop

--[[@@@
```lua
string.split_at(s, n)
s:split_at(n)
```
> Returns a tuple where first element is s prefix of length n and second element is the remainder of the string.
@@@]]

function string.split_at(s, n)
    return s_take(s, n), s_drop(s, n)
end

--[[@@@
```lua
string.take_while(s, p)
s:take_while(p)
```
> Returns the longest prefix (possibly empty) of s of elements that satisfy p.
@@@]]

function string.take_while(s, p)
    return t_concat(F_take_while(p, s_chars(s)))
end

--[[@@@
```lua
string.drop_while(s, p)
s:drop_while(p)
```
> Returns the suffix remaining after `s:take_while(p)`{.lua}.
@@@]]

function string.drop_while(s, p)
    return t_concat(F_drop_while(p, s_chars(s)))
end

--[[@@@
```lua
string.drop_while_end(s, p)
s:drop_while_end(p)
```
> Drops the largest suffix of a string in which the given predicate holds for all elements.
@@@]]

function string.drop_while_end(s, p)
    return t_concat(F_drop_while_end(p, s_chars(s)))
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
    if s_sub(s, 1, n) == prefix then return s_sub(s, n+1) end
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
    if s_sub(s, #s-n+1) == suffix then return s_sub(s, 1, #s-n) end
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
        ss[#ss+1] = s_sub(s, 1, i)
    end
    return setmetatable(ss, mt)
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
        ss[#ss+1] = s_sub(s, i)
    end
    return setmetatable(ss, mt)
end

--[[@@@
```lua
string.is_prefix_of(prefix, s)
prefix:is_prefix_of(s)
```
> Returns `true` iff the first string is a prefix of the second.
@@@]]

function string.is_prefix_of(prefix, s)
    return s_sub(s, 1, #prefix) == prefix
end

--[[@@@
```lua
string.has_prefix(s, prefix)
s:has_prefix(prefix)
```
> Returns `true` iff the second string is a prefix of the first.
@@@]]

function string.has_prefix(s, prefix)
    return s_sub(s, 1, #prefix) == prefix
end

--[[@@@
```lua
string.is_suffix_of(suffix, s)
suffix:is_suffix_of(s)
```
> Returns `true` iff the first string is a suffix of the second.
@@@]]

function string.is_suffix_of(suffix, s)
    return s_sub(s, #s-#suffix+1) == suffix
end

--[[@@@
```lua
string.has_suffix(s, suffix)
s:has_suffix(suffix)
```
> Returns `true` iff the second string is a suffix of the first.
@@@]]

function string.has_suffix(s, suffix)
    return s_sub(s, #s-#suffix+1) == suffix
end

--[[@@@
```lua
string.is_infix_of(infix, s)
infix:is_infix_of(s)
```
> Returns `true` iff the first string is contained, wholly and intact, anywhere within the second.
@@@]]

function string.is_infix_of(infix, s)
    return s_find(s, infix) ~= nil
end

--[[@@@
```lua
string.has_infix(s, infix)
s:has_infix(infix)
```
> Returns `true` iff the second string is contained, wholly and intact, anywhere within the first.
@@@]]

function string.has_infix(s, infix)
    return s_find(s, infix) ~= nil
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
    local iterator = s_gmatch(s, pattern, init)
    local ms = setmetatable({}, mt)
    while true do
        local xs = {iterator()}
        if #xs == 0 then return ms end
        ms[#ms+1] = #xs==1 and xs[1] or xs
    end
end

--[[@@@
```lua
string.split(s, sep, maxsplit, plain)
s:split(sep, maxsplit, plain)
```
> Splits a string `s` around the separator `sep`. `maxsplit` is the maximal number of separators. If `plain` is true then the separator is a plain string instead of a Lua string pattern.
@@@]]

s_split = function(s, sep, maxsplit, plain)
    assert(sep and sep ~= "")
    maxsplit = maxsplit or (1/0)
    local items = {}
    if #s > 0 then
        local init = 1
        for _ = 1, maxsplit do
            local m, n = s_find(s, sep, init, plain)
            if m and m <= n then
                t_insert(items, s_sub(s, init, m-1))
                init = n + 1
            else
                break
            end
        end
        t_insert(items, s_sub(s, init))
    end
    return setmetatable(items, mt)
end
string.split = s_split

--[[@@@
```lua
string.lines(s)
s:lines()
```
> Splits the argument into a list of lines stripped of their terminating `\n` characters.
@@@]]

function string.lines(s)
    local lines = s_split(s, '\r?\n\r?')
    if lines[#lines] == "" and s_match(s, '\r?\n\r?$') then t_remove(lines) end
    return setmetatable(lines, mt)
end

--[[@@@
```lua
string.words(s)
s:words()
```
> Breaks a string up into a list of words, which were delimited by white space.
@@@]]

function string.words(s)
    local words = s_split(s, '%s+')
    if words[1] == "" and s_match(s, '^%s+') then t_remove(words, 1) end
    if words[#words] == "" and s_match(s, '%s+$') then t_remove(words) end
    return setmetatable(words, mt)
end

--[[@@@
```lua
F.unlines(xs)
xs:unlines()
```
> Appends a `\n` character to each input string, then concatenates the results.
@@@]]

function F.unlines(xs)
    local s = {}
    for i = 1, #xs do
        s[#s+1] = xs[i]
        s[#s+1] = "\n"
    end
    return t_concat(s)
end
mt.__index.unlines = F.unlines

--[[@@@
```lua
string.unwords(xs)
xs:unwords()
```
> Joins words with separating spaces.
@@@]]

function F.unwords(xs)
    return t_concat(xs, " ")
end
mt.__index.unwords = F.unwords

--[[@@@
```lua
string.ltrim(s)
s:ltrim()
```
> Removes heading spaces
@@@]]

function string.ltrim(s)
    return (s_match(s, "^%s*(.*)"))
end

--[[@@@
```lua
string.rtrim(s)
s:rtrim()
```
> Removes trailing spaces
@@@]]

function string.rtrim(s)
    return (s_match(s, "(.-)%s*$"))
end

--[[@@@
```lua
string.trim(s)
s:trim()
```
> Removes heading and trailing spaces
@@@]]

function string.trim(s)
    return (s_match(s, "^%s*(.-)%s*$"))
end

--[[@@@
```lua
string.ljust(s, w, [c])
s:ljust(w)
```
> Left-justify `s` by appending spaces (or the character `c`).
  The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.ljust(s, w, c)
    return s .. s_rep(c or " ", w-#s)
end

--[[@@@
```lua
string.rjust(s, w, [c])
s:rjust(w)
```
> Right-justify `s` by prepending spaces (or the character `c`).
  The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.rjust(s, w, c)
    return s_rep(c or " ", w-#s) .. s
end

--[[@@@
```lua
string.center(s, w)
s:center(w)
```
> Center `s` by appending and prepending spaces (or the character `c`).
  The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.center(s, w, c)
    c = c or " "
    local l = (w-#s)//2
    local r = (w-#s)-l
    return s_rep(c, l) .. s .. s_rep(c, r)
end

--[[@@@
```lua
string.cap(s)
s:cap()
```
> Capitalizes a string. The first character is upper case, other are lower case.
@@@]]

s_cap = function(s)
    return s_upper(s_sub(s, 1, 1)) .. s_lower(s_sub(s, 2))
end
string.cap = s_cap

--[[------------------------------------------------------------------------@@@
## Identifier formatting
@@@]]

local function split_identifier(...)
    local words = {}
    local function add_word(name)
        -- an upper case letter starts a new word
        name = s_gsub(tostring(name), "([^%u])(%u)", "%1_%2")
        -- split words
        for w in s_gmatch(name, "%w+") do words[#words+1] = w end
    end
    F_foreach(F_flatten{...}, add_word)
    return setmetatable(words, mt)
end

--[[@@@
```lua
string.lower_snake_case(s)              -- e.g.: hello_world
string.upper_snake_case(s)              -- e.g.: HELLO_WORLD
string.lower_camel_case(s)              -- e.g.: helloWorld
string.upper_camel_case(s)              -- e.g.: HelloWorld
string.dotted_lower_snake_case(s)       -- e.g.: hello.world
string.dotted_upper_snake_case(s)       -- e.g.: HELLO.WORLD

F.lower_snake_case(s)                   -- e.g.: hello_world
F.upper_snake_case(s)                   -- e.g.: HELLO_WORLD
F.lower_camel_case(s)                   -- e.g.: helloWorld
F.upper_camel_case(s)                   -- e.g.: HelloWorld
F.dotted_lower_snake_case(s)            -- e.g.: hello.world
F.dotted_upper_snake_case(s)            -- e.g.: HELLO.WORLD

s:lower_snake_case()                    -- e.g.: hello_world
s:upper_snake_case()                    -- e.g.: HELLO_WORLD
s:lower_camel_case()                    -- e.g.: helloWorld
s:upper_camel_case()                    -- e.g.: HelloWorld
s:dotted_lower_snake_case()             -- e.g.: hello.world
s:dotted_upper_snake_case()             -- e.g.: HELLO.WORLD
```
> Convert an identifier using some wellknown naming conventions.
  `s` can be a string or a list of strings.
@@@]]

function string.lower_snake_case(...)
    return t_concat(F_map(s_lower, split_identifier(...)), "_")
end

function string.upper_snake_case(...)
    return t_concat(F_map(s_upper, split_identifier(...)), "_")
end

function string.lower_camel_case(...)
    return (s_gsub(t_concat(F_map(s_cap, split_identifier(...))), "^%w", s_lower))
end

function string.upper_camel_case(...)
    return t_concat(F_map(s_cap, split_identifier(...)))
end

function string.dotted_lower_snake_case(...)
    return t_concat(F_map(s_lower, split_identifier(...)), ".")
end

function string.dotted_upper_snake_case(...)
    return t_concat(F_map(s_upper, split_identifier(...)), ".")
end

F.lower_snake_case = string.lower_snake_case
mt.__index.lower_snake_case = string.lower_snake_case

F.upper_snake_case = string.upper_snake_case
mt.__index.upper_snake_case = string.upper_snake_case

F.lower_camel_case = string.lower_camel_case
mt.__index.lower_camel_case = string.lower_camel_case

F.upper_camel_case = string.upper_camel_case
mt.__index.upper_camel_case = string.upper_camel_case

F.dotted_lower_snake_case = string.dotted_lower_snake_case
mt.__index.dotted_lower_snake_case = string.dotted_lower_snake_case

F.dotted_upper_snake_case = string.dotted_upper_snake_case
mt.__index.dotted_upper_snake_case = string.dotted_upper_snake_case

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

do

local interpolator_mt = {}

function interpolator_mt:__mod(pattern)
    assert(type(pattern)=="string" and #pattern>=3)
    return setmetatable({
        pattern = s_gsub(pattern, "^(.+)(.)(.)$", "%1(%%b%2%3)"),
        env = self.env,
    }, interpolator_mt)
end

local function chain(self, new_env)
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

local function interpolate(self, s)
    return (s_gsub(s, self.pattern, function(x)
        local y = ((assert(load("return "..s_sub(x, 2, -2), nil, "t", self.env)))())
        if type(y) == "table" or type(y) == "userdata" then
            y = tostring(y)
        end
        return y
    end))
end

function interpolator_mt:__call(s)
    if type(s) == "string" then return interpolate(self, s) end
    if type(s) == "table" then return chain(self, s) end
    error "An interpolator expects a table or a string"
end

F.I = setmetatable({env=nil}, interpolator_mt) % "%$()"

end

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

function F.choose(xs, prng)
    if prng then
        return prng:choose(xs)
    else
        return require "crypt".choose(xs)
    end
end
mt.__index.choose = F.choose

--[[@@@
```lua
F.shuffle(xs, prng)
F.shuffle(xs)   -- using the global PRNG
xs:shuffle(prng)
xs:shuffle()    -- using the global PRNG
```
returns a shuffled copy of `xs`
@@@]]

function F.shuffle(xs, prng)
    if prng then
        return prng:shuffle(xs)
    else
        return require "crypt".shuffle(xs)
    end
end
mt.__index.shuffle = F.shuffle

--[[------------------------------------------------------------------------@@@
## Schema-based table validation

This function validates the content of a table agains a schema.

A schema is a Lua table with the same structure that the input tables,
the values being replaced with values of the expected type.

| Expected type     | Specification                                                     | Exemple                   |
| ----------------- | ----------------------------------------------------------------- | ------------------------- |
| Boolean           | any boolean                                                       | `true`                    |
| Number            | any number                                                        | `0`                       |
| String            | any string                                                        | `"str"`                   |
| Array             | a table with one element (type of the array items)                | `{ "str" }`               |
| Structure         | a table with keys (names) and values (types)                      | `{ x=0, y=0 }`            |
| Enumerated type   | a list with the `"enum"` keyword and the list of values           | `{ "enum", "on", "off" }` |
| Interval          | a list with the `"range"` keyword and the min and max values      | `{ "range", -10, 10 }`    |
| Union             | a list with the `"union"` keyword and the list of accepted types  | `{ "union", 0, "str" }`   |
| Option            | a list with the `"option"` keyword and the optional type          | `{ "option", "str" }`     |
| Any value         | a list with the `"any"` keyword                                   | `{ "any" }`               |

The optional types can be combined with other types. E.g.: `{ "option", "range", -10, 10 }`.

@@@]]

--[[@@@
```lua
F.validate(schema, input, [options])
```
returns `true` if `input` is validated by `schema`. Otherwise it returns `false`
and a list of failures.

| Options           | Description                                               | Default value |
| ----------------- | --------------------------------------------------------- | ------------- |
| `options.strict`  | Strict validation (unspecified fields are not allowed)    | `true`        |
@@@]]

function F.validate(schema, input, options)

    options = options or {}
    local strict = options.strict == nil or options.strict

    local function mkpath(path, k)
        if type(k) == "string" and k:match "^[%w_]+$" then
            return (path and (path..".") or "")..k
        end
        k = ("[%q]"):format(k)
        return (path or "")..k
    end

    local function q(x)
        return ("%q"):format(x)
    end

    local function walk(t, v, path, errs)

        -- detect missing fields (if not optional)
        if v == nil then
            if type(t) ~= "table" or t[1] ~= "option" then
                errs[#errs+1] = ("%s: missing field"):format(path)
            end
            return
        end

        if type(t) == "table" and t[1] == "option" then
            t = F.tail(t)
            if #t == 1 then t = t[1] end ---@diagnostic disable-line: need-check-nil
        end

        -- check atomic types (booleans, numbers and strings)
        if type(t) ~= "table" then
            if type(v) ~= type(t) then
                errs[#errs+1] = ("%s: %s expected"):format(path, type(t))
            end
            return
        end

        -- check any type
        if t[1] == "any" then
            return
        end

        -- check ranges
        if t[1] == "range" then
            local vmin, vmax = t[2], t[3]
            if type(vmin) ~= type(vmax) then
                errs[#errs+1] = ("%s: range type mismatch [%s, %s]"):format(path, type(vmin), type(vmax))
            elseif type(v) ~= type(vmin) then
                errs[#errs+1] = ("%s: %s expected"):format(path, type(vmin))
            elseif v < vmin or v > vmax then
                errs[#errs+1] = ("%s: shall be in [%q, %q]"):format(path, vmin, vmax)
            end
            return
        end

        -- check enumerations
        if t[1] == "enum" then
            local vs = assert(F.tail(t))
            for _, vi in pairs(vs) do
                if v == vi then return end
            end
            errs[#errs+1] = ("%s: shall be %s"):format(path, F.str(F.map(q, vs), ", ", " or "))
            return
        end

        -- check unions
        if t[1] == "union" then
            local ts = assert(F.tail(t))
            for _, ti in pairs(ts) do
                local l_errs = {}
                walk(ti, v, path, l_errs)
                if #l_errs == 0 then return end
            end
            errs[#errs+1] = ("%s: shall be %s"):format(path, F.show(ts))
            return
        end

        -- check array
        if t[1] ~= nil then
            if type(v) ~= "table" then
                errs[#errs+1] = ("%s: shall be an array"):format(path)
                return
            end
            for i, vi in ipairs(v) do
                walk(t[1], vi, mkpath(path, i), errs)
            end
            return
        end

        -- check table
        if type(v) ~= "table" then
            errs[#errs+1] = ("%s: shall be a table"):format(path)
            return
        end
        if strict then
            for ki in F.pairs(v) do
                if rawget(t, ki) == nil then
                    errs[#errs+1] = ("%s: unexpected field"):format(mkpath(path, ki))
                end
            end
        end
        for ki, ti in F.pairs(t) do
            walk(ti, rawget(v, ki), mkpath(path, ki), errs)
        end

    end

    local errs = F{}
    walk(schema, input, nil, errs)
    return #errs == 0, errs

end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

local reg = debug.getregistry()
reg.luax_F_mt = mt

return setmetatable(F, {
    __call = function(_, t)
        if type(t) == "table" then return setmetatable(t, mt) end
        return t
    end,
})
]==])
package.preload["argparse"] = lib("luax/argparse.lua", [==[-- The MIT License (MIT)

-- Copyright (c) 2013 - 2018 Peter Melnichenko
--                      2019 Paul Ouellette
--                      2025 Christophe Delord

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

   for _, alias in ipairs(self._public_aliases) do
      local line = alias .. " " .. argument_list_repr
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
]==])
package.preload["cbor"] = lib("luax/cbor.lua", [[-- Concise Binary Object Representation (CBOR)
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
function tagged_mt:__tocbor(opts) return integer(self.tag, 192) .. encode(self.value, opts); end

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
    local custom_pairs = opts and opts.pairs or pairs
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
	for k, v in custom_pairs(t) do
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
    local custom_pairs = opts and opts.pairs or pairs
	local map, p, len = { "\191" }, 2, 0;
	for k, v in custom_pairs(t) do
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
        local custom_pairs = opts and opts.pairs or pairs
		local i = 0;
		for k in custom_pairs(t) do
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
]])
package.preload["complex"] = lib("luax/complex.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB
local has_complex, complex = pcall(require, "_complex")

if not has_complex then

    -- see https://github.com/krakow10/Complex-Number-Library/blob/master/Lua/Complex.lua

    local mathx = require "mathx"

    local e <const> = math.exp(1)
    local pi <const> = math.pi
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

    local forget <const> = 1e-14

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
]=])
package.preload["crypt"] = lib("luax/crypt.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

-- Load crypt.lua to add new methods to strings
--@LOAD=_

local has_crypt, crypt = pcall(require, "_crypt")

local F = require "F"

if not has_crypt then

    crypt = {}

    local floor = math.floor

    local byte = string.byte
    local char = string.char
    local format = string.format
    local gsub = string.gsub
    local pack = string.pack

    local concat = table.concat
    local tunpack = table.unpack

    local tonumber = tonumber

    -- FNV-1a
    local fnv1a_32_init = 0x811c9dc5
    local fnv1a_32_prime = 1<<24 | 1<<8 | 0x93
    local function fnv1a_32(hash, bs)
        for i=1,#bs do
            hash = (hash ~ byte(bs, i)) * fnv1a_32_prime
        end
        return hash & 0xFFFFFFFF
    end

    local fnv1a_64_init = 0xcbf29ce484222325
    local fnv1a_64_prime = 1<<40 | 1<<8 | 0xb3
    local function fnv1a_64(hash, bs)
        for i=1,#bs do
            hash = (hash ~ byte(bs, i)) * fnv1a_64_prime
        end
        return hash & 0xFFFFFFFFFFFFFFFF
    end

    local fnv1a_128_init = {0x6c62272e, 0x07bb0142, 0x62b82175, 0x6295c58d}
    local fnv1a_128_prime_b, fnv1a_128_prime_d = 1<<(88-2*32), 1<<8 | 0x3b
    local function fnv1a_128(hash, bs)
        local a, b, c, d = tunpack(hash)
        for i=1,#bs do
            d = d ~ byte(bs, i)
            local c0, d0 = c, d
            local carry
            d =         d0*fnv1a_128_prime_d                            d, carry = d & 0xFFFFFFFF, d >> 32
            c = carry + c0*fnv1a_128_prime_d                            c, carry = c & 0xFFFFFFFF, c >> 32
            b = carry + b *fnv1a_128_prime_d + d0*fnv1a_128_prime_b     b, carry = b & 0xFFFFFFFF, b >> 32
            a = carry + a *fnv1a_128_prime_d + c0*fnv1a_128_prime_b
        end
        return a&0xFFFFFFFF, b, c, d
    end

    -- Random number generator

    local prng_mt = {__index={}}

    local entropy do
        local hash = fnv1a_64_init
        entropy = function(ptr)
            hash = fnv1a_64(hash, pack("<I8I8I8I8",
                os.time(),
                floor(os.clock()*1000000),
                tonumber(format("%p", ptr)),
                tonumber(format("%p", {}))
            ))
            return hash
        end
    end

    local PCG_RAND_MAX <const> = 0xFFFFFFFF

    crypt.RAND_MAX = PCG_RAND_MAX

    local default_pcg_state <const> = 0x4d595df4d0f33173
    local pcg_multiplier <const> = 6364136223846793005
    local default_pcg_increment <const> = 1442695040888963407

    function crypt.prng(seed, incr)
        local self = setmetatable({}, prng_mt)
        return self:seed(seed, incr)
    end

    function prng_mt.__index:seed(seed, incr)
        if seed == -1 then seed = default_pcg_state end
        if incr == -1 then incr = default_pcg_increment end
        self.state = seed or entropy(self)
        self.increment = incr or entropy({})
        self.state = pcg_multiplier*self.state + self.increment
        self.state = pcg_multiplier*self.state + self.increment
        return self
    end

    function prng_mt.__index:clone()
        local clone = {
            state = self.state,
            increment = self.increment,
        }
        return setmetatable(clone, prng_mt)
    end

    local function xsh_rr(state)
        local xorshifted = (((state >> 18) ~ state) >> 27) & 0xFFFFFFFF
        local rot = state >> 59
        return ((xorshifted >> rot) | (xorshifted << ((-rot) & 31))) & 0xFFFFFFFF
    end

    local function pcg_int(self, a, b)
        local oldstate = self.state
        self.state = pcg_multiplier*oldstate + self.increment
        local r = xsh_rr(oldstate)

        if not a then return r end
        if not b then return r % a + 1 end
        return r % (b-a+1) + a
    end
    prng_mt.__index.int = pcg_int

    local function pcg_float(self, a, b)
        local r = pcg_int(self) / (PCG_RAND_MAX+1)
        if not a then return r end
        if not b then return r * a end
        return r*(b-a) + a
    end
    prng_mt.__index.float = pcg_float

    local function pcg_str(self, n)
        local bs = {}
        for i = 1, n, 4 do
            local r = pcg_int(self)
            bs[i  ] = char((r>>(0*8))&0xff)
            bs[i+1] = char((r>>(1*8))&0xff)
            bs[i+2] = char((r>>(2*8))&0xff)
            bs[i+3] = char((r>>(3*8))     )
        end
        return concat(bs, nil, 1, n)
    end
    prng_mt.__index.str = pcg_str

    -- global random number generator
    local _rng = crypt.prng()

    function crypt.seed(seed, incr) return _rng:seed(seed, incr) end

    function crypt.int(a, b) return _rng:int(a, b) end

    function crypt.float(a, b) return _rng:float(a, b) end

    function crypt.str(n) return _rng:str(n) end

    -- Hexadecimal encoding

    function crypt.hex(s)
        return (gsub(s, '.', function(c) return format("%02x", byte(c)) end))
    end

    function crypt.unhex(s)
        return (gsub(s, '..', function(h) return char(tonumber(h, 16)) end))
    end

    -- Base64 encoding

    -- see <https://en.wikipedia.org/wiki/Base64>

    local base64_map = { [0] =
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9',
    '+','/',
    }

    local base64_rev = {}
    for i, c in pairs(base64_map) do base64_rev[byte(c)] = i end
    base64_rev[byte'='] = 0

    function crypt.base64(s)
        local tokens = {}
        local remainder = #s % 3
        for i = 1, #s-remainder, 3 do
            local a, b, c = byte(s, i, i+2)
            local u24 = (a << 16) | (b << 8) | c
            tokens[#tokens+1] = base64_map[(u24 >> (3*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (2*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (1*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (0*6)) & 0x3F]
        end
        if remainder == 1 then
            local a = byte(s, -1)
            local u24 = (a << 16)
            tokens[#tokens+1] = base64_map[(u24 >> (3*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (2*6)) & 0x3F]
            tokens[#tokens+1] = "=="
        elseif remainder == 2 then
            local a, b = byte(s, -2, -1)
            local u24 = (a << 16) | (b << 8)
            tokens[#tokens+1] = base64_map[(u24 >> (3*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (2*6)) & 0x3F]
            tokens[#tokens+1] = base64_map[(u24 >> (1*6)) & 0x3F]
            tokens[#tokens+1] = "="
        end
        return concat(tokens)
    end

    function crypt.base64url(s)
        return (crypt.base64(s):gsub("+", "-"):gsub("/", "_"))
    end

    function crypt.unbase64(s)
        local tokens = {}
        for i = 1, #s, 4 do
            local a, b, c, d = byte(s, i, i+3)
            local u24 = (base64_rev[a] << (3*6))
                    | (base64_rev[b] << (2*6))
                    | (base64_rev[c] << (1*6))
                    | (base64_rev[d] << (0*6))
            tokens[#tokens+1] = char((u24 >> (2*8)) & 0xFF)
            tokens[#tokens+1] = char((u24 >> (1*8)) & 0xFF)
            tokens[#tokens+1] = char((u24 >> (0*8)) & 0xFF)
        end
        local y, z = byte(s, -2, -1)
        return concat(tokens, nil, 1, #tokens - (y==61 and 2 or z==61 and 1 or 0))
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

    -- ARC4 encryption

    function crypt.arc4(input, key, drop)
        assert(type(key) == "string", "arc4 key shall be a string")
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

    crypt.unarc4 = crypt.arc4

    function crypt.hash32(s) return ("<I4"):pack(fnv1a_32(fnv1a_32_init, s)):hex() end

    function crypt.hash64(s) return ("<I8"):pack(fnv1a_64(fnv1a_64_init, s)):hex() end

    function crypt.hash128(s)
        local a, b, c, d = fnv1a_128(fnv1a_128_init, s)
        return ("<I4I4I4I4"):pack(d, c, b, a):hex()
    end

    crypt.hash = crypt.hash64

    -- SHA-1
    function crypt.sha1(message)

        local unpack = string.unpack

        local function rotl(w, n) return ((w << n) | (w >> (32 - n))) & 0xFFFFFFFF end

        -- Padding: bit '1' follwed by '0' upto 448 bits (mod 512)
        local padding, mod = "\x80", (#message + 1) % 64
        padding = padding .. ("\x00"):rep(56 - mod + (mod > 56 and 64 or 0))

        local bytes = message .. padding .. (">I8"):pack(8*#message)

        local h0 = 0x67452301
        local h1 = 0xEFCDAB89
        local h2 = 0x98BADCFE
        local h3 = 0x10325476
        local h4 = 0xC3D2E1F0

        -- 512 bit blocks
        for chunk_start = 1, #bytes, 64 do
            local w = {}
            for i = 0, 15 do
                w[i] = unpack(">I4", bytes, chunk_start + i * 4)
            end
            for i = 16, 79 do
                w[i] = rotl(w[i-3] ~ w[i-8] ~ w[i-14] ~ w[i-16], 1)
            end

            -- block hash
            local a, b, c, d, e = h0, h1, h2, h3, h4
            local function round(i, f, k)
                a, b, c, d, e = (rotl(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF, a, rotl(b, 30), c, d
            end
            for i =  0, 19 do round(i, (b & c) | ((~b) & d),        0x5A827999) end
            for i = 20, 39 do round(i, b ~ c ~ d,                   0x6ED9EBA1) end
            for i = 40, 59 do round(i, (b & c) | (b & d) | (c & d), 0x8F1BBCDC) end
            for i = 60, 79 do round(i, b ~ c ~ d,                   0xCA62C1D6) end

            -- update global hash
            h0 = (h0 + a) & 0xFFFFFFFF
            h1 = (h1 + b) & 0xFFFFFFFF
            h2 = (h2 + c) & 0xFFFFFFFF
            h3 = (h3 + d) & 0xFFFFFFFF
            h4 = (h4 + e) & 0xFFFFFFFF
        end

        -- Final hexa digest
        return (">I4I4I4I4I4"):pack(h0, h1, h2, h3, h4):hex()

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

function prng_mt.__index:choose(xs)
    return xs[self:int(1, #xs)]
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

function prng_mt.__index:shuffle(xs)
    local ys = F.clone(xs)
    for i = 1, #ys-1 do
        local j = self:int(i, #ys)
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
s:arc4(key, drop)   == crypt.arc4(s, key, drop)
s:unarc4(key, drop) == crypt.unarc4(s, key, drop)
s:hash()            == crypt.hash(s)
s:hash32()          == crypt.hash32(s)
s:hash64()          == crypt.hash64(s)
s:hash128()         == crypt.hash128(s)
s:sha1()            == crypt.sha1(s)
```
@@@]]

string.hex          = crypt.hex
string.unhex        = crypt.unhex
string.base64       = crypt.base64
string.unbase64     = crypt.unbase64
string.base64url    = crypt.base64url
string.unbase64url  = crypt.unbase64url
string.arc4         = crypt.arc4
string.unarc4       = crypt.unarc4
string.hash         = crypt.hash
string.hash32       = crypt.hash32
string.hash64       = crypt.hash64
string.hash128      = crypt.hash128
string.sha1         = crypt.sha1
string.crc32        = crypt.crc32
string.crc64        = crypt.crc64

return crypt
]=])
package.preload["curl"] = lib("luax/curl.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

--[[------------------------------------------------------------------------@@@
# Simple curl interface

```lua
local curl = require "curl"
```

`curl` provides functions to execute curl.
curl must be installed separately.

@@@]]

local curl = {
    http = {},
}

local F = require "F"
local sh = require "sh"

--[[------------------------------------------------------------------------@@@
## curl command line
@@@]]

local errs = {
    [  0] = "Success. The operation completed successfully according to the instructions.",
    [  1] = "Unsupported protocol. This build of curl has no support for this protocol.",
    [  2] = "Failed to initialize.",
    [  3] = "URL malformed. The syntax was not correct.",
    [  4] = "A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at build-time. To make curl able to do this, you probably need another build of libcurl.",
    [  5] = "Could not resolve proxy. The given proxy host could not be resolved.",
    [  6] = "Could not resolve host. The given remote host could not be resolved.",
    [  7] = "Failed to connect to host.",
    [  8] = "Weird server reply. The server sent data curl could not parse.",
    [  9] = "FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that does not exist on the server.",
    [ 10] = "FTP accept failed. While waiting for the server to connect back when an active FTP session is used, an error code was sent over the control connection or similar.",
    [ 11] = "FTP weird PASS reply. Curl could not parse the reply sent to the PASS request.",
    [ 12] = "During an active FTP session while waiting for the server to connect back to curl, the timeout expired.",
    [ 13] = "FTP weird PASV reply, Curl could not parse the reply sent to the PASV request.",
    [ 14] = "FTP weird 227 format. Curl could not parse the 227-line the server sent.",
    [ 15] = "FTP cannot use host. Could not resolve the host IP we got in the 227-line.",
    [ 16] = "HTTP/2 error. A problem was detected in the HTTP2 framing layer. This is somewhat generic and can be one out of several problems, see the error message for details.",
    [ 17] = "FTP could not set binary. Could not change transfer method to binary.",
    [ 18] = "Partial file. Only a part of the file was transferred.",
    [ 19] = "FTP could not download/access the given file, the RETR (or similar) command failed.",
    [ 21] = "FTP quote error. A quote command returned error from the server.",
    [ 22] = "HTTP page not retrieved. The requested URL was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used.",
    [ 23] = "Write error. Curl could not write data to a local filesystem or similar.",
    [ 25] = "Failed starting the upload. For FTP, the server typically denied the STOR command.",
    [ 26] = "Read error. Various reading problems.",
    [ 27] = "Out of memory. A memory allocation request failed.",
    [ 28] = "Operation timeout. The specified time-out period was reached according to the conditions.",
    [ 30] = "FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead.",
    [ 31] = "FTP could not use REST. The REST command failed. This command is used for resumed FTP transfers.",
    [ 33] = "HTTP range error. The range \"command\" did not work.",
    [ 34] = "HTTP post error. Internal post-request generation error.",
    [ 35] = "SSL connect error. The SSL handshaking failed.",
    [ 36] = "Bad download resume. Could not continue an earlier aborted download.",
    [ 37] = "FILE could not read file. Failed to open the file. Permissions?",
    [ 38] = "LDAP cannot bind. LDAP bind operation failed.",
    [ 39] = "LDAP search failed.",
    [ 41] = "Function not found. A required LDAP function was not found.",
    [ 42] = "Aborted by callback. An application told curl to abort the operation.",
    [ 43] = "Internal error. A function was called with a bad parameter.",
    [ 45] = "Interface error. A specified outgoing interface could not be used.",
    [ 47] = "Too many redirects. When following redirects, curl hit the maximum amount.",
    [ 48] = "Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual!",
    [ 49] = "Malformed telnet option.",
    [ 52] = "The server did not reply anything, which here is considered an error.",
    [ 53] = "SSL crypto engine not found.",
    [ 54] = "Cannot set SSL crypto engine as default.",
    [ 55] = "Failed sending network data.",
    [ 56] = "Failure in receiving network data.",
    [ 58] = "Problem with the local certificate.",
    [ 59] = "Could not use specified SSL cipher.",
    [ 60] = "Peer certificate cannot be authenticated with known CA certificates.",
    [ 61] = "Unrecognized transfer encoding.",
    [ 63] = "Maximum file size exceeded.",
    [ 64] = "Requested FTP SSL level failed.",
    [ 65] = "Sending the data requires a rewind that failed.",
    [ 66] = "Failed to initialize SSL Engine.",
    [ 67] = "The username, password, or similar was not accepted and curl failed to log in.",
    [ 68] = "File not found on TFTP server.",
    [ 69] = "Permission problem on TFTP server.",
    [ 70] = "Out of disk space on TFTP server.",
    [ 71] = "Illegal TFTP operation.",
    [ 72] = "Unknown TFTP transfer ID.",
    [ 73] = "File already exists (TFTP).",
    [ 74] = "No such user (TFTP).",
    [ 77] = "Problem reading the SSL CA cert (path? access rights?).",
    [ 78] = "The resource referenced in the URL does not exist.",
    [ 79] = "An unspecified error occurred during the SSH session.",
    [ 80] = "Failed to shut down the SSL connection.",
    [ 82] = "Could not load CRL file, missing or wrong format.",
    [ 83] = "Issuer check failed.",
    [ 84] = "The FTP PRET command failed.",
    [ 85] = "Mismatch of RTSP CSeq numbers.",
    [ 86] = "Mismatch of RTSP Session Identifiers.",
    [ 87] = "Unable to parse FTP file list.",
    [ 88] = "FTP chunk callback reported error.",
    [ 89] = "No connection available, the session is queued.",
    [ 90] = "SSL public key does not matched pinned public key.",
    [ 91] = "Invalid SSL certificate status.",
    [ 92] = "Stream error in HTTP/2 framing layer.",
    [ 93] = "An API function was called from inside a callback.",
    [ 94] = "An authentication function returned an error.",
    [ 95] = "A problem was detected in the HTTP/3 layer. This is somewhat generic and can be one out of several problems, see the error message for details.",
    [ 96] = "QUIC connection error. This error may be caused by an SSL library error. QUIC is the protocol used for HTTP/3 transfers.",
    [ 97] = "Proxy handshake error.",
    [ 98] = "A client-side certificate is required to complete the TLS handshake.",
    [ 99] = "Poll or select returned fatal error.",
    [100] = "A value or data field grew larger than allowed.",

    -- This error is returned by the shell, not curl
    [127] = "curl: command not found",
}

--[[@@@
```lua
curl.request(...)
```
> Execute `curl` with arguments `...` and returns the output of `curl` (`stdout`).
> Arguments can be a nested list (it will be flattened).
> In case of error, `curl` returns `nil`, an error message and an error code
> (see [curl man page](https://curl.se/docs/manpage.html)).

@@@]]

function curl.request(...)
    local res, _, err = sh("curl", ...)
    if not res then return nil, errs[tonumber(err)] or "curl: unknown error", err end
    return res
end

--[[@@@
```lua
curl(...)
```
> Like `curl.request(...)` with some default options:
>
> - `--silent`: silent mode
> - `--show-error`: show an error message if it fails
> - `--location`: follow redirections

@@@]]

local default_curl_options = {
    "-s",   --silent
    "-S",   --show-error
    "-L",   --location (follow redirections)
}

setmetatable(curl, { __call = function(_, ...) return curl.request(default_curl_options, ...) end })

--[[------------------------------------------------------------------------@@@
## curl HTTP requests

`curl.http` is meant to be a simple replacement of LuaSocket/LuaSec and OpenSSL.
It can issue HTTP(S) requests using `curl`.

@@@]]

local DEFAULT_USER_AGENT = "LuaX/"..require"luax-version".version
local global_user_agent = DEFAULT_USER_AGENT

--[[@@@
```lua
curl.http.set_user_agent([user_agent])
```
> Define the default User-Agent header used by HTTP requests.
> If no `user_agent` is given, the default value is used (`LuaX/X.Y`).
@@@]]
function curl.http.set_user_agent(ua)
    global_user_agent = ua or DEFAULT_USER_AGENT
end

--[[@@@
```lua
curl.http.request(method, url, [options])
```
> Issue a generic HTTP(S) request, using the method `method` to the target URL `url`.
> `options` is an optional table:
>
> - `options.headers`: header table (key names are normalized: `_` is replaced by `-` and words are capitalized)
> - `options.body`: body of the request (e.g. for `POST` requests)
> - `options.output_file`: filename where the response data is saved
> - `options.user_agent`: user agent specific to this request
>
> It returns a table with the following fields:
>
> - `ok`: `true` if the requests is successful (i.e. the status is `2XX`)
> - `status`: HTTP status code
> - `status_msg`: HTTP status message (if any)
> - `headers`: response header table with normalized keys (`-` replaced with `_`, all lower case)
>
> In case of errorn it returns `nil` and an error message.
@@@]]

local function http_ok(code) return code >= 200 and code < 300 end

local function q(s)
    s = ("%q"):format(s) -- escape special chars
    s = s:gsub("%$", "\\$") -- escape $ to avoid unwanted interpolations
    return s
end

function curl.http.request(method, url, options)
    options = options or {}
    local headers = options.headers or {}
    local body = options.body
    local output_file = options.output_file
    local user_agent = options.user_agent or global_user_agent

    headers = F.mapk2a(function(k, v)
        return {k : gsub("_", "-") : split "%-" : map(string.cap) : str "-", v}
    end, headers) : map2t(F.unpack)

    headers["User-Agent"] = headers["User-Agent"] or user_agent

    local response, error_message = curl.request {
        "-L",                           --location
        "-s",                           --silent
        "-i",                           --show-headers
        "-X", method:upper(), url,      --request
        F.mapk2a(function(k, v)
            return { "-H", q(('%s: %s'):format(k, v)) } --header
        end, headers),
        body and { "-d", q(body) } or {},               --data
    }
    if not response then return nil, error_message end

    local status_line, headers_str, response_body = response:match("^(.-)\r\n(.-)\r\n\r\n(.*)$")
    if not status_line then return nil, "curl: Unexpected reply format" end

    local _, status_code, status_msg = status_line:split(" ", 2):unpack() -- HTTP/X.Y 200 msg...
    status_code = tonumber(status_code)

    local response_headers = {}
    for line in headers_str:gmatch("([^\r\n]+)") do
        local k, v = line : split(":", 1) : map(string.trim) : unpack()
        if k and v then
            k = k : gsub("%-", "_") : lower()
            response_headers[k] = v
        end
    end
    response_headers.content_length = tonumber(response_headers.content_length)

    local ok = http_ok(status_code)

    if output_file and ok then
        local write_ok, errmsg = fs.write_bin(output_file, response_body)
        if not write_ok then return nil, errmsg end
    end

    return {
        ok = ok,
        status = status_code,
        status_msg = #status_msg > 0 and status_msg or status_code,
        headers = response_headers,
        body = response_body
    }
end

--[[@@@
```lua
curl.http.get(url, [options])
```
> Issue a `GET` requests using `http.request`.
@@@]]
function curl.http.get(url, options)
    return curl.http.request("GET", url, options)
end

--[[@@@
```lua
curl.http.head(url, [options])
```
> Issue a `HEAD` requests using `http.request`.
@@@]]
function curl.http.head(url, options)
    return curl.http.request("HEAD", url, options)
end

--[[@@@
```lua
curl.http.post(url, body, [options])
```
> Issue a `POST` requests using `http.request`.
@@@]]
function curl.http.post(url, body, options)
    return curl.http.request("POST", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.put(url, body, [options])
```
> Issue a `PUT` requests using `http.request`.
@@@]]
function curl.http.put(url, body, options)
    return curl.http.request("PUT", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.delete(url, [options])
```
> Issue a `DELETE` requests using `http.request`.
@@@]]
function curl.http.delete(url, options)
    return curl.http.request("DELETE", url, options)
end

--[[@@@
```lua
curl.http.connect(url, [options])
```
> Issue a `CONNECT` requests using `http.request`.
@@@]]
function curl.http.connect(url, options)
    return curl.http.request("CONNECT", url, options)
end

--[[@@@
```lua
http.options(url, [options])
```
> Issue a `OPTIONS` requests using `http.request`.
@@@]]
function curl.http.options(url, options)
    return curl.http.request("OPTIONS", url, options)
end

--[[@@@
```lua
curl.http.trace(url, [options])
```
> Issue a `TRACE` requests using `http.request`.
@@@]]
function curl.http.trace(url, options)
    return curl.http.request("TRACE", url, options)
end

--[[@@@
```lua
curl.http.patch(url, body, [options])
```
> Issue a `PATCH` requests using `http.request`.
@@@]]
function curl.http.patch(url, body, options)
    return curl.http.request("PATCH", url, F.merge{options or {}, {body=body}})
end

--[[@@@
```lua
curl.http.download(url, output_file, [options])
```
> Issue a `GET` requests using `http.request` and store the response into `output_file`.
> It returns `true` if the download is successful.
@@@]]
function curl.http.download(url, output_file, options)
    local response, err = curl.http.request("GET", url, F.merge{options or {}, {output_file=output_file}})
    if not response then return nil, err end
    if not http_ok(response.status) then return nil, response.status_msg end
    return true
end

--[[@@@
```lua
curl(...)
```
> Shortcut to `curl.request(...)`.
@@@]]

setmetatable(curl.http, { __call = function(self, ...) return self.request(...) end })

return curl
]=])
package.preload["fs"] = lib("luax/fs.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--[[------------------------------------------------------------------------@@@
## Additional functions (Lua)
@@@]]

-- Load fs.lua to add new methods to strings
--@LOAD=_

local has_fs, fs = pcall(require, "_fs")

local F = require "F"
local sys = require "sys"

local __PANDOC__, pandoc  = _ENV.PANDOC_VERSION ~= nil, _ENV.pandoc

if not has_fs then

    fs = {}

    local sh = require "sh"

    local __WINDOWS__ = sys.os == "windows"
    local __MACOS__   = sys.os == "macos"

    if __PANDOC__ then
        fs.sep = pandoc.path.separator
        fs.path_sep = pandoc.path.search_path_separator
    else
        fs.sep = package.config:match("^([^\n]-)\n")
        fs.path_sep = fs.sep == '\\' and ";" or ":"
    end

    local function safe_sh(...)
        local out, msg = sh.read(...)
        if not out then error(msg) end
        return out
    end

    function fs.getcwd()
        if __PANDOC__ then return pandoc.system.get_working_directory() end
        if __WINDOWS__ then return safe_sh "cd" : trim() end
        return safe_sh "pwd" : trim()
    end

    function fs.dir(path)
        if __PANDOC__ then return F(pandoc.system.list_directory(path)) end
        if __WINDOWS__ then return safe_sh("dir /b", path) : lines() : sort() end
        return safe_sh("ls", path) : lines() : sort()
    end

    fs.remove = os.remove

    fs.rename = os.rename

    function fs.copy(source_name, target_name)
        local from<close>, err_from = io.open(source_name, "rb")
        if not from then return from, err_from end
        local to<close>, err_to = io.open(target_name, "wb")
        if not to then return to, err_to end
        while true do
            local block = from:read(8*1024)
            if not block then break end
            local ok, err = to:write(block)
            if not ok then
                return ok, err
            end
        end
        return true
    end

    function fs.symlink(target, linkpath)
        if __WINDOWS__ then return nil, "symlink not implemented" end
        return sh.run("ln -s", target, linkpath)
    end

    function fs.mkdir(path)
        if __PANDOC__ then return pandoc.system.make_directory(path) end
        return sh.run("mkdir", path)
    end

    local S_IFMT  <const> = 0xF << 12
    local S_IFDIR <const> = 1 << 14
    local S_IFREG <const> = 1 << 15
    local S_IFLNK <const> = (1 << 13) | (1 << 15)

    local S_IRUSR <const> = 1 << 8
    local S_IWUSR <const> = 1 << 7
    local S_IXUSR <const> = 1 << 6
    local S_IRGRP <const> = 1 << 5
    local S_IWGRP <const> = 1 << 4
    local S_IXGRP <const> = 1 << 3
    local S_IROTH <const> = 1 << 2
    local S_IWOTH <const> = 1 << 1
    local S_IXOTH <const> = 1 << 0

    local S_IRALL <const> = 1 << 8 | 1 << 5 | 1 << 2
    local S_IWALL <const> = 1 << 7 | 1 << 4 | 1 << 1
    local S_IXALL <const> = 1 << 6 | 1 << 3 | 1 << 0

    fs.uR = S_IRUSR
    fs.uW = S_IWUSR
    fs.uX = S_IXUSR
    fs.aR = S_IRALL
    fs.aW = S_IWALL
    fs.aX = S_IXALL
    fs.gR = S_IRGRP
    fs.gW = S_IWGRP
    fs.gX = S_IXGRP
    fs.oR = S_IROTH
    fs.oW = S_IWOTH
    fs.oX = S_IXOTH

    local function stat(name, follow)
        local size, mtime, atime, ctime, mode
        if __MACOS__ then
            local st = sh.read("LC_ALL=C", "stat", follow, "-r", name, "2>/dev/null")
            if not st then return nil, "cannot stat "..name end
            local _, mode_str
            _, _, mode_str, _, _, _, _, size, atime, mtime, _, ctime, _, _, _ = st:words():unpack()
            mode = tonumber(mode_str, 8)
        else
            local st = sh.read("LC_ALL=C", "stat", follow, "-c '%s;%Y;%X;%W;%f'", name, "2>/dev/null")
            if not st then return nil, "cannot stat "..name end
            local mode_str
            size, mtime, atime, ctime, mode_str = st:trim():split ";":unpack()
            mode = tonumber(mode_str, 16)
        end
        return F{
            name = name,
            size = tonumber(size),
            mtime = tonumber(mtime),
            atime = tonumber(atime),
            ctime = tonumber(ctime),
            mode = mode,
            type = (mode & S_IFMT) == S_IFLNK and "link"
                or (mode & S_IFMT) == S_IFDIR and "directory"
                or (mode & S_IFMT) == S_IFREG and "file"
                or "unknown",
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

    function fs.stat(name)
        return stat(name, "-L")
    end

    function fs.lstat(name)
        return stat(name, {})
    end

    function fs.inode(name)
        local dev, ino
        if __MACOS__ then
            local st = sh.read("LC_ALL=C", "stat", "-L", "-r", name, "2>/dev/null")
            if not st then return nil, "cannot stat "..name end
            dev, ino = st:words():unpack()
        else
            local st = sh.read("LC_ALL=C", "stat", "-L", "-c '%d;%i'", name, "2>/dev/null")
            if not st then return nil, "cannot stat "..name end
            dev, ino = st:trim():split ";":unpack()
        end
        return F{
            ino = tonumber(ino),
            dev = tonumber(dev),
        }
    end

    local pattern_cache = {}

    function fs.fnmatch(pattern, name)
        local lua_pattern = pattern_cache[pattern]
        if not lua_pattern then
            lua_pattern = pattern
                : gsub("%.", "%%.")
                : gsub("%*", ".*")
            lua_pattern = "^"..lua_pattern.."$"
            pattern_cache[pattern] = lua_pattern
        end
        return name:match(lua_pattern) and true or false
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

    function fs.basename(path)
        if __PANDOC__ then return pandoc.path.filename(path) end
        return (path:gsub(".*[/\\]", ""))
    end

    function fs.dirname(path)
        if __PANDOC__ then return pandoc.path.directory(path) end
        local dir, n = path:gsub("[/\\][^/\\]*$", "")
        return n > 0 and dir or "."
    end

    function fs.splitext(path)
        if __PANDOC__ then
            if fs.basename(path):match "^%." then return path, "" end
            return pandoc.path.split_extension(path)
        end
        local name, ext = path:match("^(.*)(%.[^/\\]-)$")
        if name and ext and #name > 0 and not name:has_suffix(fs.sep) then return name, ext end
        return path, ""
    end

    function fs.ext(path)
        local _, ext = fs.splitext(path)
        return ext
    end

    function fs.chext(path, new_ext)
        return fs.splitext(path) .. new_ext
    end

    function fs.realpath(path)
        if __PANDOC__ then return pandoc.path.normalize(path) end
        return safe_sh("realpath", path) : trim()
    end

    function fs.readlink(path)
        return safe_sh("readlink", path) : trim()
    end

    function fs.absname(path)
        if path:match "^[/\\]" or path:match "^.:" then return path end
        return fs.getcwd()..fs.sep..path
    end

    function fs.mkdirs(path)
        if __PANDOC__ then return pandoc.system.make_directory(path, true) end
        if __WINDOWS__ then return sh.run("mkdir", path) end
        return sh.run("mkdir", "-p", path)
    end

    function fs.ls(dir, dotted) ---@diagnostic disable-line: unused-local (hidden files not supported in the Lua implementation)
        dir = dir or "."
        local base = dir:basename()
        local path = dir:dirname()
        local recursive = base:match"%*%*"
        local pattern = base:match"%*" and base:gsub("%*+", "*")

        local useless_path_prefix = "^%."..fs.sep
        local function clean_path(fullpath)
            return fullpath:gsub(useless_path_prefix, "")
        end

        if __WINDOWS__ then

            local files
            if recursive then
                files = sh("dir /b /s", path/pattern)
            elseif pattern then
                files = sh("dir /b", path/pattern)
            else
                files = sh("dir /b", dir)
            end
            return (files or "") : lines()
                : map(clean_path)
                : sort()
        end

        local files
        if recursive then
            files = (sh("find", path, ("-name %q"):format(pattern), "2>/dev/null") or "") : lines()
                : filter(F.partial(F.op.ne, path))
        elseif pattern then
            files = (sh("ls -d", path/pattern, "2>/dev/null") or "") : lines()
        else
            files = (sh("ls", dir, "2>/dev/null") or "") : lines()
                : map(F.partial(fs.join, dir))
        end
        return files
            : map(clean_path)
            : sort()
    end

    function fs.is_file(name)
        local st = fs.stat(name)
        return st ~= nil and st.type == "file"
    end

    function fs.is_dir(name)
        local st = fs.stat(name)
        return st ~= nil and st.type == "directory"
    end

    function fs.is_link(name)
        local st = fs.lstat(name)
        return st ~= nil and st.type == "link"
    end

    fs.rm = fs.remove
    fs.mv = fs.rename

    fs.tmpfile = os.tmpname

    function fs.tmpdir()
        local tmp = os.tmpname()
        fs.rm(tmp)
        fs.mkdir(tmp)
        return tmp
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

function fs.join(...)
    if __PANDOC__ then return pandoc.path.join(F.flatten{...}) end
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
fs.rmdir(path)
```
deletes the directory `path` and its content recursively.
@@@]]

function fs.rmdir(path)
    if __PANDOC__ then
        pandoc.system.remove_directory(path, true)
        return true
    end
    fs.walk(path, {reverse=true}):foreach(fs.rm)
    return fs.rm(path)
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
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

function fs.with_tmpfile(f)
    if __PANDOC__ then
        return pandoc.system.with_temporary_directory("luax", function(tmpdir)
            return f(tmpdir/"tmpfile")
        end)
    end
    local tmp = fs.tmpfile()
    local ret = {f(tmp)}
    fs.rm(tmp)
    return table.unpack(ret)
end

--[[@@@
```lua
fs.with_tmpdir(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary directory.
@@@]]

function fs.with_tmpdir(f)
    if __PANDOC__ then
        return pandoc.system.with_temporary_directory("luax", f)
    end
    local tmp = fs.tmpdir()
    local ret = {f(tmp)}
    fs.rmdir(tmp)
    return table.unpack(ret)
end

--[[@@@
```lua
fs.with_dir(path, f)
```
changes the current working directory to `path` and calls `f()`.
@@@]]

function fs.with_dir(path, f)
    if __PANDOC__ then
        return pandoc.system.with_working_directory(path, f)
    end
    if fs.chdir then
        local old = fs.getcwd()
        fs.chdir(path)
        local ret = {f(path)}
        fs.chdir(old)
        return table.unpack(ret)
    end
    error "fs.with_dir not implemented"
end

--[[@@@
```lua
fs.expand(path, [vars])
```
returns the expanded path
where `"~"` at the beginning of the path is replaced by the home directory of the current user
and `$XXX` or `${XXX}` is replaced by the environment variable `XXX`.
Variable values can also be taken from the optional `vars` table.
@@@]]

local function expanduser(path)
    local home = os.getenv(sys.os == "windows" and "USERPROFILE" or "HOME")
    if path == "~" then return home end
    local local_path = path:match "^~([/\\].*)"
    if local_path then return home..local_path end
    return path
end

local function expandvars(path, vars)
    vars = vars or {}
    local function expand(var) return os.getenv(var) or vars[var] or var end
    path = path : gsub("${([%w_]+)}", expand) : gsub("$([%w_]+)", expand)
    return path
end

function fs.expand(path, vars)
    return expandvars(expanduser(path), vars)
end

--[[@@@
```lua
fs.read(filename)
```
returns the content of the text file `filename`.
@@@]]

function fs.read(name)
    local f<close>, oerr = io.open(name, "r")
    if not f then return f, oerr end
    return f:read("a")
end

--[[@@@
```lua
fs.write(filename, ...)
```
write `...` to the text file `filename`.
@@@]]

function fs.write(name, ...)
    local content = F{...}:flatten():str()
    local f<close>, oerr = io.open(name, "w")
    if not f then return f, oerr end
    return f:write(content)
end

--[[@@@
```lua
fs.read_bin(filename)
```
returns the content of the binary file `filename`.
@@@]]

function fs.read_bin(name)
    local f<close>, oerr = io.open(name, "rb")
    if not f then return f, oerr end
    return f:read("a")
end

--[[@@@
```lua
fs.write_bin(filename, ...)
```
write `...` to the binary file `filename`.
@@@]]

function fs.write_bin(name, ...)
    local content = F{...}:flatten():str()
    local f<close>, oerr = io.open(name, "wb")
    if not f then return f, oerr end
    return f:write(content)
end

--[[------------------------------------------------------------------------@@@
## String methods

Some functions of the `fs` package are added to the string module:

@@@]]

--[[@@@
```lua
path:stat()             == fs.stat(path)
path:inode()            == fs.inode(path)
path:basename()         == fs.basename(path)
path:dirname()          == fs.dirname(path)
path:splitext()         == fs.splitext(path)
path:ext()              == fs.ext(path)
path:chext()            == fs.chext(path)
path:realpath()         == fs.realpath(path)
path:readlink()         == fs.readlink(path)
path:absname()          == fs.absname(path)
path1 / path2           == fs.join(path1, path2)
path:is_file()          == fs.is_file(path)
path:is_dir()           == fs.is_dir(path)
path:findpath()         == fs.findpath(path)
```
@@@]]

string.stat             = fs.stat
string.inode            = fs.inode
string.basename         = fs.basename
string.dirname          = fs.dirname
string.splitext         = fs.splitext
string.ext              = fs.ext
string.chext            = fs.chext
string.splitpath        = fs.splitpath
string.realpath         = fs.realpath
string.readlink         = fs.readlink
string.absname          = fs.absname
string.is_file          = fs.is_file
string.is_dir           = fs.is_dir
string.findpath         = fs.findpath

getmetatable("").__div  = fs.join

return fs
]=])
package.preload["imath"] = lib("luax/imath.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_imath, imath = pcall(require, "_imath")

if not has_imath then

    imath = {}

    local mt = {__index={}}

    ---@diagnostic disable:unused-vararg
    local function ni(f) return function(...) error(f.." not implemented") end end

    local floor = math.floor
    local ceil = math.ceil
    local sqrt = math.sqrt
    local log = math.log
    local max = math.max

    local RADIX <const> = 10000000
    local RADIX_LEN <const> = floor(log(RADIX, 10))

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
        if type(n) == "number" then
            if math.type(n) == "float" then
                n = ("%.0f"):format(floor(n))
            else
                n = ("%d"):format(n)
            end
        end
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

    local int_zero <const> = int(0)
    local int_one <const> = int(1)
    local int_two <const> = int(2)

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
]=])
package.preload["import"] = lib("luax/import.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
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
local conf = import("myconf.lua", [env])
```
Evaluates `"myconf.lua"` in a new table and returns this table.
All files are tracked in `package.modpath`.

The execution environment inherits from `env` (or `_ENV` if `env` is not defined).
@@@]]

return function(fname, env)
    local mod = setmetatable({}, {__index = env or _ENV})
    assert(loadfile(fname, "t", mod))()
    return mod
end
]=])
package.preload["json"] = lib("luax/json.lua", [===[-- Module options:
local always_use_lpeg = false
local register_global_module_table = false
local global_module_name = 'json'

--[==[

David Kolf's JSON module for Lua 5.1 - 5.4

Version 2.8


For the documentation see the corresponding readme.txt or visit
<http://dkolf.de/dkjson-lua/>.

You can contact the author by sending an e-mail to 'david' at the
domain 'dkolf.de'.


Copyright (C) 2010-2024 David Heiko Kolf

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable =
      pairs, type, tostring, tonumber, getmetatable, setmetatable
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat

local json = { version = "dkjson 2.8" }

local jsonlpeg = {}

if register_global_module_table then
  if always_use_lpeg then
    _G[global_module_name] = jsonlpeg
  else
    _G[global_module_name] = json
  end
end

local _ENV = nil -- blocking globals in Lua 5.2 and later

pcall (function()
  -- Enable access to blocked metatables.
  -- Don't worry, this module doesn't change anything in them.
  local debmeta = require "debug".getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable ({}, {
  __tojson = function () return "null" end
})

local function isarray (tbl)
  local max, n, arraylen = 0, 0, 0
  for k,v in pairs (tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end
      if k > max then
        max = k
      end
      n = n + 1
    end
  end
  if max > 10 and max > arraylen and max > n * 2 then
    return false -- don't create an array with too many holes
  end
  return true, max
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

local function escapeutf8 (uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176-\191]", escapeutf8)
  end
  return "\"" .. value .. "\""
end
json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind (str, o, 1, true)
  if i then
    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
  else
    return str
  end
end

-- locale independent num2str and str2num functions
local decpoint, numfilter

local function updatedecpoint ()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  -- build a filter that can be used to remove group separators
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str (num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num (str)
  local num = tonumber(replace(str, ".", decpoint))
  if not num then
    updatedecpoint()
    num = tonumber(replace(str, ".", decpoint))
  end
  return num
end

local function addnewline2 (level, buffer, buflen)
  buffer[buflen+1] = "\n"
  buffer[buflen+2] = strrep ("  ", level)
  buflen = buflen + 2
  return buflen
end

function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type (key)
  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end
  if prev then
    buflen = buflen + 1
    buffer[buflen] = ","
  end
  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end
  -- When Lua is compiled with LUA_NOCVTN2S this will fail when
  -- numbers are mixed into the keys of the table. JSON keys are always
  -- strings, so this would be an implicit conversion too and the failure
  -- is intentional.
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ":"
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen
  if type (res) == 'string' then
    buflen = buflen + 1
    buffer[buflen] = res
  end
  return buflen
end

local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason
  local handler = state.exception
  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen
    local ret, msg = handler (reason, value, state, defaultmessage)
    if not ret then return nil, msg or defaultmessage end
    return appendcustom(ret, buffer, state)
  end
end

function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson
  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    state.bufferlen = buflen
    local ret, msg = valtojson (value, state)
    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
    tables[value] = nil
    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray (value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        if type(order) == "function" then order = order(value) end
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v ~= nil then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
        for k,v in pairs (value) do
          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception ('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end

function json.encode (value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                   buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error (msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat (buffer)
  end
end

local function loc (str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind (str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end
  return strformat ("line %d, column %d", line, where - linepos)
end

local function unterminated (str, what, where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

local function scanwhite (str, pos)
  while true do
    pos = strfind (str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub (str, pos, pos + 1)
    if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind (str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind (str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated (str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end
    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar (value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end
      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat (buffer), lastpos
  else
    return "", lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable (tbl, objectmeta)
  else
    setmetatable (tbl, arraymeta)
  end
  while true do
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    local char = strsub (str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    char = strsub (str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end
      pos = scanwhite (str, pos + 1)
      if not pos then return unterminated (str, what, startpos) end
      local val2
      val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite (str, pos)
      if not pos then return unterminated (str, what, startpos) end
      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite (str, pos)
  if not pos then
    return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub (str, pos, pos)
  if char == "{" then
    return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring (str, pos)
  else
    local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num (strsub (str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind (str, "^%a%w*", pos)
    if pstart then
      local name = strsub (str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc (str, pos)
  end
end

local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return {__jsontype = 'object'}, {__jsontype = 'array'}
  end
end

function json.decode (str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end

function json.use_lpeg ()
  local g = require ("lpeg")

  if type(g.version) == 'function' and g.version() == "0.11" then
    error "due to a bug in LPeg 0.11, it cannot be used for JSON matching"
  end

  local pegmatch = g.match
  local P, S, R = g.P, g.S, g.R

  local function ErrorCall (str, pos, msg, state)
    if not state.msg then
      state.msg = msg .. " at " .. loc (str, pos)
      state.pos = pos
    end
    return false
  end

  local function Err (msg)
    return g.Cmt (g.Cc (msg) * g.Carg (2), ErrorCall)
  end

  local function ErrorUnterminatedCall (str, pos, what, state)
    return ErrorCall (str, pos - 1, "unterminated " .. what, state)
  end

  local SingleLineComment = P"//" * (1 - S"\n\r")^0
  local MultiLineComment = P"/*" * (1 - P"*/")^0 * P"*/"
  local Space = (S" \n\r\t" + P"\239\187\191" + SingleLineComment + MultiLineComment)^0

  local function ErrUnterminated (what)
    return g.Cmt (g.Cc (what) * g.Carg (2), ErrorUnterminatedCall)
  end

  local PlainChar = 1 - S"\"\\\n\r"
  local EscapeSequence = (P"\\" * g.C (S"\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
  local HexDigit = R("09", "af", "AF")
  local function UTF16Surrogate (match, pos, high, low)
    high, low = tonumber (high, 16), tonumber (low, 16)
    if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
      return true, unichar ((high - 0xD800)  * 0x400 + (low - 0xDC00) + 0x10000)
    else
      return false
    end
  end
  local function UTF16BMP (hex)
    return unichar (tonumber (hex, 16))
  end
  local U16Sequence = (P"\\u" * g.C (HexDigit * HexDigit * HexDigit * HexDigit))
  local UnicodeEscape = g.Cmt (U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence/UTF16BMP
  local Char = UnicodeEscape + EscapeSequence + PlainChar
  local String = P"\"" * (g.Cs (Char ^ 0) * P"\"" + ErrUnterminated "string")
  local Integer = P"-"^(-1) * (P"0" + (R"19" * R"09"^0))
  local Fractal = P"." * R"09"^0
  local Exponent = (S"eE") * (S"+-")^(-1) * R"09"^1
  local Number = (Integer * Fractal^(-1) * Exponent^(-1))/str2num
  local Constant = P"true" * g.Cc (true) + P"false" * g.Cc (false) + P"null" * g.Carg (1)
  local SimpleValue = Number + String + Constant
  local ArrayContent, ObjectContent

  -- The functions parsearray and parseobject parse only a single value/pair
  -- at a time and store them directly to avoid hitting the LPeg limits.
  local function parsearray (str, pos, nullval, state)
    local obj, cont
    local start = pos
    local npos
    local t, nt = {}, 0
    repeat
      obj, cont, npos = pegmatch (ArrayContent, str, pos, nullval, state)
      if cont == 'end' then
        return ErrorUnterminatedCall (str, start, "array", state)
      end
      pos = npos
      if cont == 'cont' or cont == 'last' then
        nt = nt + 1
        t[nt] = obj
      end
    until cont ~= 'cont'
    return pos, setmetatable (t, state.arraymeta)
  end

  local function parseobject (str, pos, nullval, state)
    local obj, key, cont
    local start = pos
    local npos
    local t = {}
    repeat
      key, obj, cont, npos = pegmatch (ObjectContent, str, pos, nullval, state)
      if cont == 'end' then
        return ErrorUnterminatedCall (str, start, "object", state)
      end
      pos = npos
      if cont == 'cont' or cont == 'last' then
        t[key] = obj
      end
    until cont ~= 'cont'
    return pos, setmetatable (t, state.objectmeta)
  end

  local Array = P"[" * g.Cmt (g.Carg(1) * g.Carg(2), parsearray)
  local Object = P"{" * g.Cmt (g.Carg(1) * g.Carg(2), parseobject)
  local Value = Space * (Array + Object + SimpleValue)
  local ExpectedValue = Value + Space * Err "value expected"
  local ExpectedKey = String + Err "key expected"
  local End = P(-1) * g.Cc'end'
  local ErrInvalid = Err "invalid JSON"
  ArrayContent = (Value * Space * (P"," * g.Cc'cont' + P"]" * g.Cc'last'+ End + ErrInvalid)  + g.Cc(nil) * (P"]" * g.Cc'empty' + End  + ErrInvalid)) * g.Cp()
  local Pair = g.Cg (Space * ExpectedKey * Space * (P":" + Err "colon expected") * ExpectedValue)
  ObjectContent = (g.Cc(nil) * g.Cc(nil) * P"}" * g.Cc'empty' + End + (Pair * Space * (P"," * g.Cc'cont' + P"}" * g.Cc'last' + End + ErrInvalid) + ErrInvalid)) * g.Cp()
  local DecodeValue = ExpectedValue * g.Cp ()

  jsonlpeg.version = json.version
  jsonlpeg.encode = json.encode
  jsonlpeg.null = json.null
  jsonlpeg.quotestring = json.quotestring
  jsonlpeg.addnewline = json.addnewline
  jsonlpeg.encodeexception = json.encodeexception
  jsonlpeg.using_lpeg = true

  function jsonlpeg.decode (str, pos, nullval, ...)
    local state = {}
    state.objectmeta, state.arraymeta = optionalmetatables(...)
    local obj, retpos = pegmatch (DecodeValue, str, pos, nullval, state)
    if state.msg then
      return nil, state.pos, state.msg
    else
      return obj, retpos
    end
  end

  -- cache result of this function:
  json.use_lpeg = function () return jsonlpeg end
  jsonlpeg.use_lpeg = json.use_lpeg

  return jsonlpeg
end

if always_use_lpeg then
  return json.use_lpeg()
end

return json

]===])
package.preload["lar"] = lib("luax/lar.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local F = require "F"
local cbor = require "cbor"
local crypt = require "crypt"
local lz4 = require "lz4"
local lzip = require "lzip"

--[[------------------------------------------------------------------------@@@
## Lua Archive
@@@]]

--[[@@@
```lua
local lar = require "lar"
```

`lar` is a simple archive format for Lua values (e.g. Lua tables).
It contains a Lua value:

- serialized with `cbor`
- compressed with `lz4` or `lzip`
- encrypted with `arc4`

The Lua value is only encrypted if a key is provided.
@@@]]
local lar = {}

local MAGIC = "!<LuaX archive>"

local RAW  <const> = 0
local LZ4  <const> = 1
local LZIP <const> = 2

local compression_options = {
    { algo=nil,    flag=RAW,  compress=F.id,      decompress=F.id   },
    { algo="lz4",  flag=LZ4,  compress=lz4.lz4,   decompress=lz4.unlz4  },
    { algo="lzip", flag=LZIP, compress=lzip.lzip, decompress=lzip.unlzip },
}

local function find_options(x)
    for i = 1, #compression_options do
        local opt = compression_options[i]
        if x==opt.algo or x==opt.flag then return opt end
    end
    return compression_options[1]
end

--[[@@@
```lua
lar.lar(lua_value, [opt])
```
Returns a string with `lua_value` serialized, compressed and encrypted.

Options:

- `opt.compress`: compression algorithm (`"lzip"` by default):

    - `"none"`: no compression
    - `"lz4"`: compression with LZ4 (default compression level)
    - `"lz4-#"`: compression with LZ4 (compression level `#` with `#` between 0 and 12)
    - `"lzip"`: compression with lzip (default compression level)
    - `"lzip-#"`: compression with lzip (compression level `#` with `#` between 0 and 9)

- `opt.key`: encryption key (no encryption by default)
@@@]]

function lar.lar(lua_value, lar_opt)
    lar_opt = lar_opt or {}
    local algo, level = (lar_opt.compress or "lzip"):split"%-":unpack()
    local compress_opt = find_options(algo)

    local payload = cbor.encode(lua_value, {pairs=F.pairs})
    payload = assert(compress_opt.compress(payload, tonumber(level)))
    if lar_opt.key then payload = crypt.arc4(payload, lar_opt.key) end

    local data = string.pack("<zBs4", MAGIC, compress_opt.flag, payload)
    return data .. string.pack("<I8", data:crc64())
end

--[[@@@
```lua
lar.unlar(archive, [opt])
```
Returns the Lua value contained in a serialized, compressed and encrypted string.

Options:

- `opt.key`: encryption key (no encryption by default)
@@@]]

function lar.unlar(archive, opt)
    opt = opt or {}

    if type(archive)~="string" then
        error("bad argument #1 to 'unlar' (string expected, got "..type(archive)..")")
    end
    local ok, magic, compress_flag, payload, crc = pcall(string.unpack, "<zBs4I8", archive)
    assert(ok and magic==MAGIC and crc==archive:sub(1, -9):crc64(), "not a LuaX archive")

    if opt.key then payload = crypt.unarc4(payload, opt.key) end
    local compress_opt = find_options(compress_flag)
    payload = assert(compress_opt.decompress(payload))

    return cbor.decode(payload)
end

return lar
]=])
package.preload["linenoise"] = lib("luax/linenoise.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_linenoise, linenoise = pcall(require, "_linenoise")

if not has_linenoise then

    local F = require "F"
    local term = require "term"

    linenoise = setmetatable({
        read = term.prompt,
    }, {
        __index = F.const(F.const()),
    })

end

return linenoise
]=])
package.preload["luax-debug"] = lib("luax/luax-debug.lua", [==[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LOAD=_

local F = require "F"

-- This module adds some functions to the debug package.

--[=[-----------------------------------------------------------------------@@@
# debug

The standard Lua package `debug` is added some functions to help debugging.
@@@]=]

--[[@@@
```lua
debug.locals(level)
```
> table containing the local variables at a given level `level`.
  The default level is the caller level (1).
  If `level` is a function, `locals` returns the names of the function parameters.
@@@]]

function debug.locals(level)
    local vars = F{}
    if type(level) == "function" then
        local i = 1
        while true do
            local name = debug.getlocal(level, i)
            if name==nil then break end
            if not name:match "^%(" then
                vars[#vars+1] = name
            end
            i = i+1
        end
    else
        level = (level or 1) + 1
        local i = 1
        while true do
            local name, val = debug.getlocal(level, i)
            if name==nil then break end
            if not name:match "^%(" then
                vars[name] = val
            end
            i = i+1
        end
    end
    return vars
end

return debug
]==])
package.preload["luax-package"] = lib("luax/luax-package.lua", [==[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LOAD=_

local F = require "F"

local package  = require "package"

-- inspired by https://stackoverflow.com/questions/60283272/how-to-get-the-exact-path-to-the-script-that-was-loaded-in-lua

-- This module wraps package searchers in a function that tracks package paths.
-- The paths are stored in package.modpath, which can be used to generate dependency files
-- for [ypp](https://codeberg.org/cdsoft/luax) or [panda](https://codeberg.org/cdsoft/panda).

--[=[-----------------------------------------------------------------------@@@
# package

The standard Lua package `package` is added some information about packages loaded by LuaX.
@@@]=]

--[[@@@
```lua
package.modpath      -- { module_name = module_path }
```
> table containing the names of the loaded packages and their actual paths.
>
> `package.modpath` contains the names of the packages loaded by `require`, `dofile`, `loadfile`, `import`
> and `toml.parse`.

```lua
package.track(name, [path])     -- package.modpath[name] = path or name
```
> add `name` to `package.modpath`.
@@@]]

package.modpath = F{}

function package.track(name, path)
    package.modpath[name] = path or name
end

local function wrap_searcher(searcher)
    return function(modname)
        local loader, path = searcher(modname)
        if type(loader) == "function" then
            package.track(modname, path)
        end
        return loader, path
    end
end

for i = 2, #package.searchers do
    package.searchers[i] = wrap_searcher(package.searchers[i])
end

local function wrap(func)
    return function(filename, ...)
        if filename ~= nil then
            package.track(filename)
        end
        return func(filename, ...)
    end
end

dofile = wrap(dofile)
loadfile = wrap(loadfile)

local toml = require "toml"
local _toml_parse = toml.parse

---@diagnostic disable-next-line: duplicate-set-field
toml.parse = function(filename, options)
    if not options or not options.load_from_string then
        package.track(filename)
    end
    return _toml_parse(filename, options)
end

return package
]==])
package.preload["luax-targets"] = lib("luax/luax-targets.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local F = require "F"

--[[ Target definitions:

Field       Description                         Value
----------- ----------------------------------- -------------------------------------------------------------
name        LuaX target name                    "OS"-"ARCH"[-musl]
machine     architecture name                   uname -m on Linux/MacOS, %PROCESSOR_ARCHITECTURE% on Windows
kernel      OS kernel                           uname -s on Linux/MacOS, %OS% on Windows
os          OS name known by LuaX               linux, macos, windows
arch        architecture name known by LuaX     x86_64, aarch64
libc        C library name                      gnu, musl, none
exe         executable file extension           .exe on Windows
so          shared library file extension       .so, .dylib, .dll

--]]

return F{
    {name="linux-x86_64",       machine="x86_64",  kernel="Linux",      os="linux",   arch="x86_64",  libc="gnu",   exe="",     so=".so"   },
    {name="linux-x86_64-musl",  machine="x86_64",  kernel="Linux",      os="linux",   arch="x86_64",  libc="musl",  exe="",     so=".so"   },
    {name="linux-aarch64",      machine="aarch64", kernel="Linux",      os="linux",   arch="aarch64", libc="gnu",   exe="",     so=".so"   },
    {name="linux-aarch64-musl", machine="aarch64", kernel="Linux",      os="linux",   arch="aarch64", libc="musl",  exe="",     so=".so"   },
    {name="macos-x86_64",       machine="x86_64",  kernel="Darwin",     os="macos",   arch="x86_64",  libc="none",  exe="",     so=".dylib"},
    {name="macos-aarch64",      machine="arm64",   kernel="Darwin",     os="macos",   arch="aarch64", libc="none",  exe="",     so=".dylib"},
    {name="windows-x86_64",     machine="AMD64",   kernel="Windows_NT", os="windows", arch="x86_64",  libc="gnu",   exe=".exe", so=".dll"  },
    {name="windows-aarch64",    machine="ARM64",   kernel="Windows_NT", os="windows", arch="aarch64", libc="gnu",   exe=".exe", so=".dll"  },
}
]=])
package.preload["luax-version"] = lib("luax/luax-version.lua", [[local version = "10.3.1"
local year = 2026
local url = "codeberg.org/cdsoft/luax"
local author = "Christophe Delord"

--@LIB

return setmetatable({
    version = version,
    copyright = ("Copyright (C) 2021-%d %s, %s"):format(year, url, author),
    url = url,
    author = author,
}, {
    __tostring = function() return "LuaX "..version end,
})
]])
package.preload["lz4"] = lib("luax/lz4.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

-- Load lz4.lua to add new methods to strings
--@LOAD=_

local has_lz4, lz4 = pcall(require, "_lz4")

if not has_lz4 then

    lz4 = {}

    local fs = require "fs"
    local sh = require "sh"

    function lz4.lz4(s, level)
        return fs.with_tmpfile(function(tmp)
            local n = #s
            assert(sh.write(
                "lz4 -q -z",
                n <=   64*1024 and "-B4"
                or n <=  256*1024 and "-B5"
                or n <= 1024*1024 and "-B6"
                or                    "-B7",
                "-"..(level or 9),
                "-BD --frame-crc -f -", tmp)(s))
            return assert(fs.read_bin(tmp))
        end)
    end

    function lz4.unlz4(s)
        return fs.with_tmpfile(function(tmp)
            assert(sh.write("lz4 -q -d -f -", tmp)(s))
            return assert(fs.read_bin(tmp))
        end)
    end

end

--[[------------------------------------------------------------------------@@@
## String methods

The `lz4` functions are also available as `string` methods:
@@@]]

--[[@@@
```lua
s:lz4()         == lz4.lz4(s)
s:unlz4()       == lz4.unlz4(s)
```
@@@]]

string.lz4      = lz4.lz4
string.unlz4    = lz4.unlz4

return lz4
]=])
package.preload["lzip"] = lib("luax/lzip.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

-- Load lzip.lua to add new methods to strings
--@LOAD=_

local has_lzip, lzip = pcall(require, "_lzip")

if not has_lzip then

    lzip = {}

    local fs = require "fs"
    local sh = require "sh"

    function lzip.lzip(s, level)
        return fs.with_tmpdir(function(tmp)
            local input = tmp/"data"
            local output = tmp/"data.lz"
            assert(fs.write_bin(input, s))
            assert(sh.run(
                "lzip -q",
                "-"..(level or 6),
                input,
                "-o", output))
            return assert(fs.read_bin(output))
        end)
    end

    function lzip.unlzip(s)
        return fs.with_tmpdir(function(tmp)
            local input = tmp/"data.lz"
            local output = tmp/"data"
            assert(fs.write_bin(input, s))
            assert(sh.run("lzip -q -d", input, "-o", output))
            return assert(fs.read_bin(output))
        end)
    end

end

--[[------------------------------------------------------------------------@@@
## String methods

The `lzip` functions are also available as `string` methods:
@@@]]

--[[@@@
```lua
s:lzip()        == lzip.lzip(s)
s:unlzip()      == lzip.unlzip(s)
```
@@@]]

string.lzip     = lzip.lzip
string.unlzip   = lzip.unlzip

return lzip
]=])
package.preload["mathx"] = lib("luax/mathx.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_mathx, mathx = pcall(require, "_mathx")
if has_mathx then return mathx end

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

local inf <const> = 1/0

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

return mathx
]=])
package.preload["ps"] = lib("luax/ps.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_ps, ps = pcall(require, "_ps")

if not has_ps then

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
]=])
package.preload["qmath"] = lib("luax/qmath.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB
local has_qmath, qmath = pcall(require, "_qmath")

if not has_qmath then

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

    local rat_zero <const> = rat(0)
    local rat_one <const> = rat(1)

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
## qmath additional functions
@@@]]

--[[@@@
```lua
q = qmath.torat(x, [eps])
```
approximates a floating point number `x` with a rational value.
The rational number `q` is an approximation of `x` such that $|q - x| < eps$.
The default `eps` value is $10^{-6}$.
@@@]]

local rat = qmath.new
local abs = math.abs
local modf = math.modf

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
    local a = {}
    a[1], x = modf(x)
    local q = frac(a)
    while abs(x0 - q:tonumber()) > eps and #a < 64 do
        a[#a+1], x = modf(1/x)
        q = frac(a)
    end
    return q
end

return qmath
]=])
package.preload["readline"] = lib("luax/readline.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_readline, readline = pcall(require, "_readline")

if not has_readline then

    local F = require "F"
    local term = require "term"

    readline = setmetatable({
        read = term.prompt,
    }, {
        __index = F.const(F.const()),
    })

end

return readline
]=])
package.preload["serpent"] = lib("luax/serpent.lua", [=[local n, v = "serpent", "0.303" -- (C) 2012-18 Paul Kulchenko; MIT License
local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
local badtype = {thread = true, userdata = true, cdata = true}
local getmetatable = debug and debug.getmetatable or getmetatable
local pairs = function(t) return next, t end -- avoid using __pairs in Lua 5.2+
local keyword, globals, G = {}, {}, (_G or _ENV)
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'global', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do if v==v then globals[v] = g..'.'..k end end end

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
]=])
package.preload["sh"] = lib("luax/sh.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
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
local sys = require "sys"

local __WINDOWS__ = sys.os == "windows"

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
        if type(data) ~= "string" then
            return nil, "bad argument #1 to 'write' (string expected, got "..type(data)..")"
        end
        local p, popen_err = io.popen(cmd, "w")
        if not p then return p, popen_err end
        p:write(data)
        return p:close()
    end
end

--[[@@@
```lua
sh.pipe(...)(data)
```
Runs the command `...` with `io.popen` and feeds `stdin` with `data`.
When `sh.pipe` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `io.popen`.
@@@]]

function sh.pipe(...)
    local cmd = F.flatten{...}
    local cat = __WINDOWS__ and "type" or "cat"
    return function(data)
        local fs = require "fs"
        if type(data) ~= "string" then
            return nil, "bad argument #1 to 'write' (string expected, got "..type(data)..")"
        end
        return fs.with_tmpfile(function(tmp)
            fs.write_bin(tmp, data)
            return sh.read(cat, tmp, " | ", cmd)
        end)
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
]=])
package.preload["strict"] = lib("luax/strict.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--[[------------------------------------------------------------------------@@@
# strict: checks uses of undeclared global variables

The `strict` module checks uses of undeclared global variables.
All global variables must be 'declared' through a regular assignment
(even assigning nil will do) in a main chunk before being used
anywhere or assigned to inside a function.

```lua
require "strict"
```

This module is `strict.lua` <from https://www.lua.org/extras/>
adpated for LuaX.

This module not loaded by default since some global variables are tested when LuaX start but may not be defined.
@@@]]

--@LIB

-- strict.lua
-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.
-- distributed under the Lua license: http://www.lua.org/license.html

local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget

local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

mt.__declared = {}

local function what ()
  local d = getinfo(3, "S")
  return d and d.what or "C"
end

mt.__newindex = function (t, n, v)
  if not mt.__declared[n] then
    local w = what()
    if w ~= "main" and w ~= "C" then
      error("assign to undeclared variable '"..n.."'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end

mt.__index = function (t, n)
  if not mt.__declared[n] and what() ~= "C" then
    error("variable '"..n.."' is not declared", 2)
  end
  return rawget(t, n)
end
]=])
package.preload["sys"] = lib("luax/sys.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

local has_sys, sys = pcall(require, "_sys")

if not has_sys then

    sys = {
        libc = "lua",
    }

    local targets = require "luax-targets"

    local kernel, machine

    if package.config:sub(1, 1) == "/" then
        -- Search for a Linux-like target
        kernel, machine = io.popen("uname -s -m", "r") : read "a" : match "(%S+)%s+(%S+)"
    else
        -- Search for a Windows target
        kernel, machine = os.getenv "OS", os.getenv "PROCESSOR_ARCHITECTURE"
    end

    local target
    for i = 1, #targets do
        if targets[i].kernel==kernel and targets[i].machine==machine then
            target = targets[i]
            break
        end
    end

    if not target then
        io.stderr:write("ERROR: Unknown architecture\n",
            "Please report the bug with this information:\n",
            "    config  = "..package.config:lines():head().."\n",
            "    kernel  = "..tostring(kernel).."\n",
            "    machine = "..tostring(machine).."\n",
            ">> https://codeberg.org/cdsoft/luax/issues <<\n"
        )
        os.exit(1)
    end

    sys.name = target.name
    sys.os = target.os
    sys.arch = target.arch
    sys.exe = target.exe
    sys.so = target.so

end

return sys
]=])
package.preload["tar"] = lib("luax/tar.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

--[[------------------------------------------------------------------------@@@
# Minimal tar file support

```lua
local tar = require "tar"
```

The `tar` module can read and write tar archives.
Only files, directories and symbolic links are supported.
@@@]]

-- https://fr.wikipedia.org/wiki/Tar_%28informatique%29

local tar = {}

local F = require "F"
local fs = require "fs"
local sys = require "sys"

local __WINDOWS__ = sys.os == "windows"

local format = string.format
local pack   = string.pack
local unpack = string.unpack
local rep    = string.rep
local bytes  = string.bytes
local sum    = F.sum

local function pad(size)
    return (512 - size%512) % 512
end

local file_type = F{
    file = "0",
    link = "2",
    directory = "5",
}

local rev_file_type = file_type:mapk2a(function(k, v) return {v, k} end):from_list()
rev_file_type["\0"] = rev_file_type["0"]

local default_mode = {
    file = tonumber("644", 8),
    link = tonumber("777", 8),
    directory = tonumber("755", 8),
}

local Discarded = {}

local function path_components(path)
    local function is_sep(d) return d==fs.sep or d=="." or d==" " end
    return fs.splitpath(path):drop_while(is_sep):drop_while_end(is_sep)
end

local function clean_path(path)
    return fs.join(path_components(path))
end

local function header(st, xform)
    local name = xform(clean_path(st.name))
    if name == nil then return Discarded end
    if #name > 100 then return nil, name..": filename too long" end
    if st.type=="file" and st.size >= 8*1024^3 then return nil, st.name..": file too big" end
    local ftype = file_type[st.type]
    if not ftype then return nil, st.name..": wrong file type" end
    if st.type=="link" and not st.link then return nil, st.name..": missing link name" end
    if st.link and #st.link > 100 then return nil, st.link..": filename too long" end
    local header1 = pack("c100c8c8c8c12c12",
        name,
        format("%07o", st.mode or default_mode[st.type] or "0"),
        "",
        "",
        format("%011o", st.size or 0),
        format("%011o", st.mtime)
    )
    local header2 = pack("c1c100c6c2c32c32c8c8c155c12",
        ftype,
        st.link or "",
        "", "", "", "", "", "", "", ""
    )
    local checksum = format("%07o", sum(bytes(header1)) + sum(bytes(header2)) + 32*8)
    return header1..pack("c8", checksum)..header2
end

local function end_of_archive()
    return pack("c1024", "")
end

local function parse(archive, i)
    local name, mode, _, _, size, mtime, checksum, ftype, link = unpack("c100c8c8c8c12c12c8c1c100", archive, i)
    if not checksum then return nil, "Corrupted archive" end
    local function cut(s) return s:match "^[^\0]*" end
    if sum(bytes(archive:sub(i, i+148-1))) + sum(bytes(archive:sub(i+156, i+512-1))) + 32*8 ~= tonumber(cut(checksum), 8) then
        return nil, "Wrong checksum"
    end
    ftype = rev_file_type[ftype]
    if not ftype then return nil, cut(name)..": wrong file type" end
    return {
        name = cut(name),
        mode = tonumber(cut(mode), 8),
        size = tonumber(cut(size), 8),
        mtime = tonumber(cut(mtime), 8),
        type = ftype,
        link = ftype=="link" and cut(link) or nil,
    }
end

--[[@@@
```lua
tar.tar(files, [xform])
```
> returns a string that can be saved as a tar file.
> `files` is a list of file names or `stat` like structures.
> `stat` structures shall contain these fields:
>
> - `name`: file name
> - `mtime`: last modification time
> - `content`: file content (the default value is the actual content of the file `name`).
>
> **Note**: these structures can also be produced by `fs.stat`.
>
> `xform` is an optional function used to transform filenames in the archive.
@@@]]

function tar.tar(files, xform)
    xform = xform or F.id
    local chunks = F{}

    local already_done = {}
    local function done(name)
        if already_done[name] then return true end
        already_done[name] = true
        return false
    end

    local function add_dir(path, st0)
        if done(path) then return true end
        if path:dirname() == path then return true end
        local ok, err = add_dir(path:dirname(), st0)
        if not ok then return nil, err end
        local st = F.merge{st0, { name=path, mode=tonumber("755", 8), size=0, type="directory" }}
        local hd
        hd, err = header(st, F.id)
        if not hd then return nil, err end
        chunks[#chunks+1] = hd
        return true
    end

    local function add_file(st)
        local xformed_name = xform(st.name)
        if xformed_name == nil then return true end
        if done(xformed_name) then return true end
        local ok, err = add_dir(xformed_name:dirname(), st)
        if not ok then return nil, err end
        local hd
        hd, err = header(st, xform)
        if hd == Discarded then return true end
        if not hd then return nil, err end
        chunks[#chunks+1] = hd
        chunks[#chunks+1] = st.content
        chunks[#chunks+1] = rep("\0", pad(#st.content))
        return true
    end

    local function add_link(st)
        local xformed_name = xform(st.name)
        if xformed_name == nil then return true end
        if done(xformed_name) then return true end
        local ok, err = add_dir(xformed_name:dirname(), st)
        if not ok then return nil, err end
        local hd
        hd, err = header(st, xform)
        if hd == Discarded then return true end
        if not hd then return nil, err end
        chunks[#chunks+1] = hd
        return true
    end

    local function add_real_dir(path)
        if done(path) then return true end
        if path:dirname() == path then return true end
        local ok, err = add_real_dir(path:dirname())
        if not ok then return nil, err end
        local st
        st, err = fs.stat(path)
        if not st then return nil, err end
        local hd
        hd, err = header(st, xform)
        if hd == Discarded then return true end
        if not hd then return nil, err end
        chunks[#chunks+1] = hd
        return true
    end

    local function add_real_file(st)
        local xformed_name = xform(st.name)
        if xformed_name == nil then return true end
        if done(xformed_name) then return true end
        local ok, err = add_real_dir(st.name:dirname())
        if not ok then return nil, err end
        local hd
        hd, err = header(st, xform)
        if hd == Discarded then return true end
        if not hd then return nil, err end
        local content
        content, err = fs.read_bin(st.name)
        if not content then return nil, err end
        chunks[#chunks+1] = hd
        chunks[#chunks+1] = content
        chunks[#chunks+1] = rep("\0", pad(#content))
        return true
    end

    local function add_real_link(st)
        local xformed_name = xform(st.name)
        if xformed_name == nil then return true end
        if done(xformed_name) then return true end
        local linkst, sterr = fs.stat(st.name)
        if not linkst then return nil, sterr end
        local ok, err = add_real_dir(st.name:dirname())
        if not ok then return nil, err end
        local hd
        st.link = linkst.name
        hd, err = header(st, xform)
        if hd == Discarded then return true end
        if not hd then return nil, err end
        chunks[#chunks+1] = hd
        return true
    end

    for _, file in ipairs(files) do

        if type(file) == "string" then
            local st, err = fs.stat(file)
            if not st then return nil, err end
            if st.type == "file" then
                add_real_file(st)
            elseif st.type == "link" then
                add_real_link(st)
            elseif st.type == "directory" then
                add_real_dir(st.name)
                for _, name in ipairs(fs.ls(st.name/"**")) do
                    local childst, childerr = fs.stat(name)
                    if not childst then return nil, childerr end
                    if childst.type == "directory" then
                        add_real_dir(childst.name)
                    elseif childst.type == "file" then
                        add_real_file(childst)
                    end
                end
            end

        elseif type(file) == "table" then
            local st0 = nil
            local err
            local st = {
                name = file.name,
                type = "file",
            }
            if file.content then
                st.content = file.content
                st.size = #file.content
            elseif file.link then
                st.type = "link"
                st.link = file.link
            else
                if __WINDOWS__ then
                    st0, err = fs.stat(file.name)
                else
                    st0, err = fs.lstat(file.name)
                end
                if not st0 then return nil, err end
                if st0.type == "link" then
                    local linkst, linkerr = fs.stat(file.name)
                    if not linkst then return nil, linkerr end
                    st.type = "link"
                    st.link = linkst.name
                else
                    local content
                    content, err = fs.read_bin(file.name)
                    if not content then return nil, err end
                    st.size = st0.size
                    st.content = content
                end
            end
            if file.mtime then
                st.mtime = file.mtime
            else
                st.mtime = st0 and st0.mtime or os.time()
            end
            local ok
            if st.type == "link" then
                ok, err = add_link(st)
            else
                ok, err = add_file(st)
            end
            if not ok then return nil, err end

        end

    end

    chunks[#chunks+1] = end_of_archive()
    return chunks:str()

end

--[[@@@
```lua
tar.untar(archive, [xform])
```
> returns a list of files (`stat` like structures with a `content` field).
>
> `xform` is an optional function used to transform filenames in the archive.
@@@]]

function tar.untar(archive, xform)
    xform = xform or F.id
    if #archive % 512 ~= 0 then return nil, "Corrupted archive" end
    local eof = end_of_archive()
    local files = F{}
    local i = 1
    while i <= #archive do
        if archive:byte(i, i) == 0 then
            if archive:sub(i, i+#eof-1):is_prefix_of(eof) then break end
            return nil, "Corrupted archive"
        end
        local st, err = parse(archive, i)
        if not st then return nil, err end
        if st.type == "file" then
            st.content = archive:sub(i+512, i+512+st.size-1)
            i = i + 512 + st.size + pad(st.size)
        elseif st.type == "link" or st.type == "directory" then
            i = i + 512
        else
            return nil, st.type..": file type not supported"
        end
        st.name = xform(st.name)
        if st.name ~= nil then
            files[#files+1] = st
        end
    end
    return files
end

--[[@@@
```lua
tar.chain(xforms)
```
> returns a filename transformation function that applies all functions from `funcs`.
@@@]]

function tar.chain(funcs)
    return function(x)
        for _, f in ipairs(funcs) do
            x = f(clean_path(x))
            if x == nil then return nil end
        end
        return clean_path(x)
    end
end

--[[@@@
```lua
tar.strip(x)
```
> returns a transformation function that removes part of the beginning of a filename.
> If `x` is a number, the function removes `x` path components in the filename.
> If `x` is a string, the function removes `x` at the beginning of the filename.
@@@]]

function tar.strip(x)
    if type(x) == "number" then
        return function(path)
            local dirs = path_components(path:dirname())
            if x > #dirs then return nil end
            return clean_path(fs.join(dirs:drop(x))/path:basename())
        end
    else
        local prefix = clean_path(x)
        return function(path)
            path = clean_path(path)
            if path:has_prefix(prefix) then
                return clean_path(path:sub(#prefix+1))
            else
                return path
            end
        end
    end
end

--[[@@@
```lua
tar.add(p)
```
> returns a transformation function that adds `p` at the beginning of a filename.
@@@]]

function tar.add(p)
    local prefix = path_components(p)
    return function(path)
        local components = path_components(path)
        return clean_path(fs.join(prefix..components))
    end
end

--[[@@@
```lua
tar.xform(x, y)
```
> returns a transformation function that chains `tar.strip(x)` and `tar.add(y)`.
@@@]]

function tar.xform(x, y)
    return tar.chain { tar.strip(x), tar.add(y) }
end

return tar
]=])
package.preload["term"] = lib("luax/term.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
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

--@LIB

local has_term, term = pcall(require, "_term")

if not has_term then

    term = {}

    local sh = require "sh"

    local function file_descriptor(fd, def)
        if fd == nil then return def end
        if fd == io.stdin then return 0 end
        if fd == io.stdout then return 1 end
        if fd == io.stderr then return 2 end
        return fd
    end

    local _isatty = {}

    function term.isatty(fd)
        fd = file_descriptor(fd, 0)
        _isatty[fd] = _isatty[fd] or sh.run("test -t", fd)~=nil
        return _isatty[fd]
    end

    function term.size()
        local size = sh.read("tput lines cols")
        if size then
            local rows, cols = size : words() : map(tonumber) : unpack()
            return { rows=rows, cols=cols }
        end
    end

end

local ESC <const> = '\027'
local CSI <const> = ESC..'['

--[[------------------------------------------------------------------------@@@
## Colors

The table `term.color` contain objects that can be used to build
colorized strings with ANSI sequences.

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

The user can disable the color support (e.g. when not running on a terminal):

``` lua
if not term.isatty(io.stdout) then
    term.color.disable()
end
```
@@@]]

local color_mt, color_reset
local color_enable = true
color_mt = {
    __tostring = function(self) return color_enable and self.value or ""end,
    __concat = function(self, other) return tostring(self)..tostring(other) end,
    __call = function(self, s) return color_enable and self..s..color_reset or s end,
    __add = function(self, other) return setmetatable({value=self.value..other}, color_mt) end,
}
local function color(value) return setmetatable({value=CSI..tostring(value).."m"}, color_mt) end
local function enable(en) color_enable = en==nil or en end
local function disable() color_enable = false end
--                                @@@| `term.color` field     | Description                          |@@@
--                                @@@| ---------------------- | ------------------------------------ |@@@
term.color = {
    -- attributes               --@@@| *Attributes*           |                                      |@@@
    reset       = color(0),     --@@@| `reset`                | reset the colors                     |@@@
    clear       = color(0),     --@@@| `clear`                | same as reset                        |@@@
    default     = color(0),     --@@@| `default`              | same as reset                        |@@@
    bright      = color(1),     --@@@| `bright`               | bold or more intense                 |@@@
    bold        = color(1),     --@@@| `bold`                 | same as bold                         |@@@
    dim         = color(2),     --@@@| `dim`                  | thiner or less intense               |@@@
    italic      = color(3),     --@@@| `italic`               | italic (sometimes inverse or blink)  |@@@
    underline   = color(4),     --@@@| `underline`            | underlined                           |@@@
    blink       = color(5),     --@@@| `blink`                | slow blinking (less than 150 bpm)    |@@@
    fast        = color(6),     --@@@| `fast`                 | fast blinking (more than 150 bpm)    |@@@
    reverse     = color(7),     --@@@| `reverse`              | swap foreground and background       |@@@
    hidden      = color(8),     --@@@| `hidden`               | hidden text                          |@@@
    strike      = color(9),     --@@@| `strike`               | strike or crossed-out                |@@@
    -- foreground               --@@@| *Foreground colors*    |                                      |@@@
    black       = color(30),    --@@@| `black`                | black foreground                     |@@@
    red         = color(31),    --@@@| `red`                  | red foreground                       |@@@
    green       = color(32),    --@@@| `green`                | green foreground                     |@@@
    yellow      = color(33),    --@@@| `yellow`               | yellow foreground                    |@@@
    blue        = color(34),    --@@@| `blue`                 | blue foreground                      |@@@
    magenta     = color(35),    --@@@| `magenta`              | magenta foreground                   |@@@
    cyan        = color(36),    --@@@| `cyan`                 | cyan foreground                      |@@@
    white       = color(37),    --@@@| `white`                | white foreground                     |@@@
    -- background               --@@@| *Background colors*    |                                      |@@@
    onblack     = color(40),    --@@@| `onblack`              | black background                     |@@@
    onred       = color(41),    --@@@| `onred`                | red background                       |@@@
    ongreen     = color(42),    --@@@| `ongreen`              | green background                     |@@@
    onyellow    = color(43),    --@@@| `onyellow`             | yellow background                    |@@@
    onblue      = color(44),    --@@@| `onblue`               | blue background                      |@@@
    onmagenta   = color(45),    --@@@| `onmagenta`            | magenta background                   |@@@
    oncyan      = color(46),    --@@@| `oncyan`               | cyan background                      |@@@
    onwhite     = color(47),    --@@@| `onwhite`              | white background                     |@@@
    -- enable/disable           --@@@| *Control functions*    |                                      |@@@
    enable      = enable,       --@@@| `enable(b)`            | enable colors if `b` is `true` or `nil` (default) |@@@
    disable     = disable,      --@@@| `disable`              | disable colors                       |@@@
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

--                                  @@@| `term.cursor` field      | Description                 |@@@
--                                  @@@| ------------------------ | --------------------------- |@@@
term.cursor = {
    reset           = cursor(0),  --@@@| `reset`                  | reset to the initial shape  |@@@
    block_blink     = cursor(1),  --@@@| `block_blink`            | blinking block cursor       |@@@
    block           = cursor(2),  --@@@| `block`                  | fixed block cursor          |@@@
    underline_blink = cursor(3),  --@@@| `underline_blink`        | blinking underline cursor   |@@@
    underline       = cursor(4),  --@@@| `underline`              | fixed underline cursor      |@@@
    bar_blink       = cursor(5),  --@@@| `bar_blink`              | blinking bar cursor         |@@@
    bar             = cursor(6),  --@@@| `bar`                    | fixed bar cursor            |@@@
}

--[[------------------------------------------------------------------------@@@
## Terminal

@@@]]

local function f(fmt)
    return function(h, ...)
        if io.type(h) == "file" then
            return h:write(fmt:format(...))
        else
            return io.stdout:write(fmt:format(h, ...))
        end
    end
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
    if p and term.isatty(io.stdin) then
        io.stdout:write(p)
        io.stdout:flush()
    end
    return io.stdin:read "l"
end

--[[------------------------------------------------------------------------@@@
## Title

Set the terminal title.
@@@]]

--[[@@@
```lua
term.title(t)
```
sets the terminal title.
@@@]]

function term.title(t)
    if term.isatty(io.stdout) then
        io.stdout:write(ESC, "]0;", t, "\a")
        io.stdout:flush()
    end
end


return term
]=])
package.preload["toml"] = lib("luax/toml.lua", [=[



















local tinytoml = {}








local TOML_VERSION = "1.1.0"
tinytoml._VERSION = "tinytoml 1.0.0"
tinytoml._TOML_VERSION = TOML_VERSION
tinytoml._DESCRIPTION = "a single-file pure Lua TOML parser"
tinytoml._URL = "https://github.com/FourierTransformer/tinytoml"
tinytoml._LICENSE = "MIT"

























































































































local sbyte = string.byte
local chars = {
   SINGLE_QUOTE = sbyte("'"),
   DOUBLE_QUOTE = sbyte('"'),
   OPEN_BRACKET = sbyte("["),
   CLOSE_BRACKET = sbyte("]"),
   BACKSLASH = sbyte("\\"),
   COMMA = sbyte(","),
   POUND = sbyte("#"),
   DOT = sbyte("."),
   CR = sbyte("\r"),
   LF = sbyte("\n"),
}


local function replace_control_chars(s)
   return string.gsub(s, "[%z\001-\008\011-\031\127]", function(c)
      return string.format("\\x%02x", string.byte(c))
   end)
end

local function _error(sm, message, anchor)
   local error_message = {}



   if sm.filename then
      error_message = { "\n\nIn '", sm.filename, "', line ", sm.line_number, ":\n\n  " }

      local _, end_line = sm.input:find(".-\n", sm.line_number_char_index)
      error_message[#error_message + 1] = sm.line_number
      error_message[#error_message + 1] = " | "
      error_message[#error_message + 1] = replace_control_chars(sm.input:sub(sm.line_number_char_index, end_line))
      error_message[#error_message + 1] = (end_line and "\n" or "\n\n")
   end

   error_message[#error_message + 1] = message
   error_message[#error_message + 1] = "\n"

   if anchor ~= nil then
      error_message[#error_message + 1] = "\nSee https://toml.io/en/v"
      error_message[#error_message + 1] = TOML_VERSION
      error_message[#error_message + 1] = "#"
      error_message[#error_message + 1] = anchor
      error_message[#error_message + 1] = " for more details"
   end

   error(table.concat(error_message))
end

local F = require "F"
local _unpack = unpack or table.unpack
local _tointeger = math.tointeger or tonumber

local _utf8char = utf8 and utf8.char or function(cp)
   if cp < 128 then
      return string.char(cp)
   end
   local suffix = cp % 64
   local c4 = 128 + suffix
   cp = (cp - suffix) / 64
   if cp < 32 then
      return string.char(192 + (cp), (c4))
   end
   suffix = cp % 64
   local c3 = 128 + suffix
   cp = (cp - suffix) / 64
   if cp < 16 then
      return string.char(224 + (cp), c3, c4)
   end
   suffix = cp % 64
   cp = (cp - suffix) / 64
   return string.char(240 + (cp), 128 + (suffix), c3, c4)
end

local function validate_utf8(input, toml_sub)
   local i, len, line_number, line_number_start = 1, #input, 1, 1
   local byte, second, third, fourth = 0, 129, 129, 129
   toml_sub = toml_sub or false
   while i <= len do
      byte = sbyte(input, i)

      if byte <= 127 then
         if toml_sub then
            if byte < 9 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings"
            elseif byte == chars.CR and sbyte(input, i + 1) ~= chars.LF then return false, line_number, line_number_start, "TOML requires all '\\r' be followed by '\\n'"
            elseif byte == chars.LF then
               line_number = line_number + 1
               line_number_start = i + 1
            elseif byte >= 11 and byte <= 31 and byte ~= 13 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings"
            elseif byte == 127 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings" end
         end
         i = i + 1

      elseif byte >= 194 and byte <= 223 then
         second = sbyte(input, i + 1)
         i = i + 2

      elseif byte == 224 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)

         if second ~= nil and second >= 128 and second <= 159 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 3

      elseif byte == 237 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)

         if second ~= nil and second >= 160 and second <= 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 3

      elseif (byte >= 225 and byte <= 236) or byte == 238 or byte == 239 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)
         i = i + 3

      elseif byte == 240 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)

         if second ~= nil and second >= 128 and second <= 143 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 4

      elseif byte == 241 or byte == 242 or byte == 243 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)
         i = i + 4

      elseif byte == 244 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)

         if second ~= nil and second >= 160 and second <= 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 4

      else

         return false, line_number, line_number_start, "Invalid UTF-8 Sequence"
      end


      if second == nil or second < 128 or second > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
      if third == nil or third < 128 or third > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
      if fourth == nil or fourth < 128 or fourth > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end

   end
   return true
end

local function find_newline(sm)
   sm._, sm.end_seq = sm.input:find("\r?\n", sm.i)

   if sm.end_seq == nil then
      sm._, sm.end_seq = sm.input:find(".-$", sm.i)
   end
   sm.line_number = sm.line_number + 1
   sm.i = sm.end_seq + 1
   sm.line_number_char_index = sm.i
end

local escape_sequences = {
   ['b'] = '\b',
   ['t'] = '\t',
   ['n'] = '\n',
   ['f'] = '\f',
   ['r'] = '\r',
   ['e'] = '\027',
   ['\\'] = '\\',
   ['"'] = '"',
}


local function handle_backslash_escape(sm)


   if sm.multiline_string then
      if sm.input:find("^\\[ \t]-\r?\n", sm.i) then
         sm._, sm.end_seq = sm.input:find("%S", sm.i + 1)
         sm.i = sm.end_seq - 1
         return "", false
      end
   end


   sm._, sm.end_seq, sm.match = sm.input:find('^([\\btrfne"])', sm.i + 1)
   local escape = escape_sequences[sm.match]
   if escape then
      sm.i = sm.end_seq
      if sm.match == '"' then
         return escape, true
      else
         return escape, false
      end
   end


   sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(x)([0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   if sm.match then
      local codepoint_to_insert = _utf8char(tonumber(sm.ext, 16))
      if not validate_utf8(codepoint_to_insert) then
         _error(sm, "Escaped UTF-8 sequence not valid UTF-8 character: '\\" .. sm.match .. sm.ext .. "'", "string")
      end
      sm.i = sm.end_seq
      return codepoint_to_insert, false
   end


   sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(u)([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   if not sm.match then
      sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(U)([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   end
   if sm.match then
      local codepoint_to_insert = _utf8char(tonumber(sm.ext, 16))
      if not validate_utf8(codepoint_to_insert) then
         _error(sm, "Escaped UTF-8 sequence not valid UTF-8 character: '\\" .. sm.match .. sm.ext .. "'", "string")
      end
      sm.i = sm.end_seq
      return codepoint_to_insert, false
   end

   return nil
end

local function close_string(sm)
   local escape
   local reset_quote
   local start_field, end_field = sm.i + 1, 0
   local second, third = sbyte(sm.input, sm.i + 1), sbyte(sm.input, sm.i + 2)
   local quote_count = 0
   local output = {}
   local found_closing_quote = false
   sm.multiline_string = false


   if second == chars.DOUBLE_QUOTE and third == chars.DOUBLE_QUOTE then
      if sm.mode == "table" then _error(sm, "Cannot have multiline strings as table keys", "table") end
      sm.multiline_string = true
      start_field = sm.i + 3

      second, third = sbyte(sm.input, sm.i + 3), sbyte(sm.input, sm.i + 4)
      if second == chars.LF then
         start_field = start_field + 1
      elseif second == chars.CR and third == chars.LF then
         start_field = start_field + 2
      end
      sm.i = start_field - 1
   end

   while found_closing_quote == false and sm.i <= sm.input_length do
      sm.i = sm.i + 1
      sm.byte = sbyte(sm.input, sm.i)
      if sm.byte == chars.BACKSLASH then
         output[#output + 1] = sm.input:sub(start_field, sm.i - 1)

         escape, reset_quote = handle_backslash_escape(sm)
         if reset_quote then quote_count = 0 end

         if escape ~= nil then
            output[#output + 1] = escape
         else
            sm._, sm._, sm.match = sm.input:find("(.-[^'\"])", sm.i + 1)
            _error(sm, "TOML only allows specific escape sequences. Invalid escape sequence found: '\\" .. sm.match .. "'", "string")
         end

         start_field = sm.i + 1

      elseif sm.multiline_string then
         if sm.byte == chars.DOUBLE_QUOTE then
            quote_count = quote_count + 1
            if quote_count == 5 then
               end_field = sm.i - 3
               output[#output + 1] = sm.input:sub(start_field, end_field)
               found_closing_quote = true
               break
            end
         else
            if quote_count >= 3 then
               end_field = sm.i - 4
               output[#output + 1] = sm.input:sub(start_field, end_field)
               found_closing_quote = true
               sm.i = sm.i - 1
               break
            else
               quote_count = 0
            end
         end

      else
         if sm.byte == chars.DOUBLE_QUOTE then
            end_field = sm.i - 1
            output[#output + 1] = sm.input:sub(start_field, end_field)
            found_closing_quote = true
            break
         elseif sm.byte == chars.CR or sm.byte == chars.LF then
            _error(sm, "String does not appear to be closed. Use multi-line (triple quoted) strings if non-escaped newlines are desired.", "string")
         end
      end
   end

   if not found_closing_quote then
      if sm.multiline_string then
         _error(sm, "Unable to find closing triple-quotes for multi-line string", "string")
      else
         _error(sm, "Unable to find closing quote for string", "string")
      end
   end

   sm.i = sm.i + 1
   sm.value = table.concat(output)
   sm.value_type = "string"
end

local function close_literal_string(sm)
   sm.byte = 0
   local start_field, end_field = sm.i + 1, 0
   local second, third = sbyte(sm.input, sm.i + 1), sbyte(sm.input, sm.i + 2)
   local quote_count = 0
   sm.multiline_string = false


   if second == chars.SINGLE_QUOTE and third == chars.SINGLE_QUOTE then
      if sm.mode == "table" then _error(sm, "Cannot have multiline strings as table keys", "table") end
      sm.multiline_string = true
      start_field = sm.i + 3

      second, third = sbyte(sm.input, sm.i + 3), sbyte(sm.input, sm.i + 4)
      if second == chars.LF then
         start_field = start_field + 1
      elseif second == chars.CR and third == chars.LF then
         start_field = start_field + 2
      end
      sm.i = start_field
   end

   while end_field ~= 0 or sm.i <= sm.input_length do
      sm.i = sm.i + 1
      sm.byte = sbyte(sm.input, sm.i)
      if sm.multiline_string then
         if sm.byte == chars.SINGLE_QUOTE then
            quote_count = quote_count + 1
            if quote_count == 5 then
               end_field = sm.i - 3
               break
            end
         else
            if quote_count >= 3 then
               end_field = sm.i - 4
               sm.i = sm.i - 1
               break
            else
               quote_count = 0
            end
         end

      else
         if sm.byte == chars.SINGLE_QUOTE then
            end_field = sm.i - 1
            break
         elseif sm.byte == chars.CR or sm.byte == chars.LF then
            _error(sm, "String does not appear to be closed. Use multi-line (triple quoted) strings if non-escaped newlines are desired.", "string")
         end
      end
   end

   if end_field == 0 then
      if sm.multiline_string then
         _error(sm, "Unable to find closing triple quotes for multi-line literal string", "string")
      else
         _error(sm, "Unable to find closing quote for literal string", "string")
      end
   end

   sm.i = sm.i + 1
   sm.value = sm.input:sub(start_field, end_field)
   sm.value_type = "string"
end

local function close_bare_string(sm)
   sm._, sm.end_seq, sm.match = sm.input:find("^([a-zA-Z0-9-_]+)", sm.i)
   if sm.match then
      sm.i = sm.end_seq + 1
      sm.multiline_string = false
      sm.value = sm.match
      sm.value_type = "string"
   else
      _error(sm, "Bare keys can only contain 'a-zA-Z0-9-_'. Invalid bare key found: '" .. sm.input:sub(sm.input:find("[^ #\r\n,]+", sm.i)) .. "'", "keys")
   end
end


local function remove_underscores_number(sm, number, anchor)
   if number:find("_") then
      if number:find("__") then _error(sm, "Numbers cannot have consecutive underscores. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      if number:find("^_") or number:find("_$") then _error(sm, "Underscores are not allowed at beginning or end of a number. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      if number:find("%D_%d") or number:find("%d_%D") then _error(sm, "Underscores must have digits on either side. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      number = number:gsub("_", "")
   end
   return number
end

local integer_match = {
   ["b"] = { "^0b([01_]+)$", 2 },
   ["o"] = { "^0o([0-7_]+)$", 8 },
   ["x"] = { "^0x([0-9a-fA-F_]+)$", 16 },
}

local function validate_integer(sm, value)
   sm._, sm._, sm.match = value:find("^([-+]?[%d_]+)$")
   if sm.match then
      if sm.match:find("^[-+]?0[%d_]") then _error(sm, "Integers can't start with a leading 0. Found integer: '" .. sm.match .. "'", "integer") end
      sm.match = remove_underscores_number(sm, sm.match, "integer")
      sm.value = _tointeger(sm.match)
      sm.value_type = "integer"
      return true
   end

   if value:find("^0[box]") then
      local pattern_bits = integer_match[value:sub(2, 2)]
      sm._, sm._, sm.match = value:find(pattern_bits[1])
      if sm.match then
         sm.match = remove_underscores_number(sm, sm.match, "integer")
         sm.value = tonumber(sm.match, pattern_bits[2])
         sm.value_type = "integer"
         return true
      end
   end
end

local function validate_float(sm, value)
   sm._, sm._, sm.match, sm.ext = value:find("^([-+]?[%d_]+%.[%d_]+)(.*)$")
   if sm.match then
      if sm.match:find("%._") or sm.match:find("_%.") then _error(sm, "Underscores in floats must have a number on either side. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      if sm.match:find("^[-+]?0[%d_]") then _error(sm, "Floats can't start with a leading 0. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      sm.match = remove_underscores_number(sm, sm.match, "float")
      if sm.ext ~= "" then
         if sm.ext:find("^[eE][-+]?[%d_]+$") then
            sm.ext = remove_underscores_number(sm, sm.ext, "float")
            sm.value = tonumber(sm.match .. sm.ext)
            sm.value_type = "float"
            return true
         end
      else
         sm.value = tonumber(sm.match)
         sm.value_type = "float"
         return true
      end
   end

   sm._, sm._, sm.match = value:find("^([-+]?[%d_]+[eE][-+]?[%d_]+)$")
   if sm.match then
      if sm.match:find("_[eE]") or sm.match:find("[eE]_") then _error(sm, "Underscores in floats cannot be before or after the e. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      sm.match = remove_underscores_number(sm, sm.match, "float")
      sm.value = tonumber(sm.match)
      sm.value_type = "float"
      return true
   end
end

local max_days_in_month = { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local function validate_seconds(sm, sec, anchor)
   if sec > 60 then _error(sm, "Seconds must be less than 61. Found second: " .. sec .. " in: '" .. sm.match .. "'", anchor) end
end

local function validate_hours_minutes(sm, hour, min, anchor)
   if hour > 23 then _error(sm, "Hours must be less than 24. Found hour: " .. hour .. " in: '" .. sm.match .. "'", anchor) end
   if min > 59 then _error(sm, "Minutes must be less than 60. Found minute: " .. min .. " in: '" .. sm.match .. "'", anchor) end
end

local function validate_month_date(sm, year, month, day, anchor)
   if month == 0 or month > 12 then _error(sm, "Month must be between 01-12. Found month: " .. month .. " in: '" .. sm.match .. "'", anchor) end
   if day == 0 or day > max_days_in_month[month] then
      local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
      _error(sm, "Too many days in the month. Found " .. day .. " days in " .. months[month] .. ", which only has " .. max_days_in_month[month] .. " days in: '" .. sm.match .. "'", anchor)
   end
   if month == 2 then
      local leap_year = (year % 4 == 0) and not (year % 100 == 0) or (year % 400 == 0)
      if leap_year == false then
         if day > 28 then _error(sm, "Too many days in month. Found " .. day .. " days in February, which only has 28 days if it's not a leap year in: '" .. sm.match .. "'", anchor) end
      end
   end
end

local function assign_time_local(sm, match, hour, min, sec, msec)
   sm.value_type = "time-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ hour = hour, min = min, sec = sec, msec = msec })
   end
end

local function assign_date_local(sm, match, year, month, day)
   sm.value_type = "date-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day })
   end
end

local function assign_datetime_local(sm, match, year, month, day, hour, min, sec, msec)
   sm.value_type = "datetime-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day, hour = hour, min = min, sec = sec, msec = msec or 0 })
   end
end

local function assign_datetime(sm, match, year, month, day, hour, min, sec, msec, tz)
   if tz then
      local hour_s, min_s
      sm._, sm._, hour_s, min_s = tz:find("^[+-](%d%d):(%d%d)$")
      validate_hours_minutes(sm, _tointeger(hour_s), _tointeger(min_s), "offset-date-time")
   end
   sm.value_type = "datetime"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day, hour = hour, min = min, sec = sec, msec = msec or 0, time_offset = tz or "00:00" })
   end
end

local function validate_datetime(sm, value)
   local hour_s, min_s, sec_s, msec_s
   local hour, min, sec
   sm._, sm._, sm.match, hour_s, min_s, sm.ext = value:find("^((%d%d):(%d%d))(.*)$")
   if sm.match then
      hour, min = _tointeger(hour_s), _tointeger(min_s)
      validate_hours_minutes(sm, hour, min, "local-time")

      if sm.ext ~= "" then
         sm._, sm._, sec_s = sm.ext:find("^:(%d%d)$")
         if sec_s then
            sec = _tointeger(sec_s)
            validate_seconds(sm, sec, "local-time")
            assign_time_local(sm, sm.match .. sm.ext, hour, min, sec, 0)
            return true
         end

         sm._, sm._, sec_s, msec_s = sm.ext:find("^:(%d%d)%.(%d+)$")
         if sec_s then
            sec = _tointeger(sec_s)
            validate_seconds(sm, sec, "local-time")
            assign_time_local(sm, sm.match .. sm.ext, hour, min, sec, _tointeger(msec_s))
            return true
         end
      else
         assign_time_local(sm, sm.match .. ":00", hour, min, 0, 0)
         return true
      end
   end

   local year_s, month_s, day_s
   local year, month, day
   sm._, sm._, sm.match, year_s, month_s, day_s = value:find("^((%d%d%d%d)%-(%d%d)%-(%d%d))$")
   if sm.match then
      year, month, day = _tointeger(year_s), _tointeger(month_s), _tointeger(day_s)
      validate_month_date(sm, year, month, day, "local-date")
      assign_date_local(sm, sm.match, year, month, day)



      local potential_end_seq



      if sm.input:find("^ %d", sm.i) then
         sm._, potential_end_seq, sm.match = sm.input:find("^ ([%S]+)", sm.i)
         value = value .. " " .. sm.match
         sm.end_seq = potential_end_seq
         sm.i = sm.end_seq + 1
      else
         return true
      end
   end

   sm._, sm._, sm.match, year_s, month_s, day_s, hour_s, min_s, sm.ext =
   value:find("^((%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d))(.*)$")

   if sm.match then
      hour, min = _tointeger(hour_s), _tointeger(min_s)
      validate_hours_minutes(sm, hour, min, "local-time")
      year, month, day = _tointeger(year_s), _tointeger(month_s), _tointeger(day_s)
      validate_month_date(sm, year, month, day, "local-date-time")


      local temp_ext
      sm._, sm._, sec_s, temp_ext = sm.ext:find("^:(%d%d)(.*)$")
      if sec_s then
         sec = _tointeger(sec_s)
         validate_seconds(sm, sec, "local-time")
         sm.match = sm.match .. ":" .. sec_s
         sm.ext = temp_ext
      else
         sm.match = sm.match .. ":00"
      end


      if sm.ext ~= "" then
         sm.match = sm.match .. sm.ext
         if sm.ext:find("^%.%d+$") then
            sm._, sm._, msec_s = sm.ext:find("^%.(%d+)Z$")
            assign_datetime_local(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s))
            return true
         elseif sm.ext:find("^%.%d+Z$") then
            sm._, sm._, msec_s = sm.ext:find("^%.(%d+)Z$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s))
            return true
         elseif sm.ext:find("^%.%d+[+-]%d%d:%d%d$") then
            local tz_s
            sm._, sm._, msec_s, tz_s = sm.ext:find("^%.(%d+)([+-]%d%d:%d%d)$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s), tz_s)
            return true
         elseif sm.ext:find("^[Zz]$") then
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec)
            return true
         elseif sm.ext:find("^[+-]%d%d:%d%d$") then
            local tz_s
            sm._, sm._, tz_s = sm.ext:find("^([+-]%d%d:%d%d)$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, 0, tz_s)
            return true
         end
      else
         assign_datetime_local(sm, sm.match, year, month, day, hour, min, sec)
         return true
      end
   end
end

local validators = {
   validate_integer,
   validate_float,
   validate_datetime,
}

local exact_matches = {
   ["true"] = { true, "bool" },
   ["false"] = { false, "bool" },
   ["+inf"] = { math.huge, "float" },
   ["inf"] = { math.huge, "float" },
   ["-inf"] = { -math.huge, "float" },
   ["+nan"] = { (0 / 0), "float" },
   ["nan"] = { (0 / 0), "float" },
   ["-nan"] = { (-(0 / 0)), "float" },
}

local function close_other_value(sm)
   local successful_type
   sm._, sm.end_seq, sm.match = sm.input:find("^([^ #\r\n,%[{%]}]+)", sm.i)
   if sm.match == nil then
      _error(sm, "Key has been assigned, but value doesn't seem to exist", "keyvalue-pair")
   end
   sm.i = sm.end_seq + 1

   local value = sm.match
   local exact_value = exact_matches[value]
   if exact_value ~= nil then
      sm.value = exact_value[1]
      sm.value_type = exact_value[2]
      return
   end

   for _, validator in ipairs(validators) do
      successful_type = validator(sm, value)
      if successful_type == true then
         return
      end
   end

   _error(sm, "Unable to determine type of value for: '" .. value .. "'", "keyvalue-pair")
end

local function create_array(sm)
   sm.nested_arrays = sm.nested_arrays + 1
   if sm.nested_arrays >= sm.options.max_nesting_depth then
      _error(sm, "Maximum nesting depth has exceeded " .. sm.options.max_nesting_depth .. ". If this larger nesting depth is required, feel free to set 'max_nesting_depth' in the parser options.")
   end
   sm.arrays[sm.nested_arrays] = {}
   sm.i = sm.i + 1
end

local function add_array_comma(sm)
   table.insert(sm.arrays[sm.nested_arrays], sm.value)
   sm.value = nil

   sm.i = sm.i + 1
end

local function close_array(sm)

   if sm.value ~= nil then
      add_array_comma(sm)
   else
      sm.i = sm.i + 1
   end
   sm.value = sm.arrays[sm.nested_arrays]
   sm.value_type = "array"
   sm.nested_arrays = sm.nested_arrays - 1
   if sm.nested_arrays == 0 then
      return "assign"
   else
      return "inside_array"
   end
end

local function create_table(sm)
   sm.tables = {}
   sm.byte = sbyte(sm.input, sm.i + 1)

   if sm.byte == chars.OPEN_BRACKET then
      sm.i = sm.i + 2
      sm.table_type = "arrays_of_tables"
   else
      sm.i = sm.i + 1
      sm.table_type = "table"
   end
end

local function add_table_dot(sm)
   sm.tables[#sm.tables + 1] = sm.value
   sm.i = sm.i + 1
end

local function close_table(sm)
   sm.byte = sbyte(sm.input, sm.i + 1)

   if sm.table_type == "arrays_of_tables" and sm.byte ~= chars.CLOSE_BRACKET then
      _error(sm, "Arrays of Tables should be closed with ']]'", "array-of-tables")
   end

   if sm.byte == chars.CLOSE_BRACKET then
      sm.i = sm.i + 2
   else
      sm.i = sm.i + 1
   end

   sm.tables[#sm.tables + 1] = sm.value

   local out_table = sm.output
   local meta_out_table = sm.meta_table

   for i = 1, #sm.tables - 1 do
      if out_table[sm.tables[i]] == nil then

         out_table[sm.tables[i]] = {}
         out_table = out_table[sm.tables[i]]

         meta_out_table[sm.tables[i]] = { type = "auto-dictionary" }
         meta_out_table = meta_out_table[sm.tables[i]]
      else
         if (meta_out_table[sm.tables[i]]).type == "value" then
            _error(sm, "Cannot override previously definied value '" .. sm.tables[i] .. "' with new table definition: '" .. table.concat(sm.tables, ".") .. "'")
         end

         local next_table = out_table[sm.tables[i]][#out_table[sm.tables[i]]]
         local next_meta_table = meta_out_table[sm.tables[i]][#meta_out_table[sm.tables[i]]]

         if next_table == nil then
            out_table = out_table[sm.tables[i]]
            meta_out_table = meta_out_table[sm.tables[i]]
         else
            out_table = next_table
            meta_out_table = next_meta_table
         end
      end
   end
   local final_table = sm.tables[#sm.tables]

   if sm.table_type == "table" then
      if out_table[final_table] == nil then
         out_table[final_table] = {}
         meta_out_table[final_table] = { type = "dictionary" }
      elseif (meta_out_table[final_table]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "array" then
         _error(sm, "Cannot override existing array '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "value-dictionary" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      end
      (meta_out_table[final_table]).type = "dictionary"
      sm.current_table = out_table[final_table]
      sm.current_meta_table = meta_out_table[final_table]

   elseif sm.table_type == "arrays_of_tables" then
      if out_table[final_table] == nil then
         out_table[final_table] = {}
         meta_out_table[final_table] = { type = "array" }
      elseif (meta_out_table[final_table]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "auto-dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "value-dictionary" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      end
      table.insert(out_table[final_table], {})
      table.insert(meta_out_table[final_table], { type = "dictionary" })
      sm.current_table = out_table[final_table][#out_table[final_table]]
      sm.current_meta_table = meta_out_table[final_table][#meta_out_table[final_table]]
   end

end

local function assign_key(sm)
   if sm.multiline_string == false then
      sm.keys[#sm.keys + 1] = sm.value
   else
      _error(sm, "Cannot have multi-line string as keys. Found key: '" .. tostring(sm.value) .. "'", "keys")
   end


   sm.value = nil
   sm.value_type = nil

   sm.i = sm.i + 1
end

local function assign_value(sm)
   local output = {}
   output = sm.value


   local out_table = sm.current_table
   local meta_out_table = sm.current_meta_table
   for i = 1, #sm.keys - 1 do
      if out_table[sm.keys[i]] == nil then
         out_table[sm.keys[i]] = {}
         meta_out_table[sm.keys[i]] = { type = "value-dictionary" }
      elseif (meta_out_table[sm.keys[i]]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      elseif (meta_out_table[sm.keys[i]]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      elseif (meta_out_table[sm.keys[i]]).type == "array" then
         _error(sm, "Cannot override existing array '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      end
      out_table = out_table[sm.keys[i]]
      meta_out_table = meta_out_table[sm.keys[i]]
   end


   local last_table = sm.keys[#sm.keys]

   if out_table[last_table] ~= nil then
      _error(sm, "Cannot override previously defined key '" .. sm.keys[#sm.keys] .. "'")
   end

   out_table[last_table] = output
   meta_out_table[last_table] = { type = "value" }

   sm.keys = {}
   sm.value = nil
end

local function error_invalid_state(sm)
   local error_message = "Incorrectly formatted TOML. "
   local found = sm.input:sub(sm.i, sm.i); if found == "\r" or found == "\n" then found = "newline character" end
   if sm.mode == "start_of_line" then error_message = error_message .. "At start of line, could not find a key. Found '='"
   elseif sm.mode == "inside_table" then error_message = error_message .. "In a table definition, expected a '.' or ']'. Found: '" .. found .. "'"
   elseif sm.mode == "inside_key" then error_message = error_message .. "In a key defintion, expected a '.' or '='. Found: '" .. found .. "'"
   elseif sm.mode == "value" then error_message = error_message .. "Unspecified value, key was specified, but no value provided."
   elseif sm.mode == "inside_array" then error_message = error_message .. "Inside an array, expected a ']', '}' (if inside inline table), ',', newline, or comment. Found: " .. found
   elseif sm.mode == "wait_for_newline" then error_message = error_message .. "Just assigned value or created table. Expected newline or comment before continuing."
   end
   _error(sm, error_message)
end

local function create_inline_table(sm)
   sm.nested_inline_tables = sm.nested_inline_tables + 1

   if sm.nested_inline_tables >= sm.options.max_nesting_depth then
      _error(sm, "Maximum nesting depth has exceeded " .. sm.options.max_nesting_depth .. ". If this larger nesting depth is required, feel free to set 'max_nesting_depth' in the parser options.")
   end

   local backup = {
      previous_state = sm.mode,
      meta_table = sm.meta_table,
      current_table = sm.current_table,
      keys = { _unpack(sm.keys) },
   }

   local new_inline_table = {}
   sm.current_table = new_inline_table

   sm.inline_table_backup[sm.nested_inline_tables] = backup

   sm.current_table = {}
   sm.meta_table = {}
   sm.keys = {}

   sm.i = sm.i + 1
end

local function close_inline_table(sm)
   if sm.value ~= nil then
      assign_value(sm)
   end
   sm.i = sm.i + 1
   sm.value = sm.current_table
   sm.value_type = "inline-table"

   local restore = sm.inline_table_backup[sm.nested_inline_tables]
   sm.keys = restore.keys
   sm.meta_table = restore.meta_table
   sm.current_table = restore.current_table

   sm.nested_inline_tables = sm.nested_inline_tables - 1

   if restore.previous_state == "array" then
      return "inside_array"
   elseif restore.previous_state == "value" then
      return "assign"
   else
      _error(sm, "close_inline_table should not be called from the previous state: " .. restore.previous_state .. ". Please submit an issue with your TOML file so we can look into the issue!")
   end
end

local function skip_comma(sm)
   sm.i = sm.i + 1
end

local transitions = {
   ["start_of_line"] = {
      [sbyte("#")] = { find_newline, "start_of_line" },
      [sbyte("\r")] = { find_newline, "start_of_line" },
      [sbyte("\n")] = { find_newline, "start_of_line" },
      [sbyte('"')] = { close_string, "inside_key" },
      [sbyte("'")] = { close_literal_string, "inside_key" },
      [sbyte("[")] = { create_table, "table" },
      [sbyte("=")] = { error_invalid_state, "error" },
      [sbyte("}")] = { close_inline_table, "?" },
      [0] = { close_bare_string, "inside_key" },
   },
   ["table"] = {
      [sbyte('"')] = { close_string, "inside_table" },
      [sbyte("'")] = { close_literal_string, "inside_table" },
      [0] = { close_bare_string, "inside_table" },
   },
   ["inside_table"] = {
      [sbyte(".")] = { add_table_dot, "table" },
      [sbyte("]")] = { close_table, "wait_for_newline" },
      [0] = { error_invalid_state, "error" },
   },
   ["key"] = {
      [sbyte('"')] = { close_string, "inside_key" },
      [sbyte("'")] = { close_literal_string, "inside_key" },
      [sbyte("}")] = { close_inline_table, "?" },
      [sbyte("\r")] = { find_newline, "key" },
      [sbyte("\n")] = { find_newline, "key" },
      [sbyte("#")] = { find_newline, "key" },
      [0] = { close_bare_string, "inside_key" },
   },
   ["inside_key"] = {
      [sbyte(".")] = { assign_key, "key" },
      [sbyte("=")] = { assign_key, "value" },
      [0] = { error_invalid_state, "error" },
   },
   ["value"] = {
      [sbyte("'")] = { close_literal_string, "assign" },
      [sbyte('"')] = { close_string, "assign" },
      [sbyte("{")] = { create_inline_table, "key" },
      [sbyte("[")] = { create_array, "array" },
      [sbyte("\n")] = { error_invalid_state, "error" },
      [sbyte("\r")] = { error_invalid_state, "error" },
      [0] = { close_other_value, "assign" },
   },
   ["array"] = {
      [sbyte("'")] = { close_literal_string, "inside_array" },
      [sbyte('"')] = { close_string, "inside_array" },
      [sbyte("[")] = { create_array, "array" },
      [sbyte("]")] = { close_array, "?" },
      [sbyte("#")] = { find_newline, "array" },
      [sbyte("\r")] = { find_newline, "array" },
      [sbyte("\n")] = { find_newline, "array" },
      [sbyte("{")] = { create_inline_table, "key" },
      [0] = { close_other_value, "inside_array" },
   },
   ["inside_array"] = {
      [sbyte(",")] = { add_array_comma, "array" },
      [sbyte("]")] = { close_array, "?" },
      [sbyte("}")] = { close_inline_table, "?" },
      [sbyte("#")] = { find_newline, "inside_array" },
      [sbyte("\r")] = { find_newline, "inside_array" },
      [sbyte("\n")] = { find_newline, "inside_array" },
      [0] = { error_invalid_state, "error" },
   },
   ["assign"] = {
      [sbyte(",")] = { assign_value, "wait_for_key" },
      [sbyte("}")] = { close_inline_table, "?" },
      [0] = { assign_value, "wait_for_newline" },
   },
   ["wait_for_key"] = {
      [sbyte(",")] = { skip_comma, "key" },
   },
   ["wait_for_newline"] = {
      [sbyte("#")] = { find_newline, "start_of_line" },
      [sbyte("\r")] = { find_newline, "start_of_line" },
      [sbyte("\n")] = { find_newline, "start_of_line" },
      [0] = { error_invalid_state, "error" },
   },
}

local function generic_type_conversion(raw_value) return raw_value end

function tinytoml.parse(filename, options)
   local sm = {}

   local default_options = {
      max_nesting_depth = 1000,
      max_filesize = 100000000,
      load_from_string = false,
      parse_datetime_as = "string",
      type_conversion = {
         ["datetime"] = generic_type_conversion,
         ["datetime-local"] = generic_type_conversion,
         ["date-local"] = generic_type_conversion,
         ["time-local"] = generic_type_conversion,
      },
   }

   if options then

      if options.max_nesting_depth ~= nil then
         assert(type(options.max_nesting_depth) == "number", "the tinytoml option 'max_nesting_depth' takes in a 'number'. You passed in the value '" .. tostring(options.max_nesting_depth) .. "' of type '" .. type(options.max_nesting_depth) .. "'")
      end

      if options.max_filesize ~= nil then
         assert(type(options.max_filesize) == "number", "the tinytoml option 'max_filesize' takes in a 'number'. You passed in the value '" .. tostring(options.max_filesize) .. "' of type '" .. type(options.max_filesize) .. "'")
      end

      if options.load_from_string ~= nil then
         assert(type(options.load_from_string) == "boolean", "the tinytoml option 'load_from_string' takes in a 'function'. You passed in the value '" .. tostring(options.load_from_string) .. "' of type '" .. type(options.load_from_string) .. "'")
      end

      if options.parse_datetime_as ~= nil then
         assert(type(options.parse_datetime_as) == "string", "the tinytoml option 'parse_datetime_as' takes in either the 'string' or 'table' (as type 'string'). You passed in the value '" .. tostring(options.parse_datetime_as) .. "' of type '" .. type(options.parse_datetime_as) .. "'")
      end

      if options.type_conversion ~= nil then
         assert(type(options.type_conversion) == "table", "the tinytoml option 'type_conversion' takes in a 'table'. You passed in the value '" .. tostring(options.type_conversion) .. "' of type '" .. type(options.type_conversion) .. "'")
         for key, value in pairs(options.type_conversion) do
            assert(type(key) == "string")
            if not default_options.type_conversion[key] then
               error("")
            end
            assert(type(value) == "function")
         end
      end


      options.max_nesting_depth = options.max_nesting_depth or default_options.max_nesting_depth
      options.max_filesize = options.max_filesize or default_options.max_filesize
      options.load_from_string = options.load_from_string or default_options.load_from_string
      options.parse_datetime_as = options.parse_datetime_as or default_options.parse_datetime_as
      options.type_conversion = options.type_conversion or default_options.type_conversion


      if options.load_from_string == true then
         sm.input = filename
         sm.filename = "string input"
      end


      for key, value in pairs(default_options.type_conversion) do
         if options.type_conversion[key] == nil then
            options.type_conversion[key] = value
         end
      end

   else
      options = default_options
   end


   sm.options = options

   if options.load_from_string == false then
      local file = io.open(filename, "r")
      if not file then error("Unable to open file: '" .. filename .. "'") end
      if file:seek("end") > options.max_filesize then error("Filesize is larger than 100MB. If this is intentional, please set the 'max_filesize' (in bytes) in options") end
      file:seek("set")
      sm.input = file:read("*all")
      file:close()
      sm.filename = filename
   end

   sm.i = 1
   sm.keys = {}
   sm.arrays = {}
   sm.output = {}
   sm.meta_table = {}
   sm.line_number = 1
   sm.line_number_char_index = 1
   sm.nested_arrays = 0
   sm.inline_table_backup = {}
   sm.nested_inline_tables = 0
   sm.table_type = "table"
   sm.input_length = #sm.input
   sm.current_table = sm.output
   sm.current_meta_table = sm.meta_table


   if sm.input_length == 0 then return {} end

   local valid, line_number, line_number_start, message = validate_utf8(sm.input, true)
   if not valid then
      sm.line_number = line_number
      sm.line_number_char_index = line_number_start
      _error(sm, message, "preliminaries")
   end

   sm.mode = "start_of_line"
   local dynamic_next_mode = "start_of_line"
   local transition = nil
   sm._, sm.i = sm.input:find("[^ \t]", sm.i)


   if not sm.i then return {} end

   while sm.i <= sm.input_length do
      sm.byte = sbyte(sm.input, sm.i)

      transition = transitions[sm.mode][sm.byte]
      if transition == nil then
         transition = transitions[sm.mode][0]
      end

      if transition[2] == "?" then
         dynamic_next_mode = transition[1](sm)
         sm.mode = dynamic_next_mode
      else
         transition[1](sm)
         sm.mode = transition[2]
      end

      sm._, sm.i = sm.input:find("[^ \t]", sm.i)
      if sm.i == nil then
         break
      end
   end

   if sm.mode == "assign" then

      sm.i = sm.input_length
      assign_value(sm)
   end
   if sm.mode == "inside_array" or sm.mode == "array" then
      _error(sm, "Unable to find closing bracket of array", "array")
   end
   if sm.mode == "key" then
      _error(sm, "Incorrect formatting for key", "keys")
   end
   if sm.mode == "value" then
      _error(sm, "Key has been assigned, but value doesn't seem to exist", "keyvalue-pair")
   end
   if sm.nested_inline_tables ~= 0 then
      _error(sm, "Unable to find closing bracket of inline table", "inline-table")
   end

   return sm.output
end







local function is_array(input_table)
   local count = #(input_table)
   return count > 0 and next(input_table, count) == nil
end

local short_sequences = {
   [sbyte('\b')] = '\\b',
   [sbyte('\t')] = '\\t',
   [sbyte('\n')] = '\\n',
   [sbyte('\f')] = '\\f',
   [sbyte('\r')] = '\\r',
   [sbyte('\t')] = '\\t',
   [sbyte('\\')] = '\\\\',
   [sbyte('"')] = '\\"',
}

local function escape_string(str, multiline, is_key)


   if not is_key and #str >= 5 and str:find("%d%d") then




      local sm = { input = str, i = 1, line_number = 1, line_number_char_index = 1 }
      sm.options = {}
      sm.options.type_conversion = {
         ["datetime"] = generic_type_conversion,
         ["datetime-local"] = generic_type_conversion,
         ["date-local"] = generic_type_conversion,
         ["time-local"] = generic_type_conversion,
      }
      sm.options.parse_datetime_as = "string"


      sm._, sm.end_seq, sm.match = sm.input:find("^([^ #\r\n,%[{%]}]+)", sm.i)
      sm.i = sm.end_seq + 1

      if validate_datetime(sm, sm.match) then
         if sm.value_type == "datetime" or sm.value_type == "datetime-local" or
            sm.value_type == "date-local" or sm.value_type == "time-local" then
            return sm.value
         end
      end
   end

   local byte
   local found_newline = false
   local final_string = string.gsub(str, '[%z\001-\031\127\\"]', function(c)
      byte = sbyte(c)
      if short_sequences[byte] then
         if multiline and (byte == chars.CR or byte == chars.LF) then
            found_newline = true
            return c
         else
            return short_sequences[byte]
         end
      else
         return string.format("\\x%02x", byte)
      end
   end)
   if found_newline then
      final_string = '"""' .. final_string .. '"""'
   else
      final_string = '"' .. final_string .. '"'
   end

   if not validate_utf8(final_string, true) then
      error("String is not valid UTF-8, cannot encode to TOML")
   end
   return final_string

end

local function escape_key(str)
   if str:find("^[A-Za-z0-9_-]+$") then
      return str
   else
      return escape_string(str, false, true)
   end
end

local to_inf_and_beyound = {
   ["inf"] = true,
   ["-inf"] = true,
   ["nan"] = true,
   ["-nan"] = true,
}


local function float_to_string(x)


   if to_inf_and_beyound[tostring(x)] then
      return tostring(x)
   end
   for precision = 15, 17 do

      local s = ('%%.%dg'):format(precision):format(x)

      if tonumber(s) == x then
         return s
      end
   end

   return tostring(x)
end

local function encode_element(element, allow_multiline_strings)
   if type(element) == "table" then
      local encoded_string = {}
      if is_array(element) then
         table.insert(encoded_string, "[")

         local remove_trailing_comma = false
         for _, array_element in ipairs(element) do
            remove_trailing_comma = true
            table.insert(encoded_string, encode_element(array_element, allow_multiline_strings))
            table.insert(encoded_string, ", ")
         end
         if remove_trailing_comma then table.remove(encoded_string) end

         table.insert(encoded_string, "]")

         return table.concat(encoded_string)

      else
         table.insert(encoded_string, "{")

         local remove_trailing_comma = false
         for k, v in F.pairs(element) do
            remove_trailing_comma = true
            table.insert(encoded_string, k)
            table.insert(encoded_string, " = ")
            table.insert(encoded_string, encode_element(v, allow_multiline_strings))
            table.insert(encoded_string, ", ")
         end
         if remove_trailing_comma then table.remove(encoded_string) end

         table.insert(encoded_string, "}")

         return table.concat(encoded_string)

      end

   elseif type(element) == "string" then
      return escape_string(element, allow_multiline_strings, false)

   elseif type(element) == "number" then
      return float_to_string(element)

   elseif type(element) == "boolean" then
      return tostring(element)

   else
      error("Unable to encode type '" .. type(element) .. "' into a TOML type")
   end
end

local function encode_depth(encoded_string, depth)
   table.insert(encoded_string, '\n[')
   table.insert(encoded_string, table.concat(depth, '.'))
   table.insert(encoded_string, ']\n')
end

local function encoder(input_table, encoded_string, depth, options)
   local printed_table_info = false
   for k, v in F.pairs(input_table) do
      if type(v) ~= "table" or (type(v) == "table" and is_array(v)) then
         if not printed_table_info and #depth > 0 then
            encode_depth(encoded_string, depth)
            printed_table_info = true
         end
         table.insert(encoded_string, escape_key(k))
         table.insert(encoded_string, " = ")
         local status, error_or_encoded_element = pcall(encode_element, v, options.allow_multiline_strings)
         if not status then
            local error_message = { "\n\nWhile encoding '" }
            local _
            if #depth > 0 then
               error_message[#error_message + 1] = table.concat(depth, ".")
               error_message[#error_message + 1] = "."
            end
            error_message[#error_message + 1] = escape_key(k)
            error_message[#error_message + 1] = "', received the following error message:\n\n"
            _, _, error_or_encoded_element = error_or_encoded_element:find(".-:.-: (.*)")
            error_message[#error_message + 1] = error_or_encoded_element
            error(table.concat(error_message))
         end
         table.insert(encoded_string, error_or_encoded_element)
         table.insert(encoded_string, "\n")
      end
   end
   for k, v in F.pairs(input_table) do
      if type(v) == "table" and not is_array(v) then
         if next(v) == nil then
            table.insert(depth, escape_key(k))
            encode_depth(encoded_string, depth)
            table.remove(depth)


         else
            table.insert(depth, escape_key(k))
            encoder(v, encoded_string, depth, options)
            table.remove(depth)
         end
      end
   end
   return encoded_string
end

function tinytoml.encode(input_table, options)
   options = options or {
      allow_multiline_strings = false,
   }
   return table.concat(encoder(input_table, {}, {}, options))
end

return tinytoml
]=])
package.preload["tomlx"] = lib("luax/tomlx.lua", [=[--[[
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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

--[[------------------------------------------------------------------------@@@
# tomlx

`tomlx` is a layer on top of `toml` ([tinytoml](https://github.com/FourierTransformer/tinytoml)).

It uses Lua as a macro language to transform values.
Macros are string values starting with `=`.
The expression following `=` is a Lua expression which value replaces the macro in the table.

The evaluation environment contains two specific symbols:

- `__up`: environment one level above the current level
- `__root`: root level of the environment levels

```lua
local tomlx = require "tomlx"
```
@@@]]

local tomlx = {}

local F = require "F"
local fs = require "fs"
local toml = require "toml"

local function pattern(options)
    return options and options.pattern or "^=%s*(.-)%s*$"
end

local function chain(env1, env2)
    return setmetatable({}, {
        __index = function(_, k)
            local v = env2[k]
            if v ~= nil then return v end
            return env1 and env1[k]
        end
    })
end

local function chain_and_uplink(env1, env2)
    local env = chain(env1, env2)
    env.__up = env1
    return env
end

--[[@@@
The default environment contains the global variables (`_G`)
and some LuaX modules (`crypt`, `F`, `fs`, `sh`).
@@@]]

local default_env = chain({
    crypt = require "crypt",
    F = require "F",
    fs = require "fs",
    sh = require "sh",
}, _G)

local function root_env(t, options)
    local root = chain(default_env, {__root=t})
    local env = options and options.env
    if env then return chain(root, env) end
    return root
end

local function join(path, k)
    if type(k) == "number" then return path.."["..k.."]" end
    if path then return path.."."..k end
    return k
end

local function process(t, env, pat, path)
    local t2 = {}
    env = chain_and_uplink(env, t)
    for k, v in pairs(t) do
        if type(v) == "table" then
            local path2 = join(path, k)
            rawset(t2, k, process(v, env, pat, path2))
        elseif type(v) == "string" then
            local expr = v:match(pat)
            if expr then
                local path2 = join(path, k)
                rawset(t2, k, assert(load("return "..expr, "@"..path2..": "..expr, "t", env))())
            else
                rawset(t2, k, v)
            end
        else
            rawset(t2, k, v)
        end
    end
    return t2
end

local function input_options(options, load_from_string)
    return F.patch(options or {}, {load_from_string=load_from_string})
end

--[[@@@
```lua
tomlx.read(filename, [options])
```
> calls `toml.parse` to parse a TOML file.
> Options are optional
> and described in the [tinytoml documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#parsing-toml).
> tomlx adds the env option (`options.env`) to define the initial evaluation environment.
> The table returned by `tinytoml` is then processed to evaluate `tomlx` macros.
@@@]]
function tomlx.read(filename, options)
    local t = toml.parse(filename, input_options(options, false))
    return process(t, root_env(t, options), pattern(options))
end

--[[@@@
```lua
tomlx.decode(s, [options])
```
> calls `toml.parse` to parse a TOML string.
> Options are optional
> and described in the [tinytoml documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#parsing-toml).
> tomlx adds the env option (`options.env`) to define the initial evaluation environment.
> The table returned by `tinytoml` is then processed to evaluate `tomlx` macros.
@@@]]
function tomlx.decode(s, options)
    local t = toml.parse(s, input_options(options, true))
    return process(t, root_env(t, options), pattern(options))
end

--[[@@@
```lua
tomlx.encode(s, [options])
```
> calls `toml.encode` to encode a Lua table into a TOML string.
> Options are optional
> and described in the [tinytoml documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#encoding-toml).
@@@]]
function tomlx.encode(t, options)
    return toml.encode(t, options)
end

--[[@@@
```lua
tomlx.write(filename, t, [options])
```
> calls `toml.encode` to encode a Lua table into a TOML string
> and save it the file `filename`.
> Options are optional
> and described in the [tinytoml documentation](https://github.com/FourierTransformer/tinytoml?tab=readme-ov-file#encoding-toml).
@@@]]
function tomlx.write(filename, t, options)
    fs.write(filename, toml.encode(t, options))
end

--[[@@@
```lua
tomlx.validate(schema, filename, [options])
```
> returns `true` if `filename` is validated by `schema`. Otherwise it returns `false`
> and a list of failures.
>
> The `schema` file is a TOML file used to validate the TOML file `filename`.
> Both files are read with `tomlx.read` and the corresponding tables are validated with `F.validate`.
>
> Options (the `option` table) contains options for `tomlx.read` and `F.validate`.
@@@]]
function tomlx.validate(schema, filename, options)
    return F.validate(tomlx.read(schema, options), tomlx.read(filename, options), options)
end

return tomlx
]=])
package.preload["C"] = lib("bang/C.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sys = require "sys"

local flatten = require "flatten"
local tmp = require "tmp"

local default_options = {
    builddir = "$builddir/tmp",
    cc = "cc", cflags = {"-c", "-MMD -MF $depfile"}, cargs = "$in -o $out",
    depfile = "$out.d",
    cvalid = {},
    ar = "ar", aflags = "-crs", aargs = "$out $in",
    so = "cc", soflags = "-shared", soargs = "-o $out $in", solibs = {},
    ld = "cc", ldflags = {}, ldargs = "-o $out $in", ldlibs = {},
    c_exts = { ".c" },
    o_ext = ".o",
    a_ext = ".a",
    so_ext = sys.so,
    exe_ext = sys.exe,
    implicit_in = Nil,
}

local function set_ext(name, ext)
    if (vars%name):has_suffix(ext) then return name end
    return name..ext
end

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local rules = setmetatable({}, {
    __index = function(self, compiler)
        local cc = F{compiler.name, "cc"}:flatten():str"-"
        local ar = F{compiler.name, "ar"}:flatten():str"-"
        local so = F{compiler.name, "so"}:flatten():str"-"
        local ld = F{compiler.name, "ld"}:flatten():str"-"
        local new_rules = {
            cc = rule(cc) {
                description = {compiler.cc, "$out"},
                command = { compiler.cc, compiler.cflags, compiler.cargs },
                depfile = compiler.depfile,
                implicit_in = compiler.implicit_in,
            },
            ar = rule(ar) {
                description = {compiler.ar, "$out"},
                command = { compiler.ar, compiler.aflags, compiler.aargs },
                implicit_in = compiler.implicit_in,
            },
            so = rule(so) {
                description = {compiler.so, "$out"},
                command = { compiler.so, compiler.soflags, compiler.soargs, compiler.solibs },
                implicit_in = compiler.implicit_in,
            },
            ld = rule(ld) {
                description = {compiler.ld, "$out"},
                command = { compiler.ld, compiler.ldflags, compiler.ldargs, compiler.ldlibs },
                implicit_in = compiler.implicit_in,
            },
        }
        rawset(self, compiler, new_rules)
        return new_rules
    end
})

local function compile(self, output)
    local cc = rules[self].cc
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.o_ext)
        local validations = F.flatten{self.cvalid}:map(function(valid)
            local valid_output = output.."-"..(valid.name or valid)..".check"
            if valid.name then
                return valid(valid_output) { inputs }
            else
                return build(valid_output) { valid, inputs }
            end
        end)
        return build(output) (F.merge{
            { cc, input_list },
            input_vars,
            { validations = validations },
        })
    end
end

local function static_lib(self, output)
    local ar = rules[self].ar
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.a_ext)
        return build(output) { ar,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local function dynamic_lib(self, output)
    local so = rules[self].so
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.so_ext)
        return build(output) { so,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local function executable(self, output)
    local ld = rules[self].ld
    return function(inputs)
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.exe_ext)
        return build(output) { ld,
            F.flatten(input_list):map(function(input)
                if F.elem(input:ext(), self.c_exts) then
                    return self:compile(tmp(self.builddir, output, input)..self.o_ext) (F.merge{
                        { input },
                        input_vars,
                    })
                else
                    return input
                end
            end)
        }
    end
end

local compiler_mt

local compilers = {}

local function new(compiler, name)
    if compilers[name] then
        error(name..": compiler redefinition")
    end
    local self = F.merge { compiler, {name=name} }
    compilers[name] = self
    return setmetatable(self, compiler_mt)
end

local function check_opt(name)
    assert(default_options[name], name..": Unknown compiler option")
end

compiler_mt = {
    __call = executable,

    __index = {
        new = new,

        compile = compile,
        static_lib = static_lib,
        dynamic_lib = dynamic_lib,
        executable = executable,

        set = function(self, name)
            check_opt(name)
            return function(value) self[name] = value; return self end
        end,
        add = function(self, name)
            check_opt(name)
            return function(value) self[name] = {self[name], value}; return self end
        end,
        insert = function(self, name)
            check_opt(name)
            return function(value) self[name] = {value, self[name]}; return self end
        end,
    },
}

local cc      = new(default_options, "C")
local gcc     = cc  : new "gcc"     : set "cc" "gcc"     : set "so" "gcc"     : set "ld" "gcc"
local clang   = cc  : new "clang"   : set "cc" "clang"   : set "so" "clang"   : set "ld" "clang"
local cpp     = cc  : new "Cpp"     : set "cc" "c++"     : set "so" "c++"     : set "ld" "c++"     : set "c_exts" { ".cc", ".cpp" }
local gpp     = cpp : new "gpp"     : set "cc" "g++"     : set "so" "g++"     : set "ld" "g++"
local clangpp = cpp : new "clangpp" : set "cc" "clang++" : set "so" "clang++" : set "ld" "clang++"

local zigcc   = cc  : new "zigcc"   : set "cc" "zig cc"  : set "ar" "zig ar" : set "so" "zig cc"  : set "ld" "zig cc"
local zigcpp  = cpp : new "zigcpp"  : set "cc" "zig c++" : set "ar" "zig ar" : set "so" "zig c++" : set "ld" "zig c++"
require "luax-targets" : foreach(function(target)
    local zig_target = {"-target", F{target.arch, target.os, target.libc}:str"-"}
    local function add_target(compiler)
        return compiler : add "cc" (zig_target) : add "so" (zig_target) : add "ld" (zig_target) : set "so_ext" (target.so) : set "exe_ext" (target.exe)
    end
    zigcc[target.name]  = add_target(zigcc  : new("zigcc-"..target.name))
    zigcpp[target.name] = add_target(zigcpp : new("zigcpp-"..target.name))
end)

local compile_flags_file = nil

local function compile_flags(flags)
    if not compile_flags_file then
        compile_flags_file = file(bang.output:dirname()/"compile_flags.txt")
    end
    local flag_list = type(flags) == "string" and {flags} or flatten(flags)
    compile_flags_file((vars%flag_list) : unlines())
    return flags
end

return setmetatable({
    cc  = cc,  gcc = gcc, clang   = clang,   zigcc  = zigcc,
    cpp = cpp, gpp = gpp, clangpp = clangpp, zigcpp = zigcpp,
    compile_flags = compile_flags,
}, {
    __call = function(_, ...) return cc(...) end,
    __index = {
        new = function(_, name) return cc:new(name) end,
    },
})
]])
package.preload["acc"] = lib("bang/acc.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local function acc(list)
    return function(xs)
        list[#list+1] = xs
    end
end

return acc
]])
package.preload["archivers"] = lib("bang/archivers.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local fs = require "fs"
local log = require "log"
local sys = require "sys"

local function tar_rule()
    rule "tar" {
        description = "tar $out",
        command = {
            "tar -caf $out -C $base $name $transform",
            case(sys.os) {
                linux   = "--sort=name",
                macos   = {},
                windows = {},
            },
        },
    }
    tar_rule = F.const() -- generate the tar rule once
end

local function get_first_level(base, files)
    return files : map(function(file)
        if not file:has_prefix(base) then return end
        return file
            : sub(#base+1)                                  -- remove the base dir
            : splitpath()                                   -- split path components
            : drop_while(function(p) return p==fs.sep end)  -- ignore empty path components
            : head()                                        -- keep the first one
    end) : nub()
end

local function in_dir(dir)
    local dirs = dir:splitpath()
    return function(file)
        return F.op.ueq(file:splitpath():take(#dirs), dirs)
    end
end

local function tar(output)
    tar_rule()
    return function(inputs)
        local base = inputs.base
        local name = inputs.name
        local transform = nil
        if inputs.transform then
            transform = F.flatten{inputs.transform} : map(function(expr)
                return { "--transform", string.format("%q", expr) }
            end)
        end
        if base and name then
            local files = build.files(in_dir(base/name))
            return build(output) { "tar",
                base = base,
                name = name,
                transform = transform,
                implicit_in = files,
            }
        end
        if base then
            local files = build.files(in_dir(base))
            return build(output) { "tar",
                base = base,
                name = get_first_level(base, files),
                transform = transform,
                implicit_in = files,
            }
        end
        log.error(output..": base directory not specified")
    end
end

return {
    tar = tar,
}
]])
package.preload["atexit"] = lib("bang/atexit.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

local registered_functions = F{}

return setmetatable({}, {
    __call = function(_, f)
        if type(f) ~= "function" then error(tostring(f).." is not a function", 2) end
        registered_functions[#registered_functions+1] = f
    end,
    __index = {
        run = function()
            while not registered_functions:null() do
                local funcs = registered_functions
                registered_functions = F{}
                funcs:foreach(F.call)
            end
        end,
    },
})
]])
package.preload["builders"] = lib("bang/builders.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local fs = require "fs"
local sys = require "sys"

local default_options = {
    cmd = "cat",
    flags = {},
    args = "$in > $out",
    ext = "",
}

local builder_keys = F.keys(default_options) .. { "name", "output_prefix" }

local function set_ext(name, ext)
    if (vars%name):lower():has_suffix(ext:lower()) then return name end
    return name..ext
end

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local rules = setmetatable({}, {
    __index = function(self, builder)
        local new_rule = rule(builder.name) (F.merge{
            {
                description = builder.description or {builder.name, "$out"},
                command = { builder.cmd, builder.flags, builder.args },
            },
            F.without_keys(builder, builder_keys),
        })
        self[builder] = new_rule
        return new_rule
    end
})

local function gen_rule(self)
    return rules[self]
end

local function run(self, output)
    return function(inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.ext)
        return build(output) (F.merge{
            { rules[self], input_list },
            self.output_prefix and { output_prefix = output:splitext() } or {},
            input_vars,
        })
    end
end

local builder_mt

local builder_definitions = {}

local function new(builder, name)
    if builder_definitions[name] then
        error(name..": document builder redefinition")
    end
    local self = F.merge { builder, {name=name} }
    builder_definitions[name] = self
    return setmetatable(self, builder_mt)
end

builder_mt = {
    __call = run,

    __index = {
        new = new,

        rule = gen_rule,
        build = run,

        set = function(self, name)
            return function(value) self[name] = value; return self end
        end,
        add = function(self, name)
            return function(value) self[name] = self[name]==nil and value or {self[name], value}; return self end
        end,
        insert = function(self, name)
            return function(value) self[name] = self[name]==nil and value or {value, self[name]}; return self end
        end,
    },
}

local cat = new(default_options, "cat")
local cp = new(default_options, "cp")
    : set "cmd" "cp"
    : set "flags" (sys.os=="linux" and "-d --preserve=mode" or {})
    : set "args" "$in $out"

local ypp = new(default_options, "ypp")
    : set "cmd" "ypp"
    : set "args" "$in -o $out"
    : set "flags" "--MF $depfile"
    : set "depfile" "$out.d"

local function ypp_var(name)
    return function(val)
        return ("-e '%s=(%q):read()'"):format(name, F.show(val))
    end
end

local function ypp_vars(t)
    return F.mapk2a(function(k, v) return ("-e '%s=%q'"):format(k, v) end, t)
end

local pandoc = new(default_options, "pandoc")
    : set "cmd" "pandoc"
    : set "args" "$in -o $out"
    : set "flags" {
        "--fail-if-warnings",
    }

local panda = pandoc:new "panda"
    : set "cmd" "panda"
    : add "flags" {
        "-Vpanda_target=$out",
        "-Vpanda_dep_file=$depfile",
    }
    : set "depfile" "$out.d"

local typst = new(default_options, "typst")
    : set "cmd" "typst"
    : set "args" "$in $out"
    : set "flags" "compile"

if sys.os == "windows" then
    cat : set "cmd" "type"
    cp : set "cmd" "copy"
       : set "flags" "/B /Y"
       : set "args" "$in $out"
end

local dot = new(default_options, "dot")
    : set "cmd" "dot"
    : set "args" "-o $out $in"

local PLANTUML = os.getenv "PLANTUML" or fs.findpath "plantuml.jar"

local plantuml = new(default_options, "plantuml")
    : set "cmd" { "java -jar", PLANTUML }
    : set "flags" { "-pipe", "charset UTF-8" }
    : set "args" "< $in > $out"

local DITAA = os.getenv "DITAA" or fs.findpath "ditaa.jar"

local ditaa = new(default_options, "ditaa")
    : set "cmd" { "java -jar", DITAA }
    : set "flags" { "-o", "-e UTF-8" }
    : set "args" "$in $out"

local asymptote = new(default_options, "asymptote")
    : set "cmd" "asy"
    : set "args" "-o $output_prefix $in"
    : set "output_prefix" (true)

local mermaid = new(default_options, "mermaid")
    : set "cmd" "mmdc"
    : set "flags" "--pdfFit"
    : set "args" "-i $in -o $out"

local blockdiag = new(default_options, "blockdiag")
    : set "cmd" "blockdiag"
    : set "flags" "-a"
    : set "args" "-o $out $in"

local gnuplot = new(default_options, "gnuplot")
    : set "cmd" "gnuplot"
    : set "args" { "-e 'set output \"$out\"'", "-c $in" }

local lsvg = new(default_options, "lsvg")
    : set "cmd" "lsvg"
    : set "flags" { "--MF $depfile" }
    : set "depfile" "$out.d"
    : set "args" "$in -o $out -- $args"

local octave = new(default_options, "octave")
    : set "cmd" "octave"
    : set "flags" {
        "--silent",
        "--no-gui",
        "--eval 'figure(\"visible\",\"off\");'",
    }
    : set "args" {
        "--eval 'run(\"$in\");'";
        "--eval 'print $out;'",
    }

return setmetatable({
    cat = cat,
    cp = cp,
    ypp = ypp, ypp_var = ypp_var, ypp_vars = ypp_vars,
    ypp_pandoc = ypp:new "ypp_pandoc" : set "cmd" "ypp-pandoc.lua",
    panda = panda,
    panda_gfm = panda:new "panda_gfm" : add "flags" "-t gfm",
    pandoc = pandoc,
    pandoc_gfm = pandoc:new "pandoc_gfm" : add "flags" "-t gfm",
    typst = typst,
    graphviz = {
        dot = {
            svg = dot:new "dot.svg" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "dot.png" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "dot.jpg" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "dot.pdf" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        neato = {
            svg = dot:new "neato.svg" : set "cmd" "neato" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "neato.png" : set "cmd" "neato" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "neato.jpg" : set "cmd" "neato" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "neato.pdf" : set "cmd" "neato" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        twopi = {
            svg = dot:new "twopi.svg" : set "cmd" "twopi" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "twopi.png" : set "cmd" "twopi" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "twopi.jpg" : set "cmd" "twopi" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "twopi.pdf" : set "cmd" "twopi" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        circo = {
            svg = dot:new "circo.svg" : set "cmd" "circo" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "circo.png" : set "cmd" "circo" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "circo.jpg" : set "cmd" "circo" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "circo.pdf" : set "cmd" "circo" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        fdp = {
            svg = dot:new "fdp.svg" : set "cmd" "fdp" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "fdp.png" : set "cmd" "fdp" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "fdp.jpg" : set "cmd" "fdp" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "fdp.pdf" : set "cmd" "fdp" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        sfdp = {
            svg = dot:new "sfdp.svg" : set "cmd" "sfdp" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "sfdp.png" : set "cmd" "sfdp" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "sfdp.jpg" : set "cmd" "sfdp" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "sfdp.pdf" : set "cmd" "sfdp" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        patchwork = {
            svg = dot:new "patchwork.svg" : set "cmd" "patchwork" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "patchwork.png" : set "cmd" "patchwork" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "patchwork.jpg" : set "cmd" "patchwork" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "patchwork.pdf" : set "cmd" "patchwork" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        osage = {
            svg = dot:new "osage.svg" : set "cmd" "osage" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = dot:new "osage.png" : set "cmd" "osage" : add "flags" "-Tpng" : set "ext" ".png",
            jpg = dot:new "osage.jpg" : set "cmd" "osage" : add "flags" "-Tjpg" : set "ext" ".jpg",
            pdf = dot:new "osage.pdf" : set "cmd" "osage" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
    },
    plantuml = {
        svg = plantuml:new "plantuml.svg" : add "flags" "-tsvg" : set "ext" ".svg",
        png = plantuml:new "plantuml.png" : add "flags" "-tpng" : set "ext" ".png",
        pdf = plantuml:new "plantuml.pdf" : add "flags" "-tpdf" : set "ext" ".pdf",
    },
    ditaa = {
        svg = ditaa:new "ditaa.svg" : add "flags" "--svg" : set "ext" ".svg",
        png = ditaa:new "ditaa.png" : set "ext" ".png",
        pdf = ditaa:new "ditaa.pdf" : set "ext" ".pdf",
    },
    asymptote = {
        svg = asymptote:new "asymptote.svg" : add "flags" "-f svg" : set "ext" ".svg",
        png = asymptote:new "asymptote.png" : add "flags" "-f png" : set "ext" ".png",
        jpg = asymptote:new "asymptote.jpg" : add "flags" "-f jpg" : set "ext" ".jpg",
        pdf = asymptote:new "asymptote.pdf" : add "flags" "-f pdf" : set "ext" ".pdf",
    },
    mermaid = {
        svg = mermaid:new "mermaid.svg" : add "flags" "-e svg" : set "ext" ".svg",
        png = mermaid:new "mermaid.png" : add "flags" "-e png" : set "ext" ".png",
        pdf = mermaid:new "mermaid.pdf" : add "flags" "-e pdf" : set "ext" ".pdf",
    },
    blockdiag = {
        svg = blockdiag:new "blockdiag.svg" : add "flags" "-Tsvg" : set "ext" ".svg",
        png = blockdiag:new "blockdiag.png" : add "flags" "-Tpng" : set "ext" ".png",
        pdf = blockdiag:new "blockdiag.pdf" : add "flags" "-Tpdf" : set "ext" ".pdf",
        activity = {
            svg = blockdiag:new "actdiag.svg" : set "cmd" "actdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "actdiag.png" : set "cmd" "actdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "actdiag.pdf" : set "cmd" "actdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        network = {
            svg = blockdiag:new "nwdiag.svg" : set "cmd" "nwdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "nwdiag.png" : set "cmd" "nwdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "nwdiag.pdf" : set "cmd" "nwdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        packet = {
            svg = blockdiag:new "packetdiag.svg" : set "cmd" "packetdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "packetdiag.png" : set "cmd" "packetdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "packetdiag.pdf" : set "cmd" "packetdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        rack = {
            svg = blockdiag:new "rackdiag.svg" : set "cmd" "rackdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "rackdiag.png" : set "cmd" "rackdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "rackdiag.pdf" : set "cmd" "rackdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
        sequence = {
            svg = blockdiag:new "seqdiag.svg" : set "cmd" "seqdiag" : add "flags" "-Tsvg" : set "ext" ".svg",
            png = blockdiag:new "seqdiag.png" : set "cmd" "seqdiag" : add "flags" "-Tpng" : set "ext" ".png",
            pdf = blockdiag:new "seqdiag.pdf" : set "cmd" "seqdiag" : add "flags" "-Tpdf" : set "ext" ".pdf",
        },
    },
    gnuplot = {
        svg = gnuplot:new "gnuplot.svg" : add "flags" { "-e 'set terminal svg'" }     : set "ext" ".svg",
        png = gnuplot:new "gnuplot.png" : add "flags" { "-e 'set terminal png'" }     : set "ext" ".png",
        jpg = gnuplot:new "gnuplot.jpg" : add "flags" { "-e 'set terminal jpeg'" }    : set "ext" ".jpg",
        pdf = gnuplot:new "gnuplot.pdf" : add "flags" { "-e 'set terminal context'" } : set "ext" ".pdf",
    },
    lsvg = {
        svg = lsvg:new "lsvg.svg" : set "ext" ".svg",
        png = lsvg:new "lsvg.png" : set "ext" ".png",
        jpg = lsvg:new "lsvg.jpg" : set "ext" ".jpg",
        pdf = lsvg:new "lsvg.pdf" : set "ext" ".pdf",
    },
    octave = {
        svg = octave:new "octave.svg" : set "ext" ".svg",
        png = octave:new "octave.png" : set "ext" ".png",
        jpg = octave:new "octave.jpg" : set "ext" ".jpg",
        pdf = octave:new "octave.pdf" : set "ext" ".pdf",
    },
}, {
    __index = {
        new = function(_, name) return cat:new(name) end,
    }
})
]])
package.preload["clean"] = lib("bang/clean.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sys = require "sys"
local help = require "help"
local ident = require "ident"

local clean = {}
local mt = {__index={}}

local directories_to_clean = F{}
local directories_to_clean_more = F{}

local builddir = "$builddir"

function mt.__call(_, dir)
    directories_to_clean[#directories_to_clean+1] = dir
end

function clean.mrproper(dir)
    directories_to_clean_more[#directories_to_clean_more+1] = dir
end

function mt.__index:default_target_needed()
    return #directories_to_clean > 0 or #directories_to_clean_more > 0
end

function mt.__index:gen()

    local rm_cmd = F.case(sys.os) {
        linux   = "rm -rf",
        macos   = "rm -rf",
        windows = "del /F /S /Q",
    }

    local function rm(dir)
        return { rm_cmd, dir/(dir==builddir and "*" or {}) }
    end

    if #directories_to_clean > 0 then

        section("Clean")

        help "clean" "clean generated files"

        local targets = directories_to_clean : map(function(dir)
            return build("clean-"..ident(dir)) {
                ["$no_default"] = true,
                description = {"CLEAN", dir},
                command = rm(dir),
            }
        end)

        phony "clean" {
            ["$no_default"] = true,
            targets,
        }

    end

    if #directories_to_clean_more > 0 then

        section("Clean (mrproper)")

        help "mrproper" "clean generated files and more"

        local targets = directories_to_clean_more : map(function(dir)
            return build("mrproper-"..ident(dir)) {
                ["$no_default"] = true,
                description = {"CLEAN", dir},
                command = rm(dir),
            }
        end)

        phony "mrproper" {
            ["$no_default"] = true,
            #directories_to_clean > 0 and "clean" or {},
            targets,
        }

    end

end

return setmetatable(clean, mt)
]])
package.preload["file"] = lib("bang/file.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local fs = require "fs"
local F = require "F"

local flatten = require "flatten"

local file_mt = {__index = {}}

function file_mt.__call(self, ...)
    self.chunks[#self.chunks+1] = {...}
    return self.name -- return the filename to easily add it to a filelist in the build file
end

function file_mt.__index:close()
    local new_content = flatten(self.chunks):str()
    local old_content = fs.read(self.name)
    if old_content == new_content then
        return -- keep the old file untouched
    end
    fs.mkdirs(self.name:dirname())
    fs.write(self.name, new_content)
end

local open_files = F{}

local function file(name)
    name = vars%name
    if open_files[name] then
        error(name..": multiple file creation")
    end
    local f = setmetatable({name=name, chunks={}}, file_mt)
    open_files[name] = f
    return f
end

return setmetatable({}, {
    __call = function(_, name) return file(name) end,
    __index = {
        flush = function()
            open_files:foreacht(function(f) f:close() end)
        end,
    },
})
]])
package.preload["flatten"] = lib("bang/flatten.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

return function(xs)
    return F.filter_ne(F.Nil, F.flatten(xs))
end
]])
package.preload["help"] = lib("bang/help.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

local product_name = ""
local description = F{}
local epilog = F{}
local targets = F{}

local help = {}
local mt = {__index={}}

local function i(s)
    return s : gsub("%$name", product_name)
end

function help.name(txt)
    product_name = txt
end

function help.description(txt)
    description[#description+1] = i(txt:rtrim())
end

function help.epilog(txt)
    epilog[#epilog+1] = i(txt:rtrim())
end

help.epilogue = help.epilog

function help.target(name)
    return function(txt)
        targets[#targets+1] = F{name=name, txt=i(txt)}
    end
end

function mt.__call(_, ...)
    return help.target(...)
end

local function help_defined()
    return not description:null() or not epilog:null() or not targets:null()
end

function mt.__index:default_target_needed()
    return help_defined()
end

function mt.__index:gen(help_token)
    if not help_defined() then return end

    if not targets:null() then
        table.insert(targets, 1, {name="help", txt="show this help message"})
    end

    local w = targets:map(function(t) return #t.name end):maximum()
    local function justify(s)
        return s..(" "):rep(w-#s)
    end

    section "Help"

    local help_message = F{
        description:null() and {} or description:unlines(),
        "",
        targets:null() and {} or {
            "Targets:",
            targets : map(function(target)
                return F"  %s   %s":format(justify(target.name), target.txt)
            end)
        },
        "",
        epilog:null() and {} or epilog:unlines(),
    } : flatten()
      : unlines()
      : trim()
      : gsub("\n\n+", "\n\n")   -- remove duplicate blank lines
      : lines()

    acc(help_token) {
        help_message : map(F.compose{string.rtrim, F.prefix"# "}) : unlines(),
        "\n",
    }

    build "help" {
        ["$no_default"] = true,
        description = "help",
        command = help_message
          : map(function(line) return ("echo %q"):format(line) end)
          : str "; $\n            "
    }

end

return setmetatable(help, mt)
]])
package.preload["ident"] = lib("bang/ident.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local gsub = string.gsub

return function(s)
    return gsub(s, "[^a-zA-Z0-9_%.%-]+", "_")
end
]])
package.preload["install"] = lib("bang/install.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sys = require "sys"

local flatten = require "flatten"
local ident = require "ident"

local prefix = "~/.local"
local targets = F{}

local install = {}
local mt = {__index={}}

function install.prefix(dir)
    prefix = dir
end

function mt.__call(_, name)
    return function(sources)
        targets[#targets+1] = F{name=name, sources=sources}
    end
end

function mt.__index:default_target_needed()
    return not targets:null()
end

function mt.__index:gen(install_rule, install_token)
    if targets:null() then
        return
    end

    section "Installation"

    help "install" ("install $name in PREFIX or "..prefix)

    var "prefix" (prefix)

    local function destdir(target_name)
        return case(sys.os) {
            linux   = "$${DESTDIR}$${PREFIX:-$prefix}"/target_name,
            macos   = "$${DESTDIR}$${PREFIX:-$prefix}"/target_name,
            windows = "%PREFIX%"/target_name,
        }
    end

    rule(install_rule) {
        description = "INSTALL $in to $destdir",
        command = case(sys.os) {
            linux = "mkdir -p $destdir && cp -v --force --preserve=mode,timestamp $in $destdir",
            macos = "mkdir -p $destdir && cp -v -f -p $in $destdir",
            windows = "copy $in $destdir",
        },
        pool = "console",
    }

    local rule_names = targets
    : sort(function(a, b) return a.name < b.name end)
    : group(function(a, b) return a.name == b.name end)
    : map(function(target_group)
        local target_name = target_group[1].name
        local rule_name = "install-"..ident(target_name)
        acc(install_token) {
            "# Files installed in "..target_name.."\n",
            target_group
                : map(function(target)
                    local files = flatten{target.sources} : map(tostring) : unwords() : words()
                    return files:map(function(file) return "#   "..(vars%file).."\n" end)
                end),
            "\n",
        }
        return build(rule_name) { "install", target_group:map(function(target) return target.sources end),
            ["$no_default"] = true,
            destdir = destdir(target_name)
        }
    end)

    phony "install" {
        ["$no_default"] = true,
        rule_names,
    }

end

return setmetatable(install, mt)
]])
package.preload["log"] = lib("bang/log.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

local where = require "where"

local log = {}

local quiet = false

function log.config(args)
    quiet = args.quiet
end

function log.error(...)
    io.stderr:write(F.flatten{where(), "ERROR: ", {...}, "\n"}:unpack())
    os.exit(1)
end

function log.warning(...)
    io.stderr:write(F.flatten{where(), "WARNING: ", {...}, "\n"}:unpack())
end

function log.info(...)
    if not quiet then
        io.stdout:write(F.flatten{{...}, "\n"}:unpack())
    end
end

return log
]])
package.preload["luax"] = lib("bang/luax.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sys = require "sys"
local targets = require "luax-targets"

local default_options = {
    name = "luax",
    luax = "luax",
    target = "luax",
    flags = {},
    implicit_in = Nil,
    exe_ext = "",
}

local function set_ext(name, ext)
    if (vars%name):has_suffix(ext) then return name end
    return name..ext
end

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local rules = setmetatable({}, {
    __index = function(self, compiler)
        local new_rule = rule(compiler.name) {
            description = compiler.description or {compiler.name, "$out"},
            command = { compiler.luax, "compile", "-t", compiler.target, "$in -o $out", compiler.flags },
            implicit_in = compiler.implicit_in,
        }
        self[compiler] = new_rule
        return new_rule
    end
})

local function run(self, output)
    return function(inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        output = set_ext(output, self.exe_ext)
        return build(output) (F.merge{
            { rules[self], input_list },
            input_vars,
        })
    end
end

local compiler_mt

local compilers = F{}

local function new(compiler, name)
    if compilers[name] then
        error(name..": compiler redefinition")
    end
    local self = F.merge { compiler, {name=name} }
    compilers[name] = self
    return setmetatable(self, compiler_mt)
end

local function check_opt(name)
    assert(default_options[name], name..": Unknown compiler option")
end

compiler_mt = {
    __call = run,

    __index = {
        new = new,

        set = function(self, name)
            check_opt(name)
            return function(value) self[name] = value; return self end
        end,
        add = function(self, name)
            check_opt(name)
            return function(value) self[name] = {self[name], value}; return self end
        end,
        insert = function(self, name)
            check_opt(name)
            return function(value) self[name] = {value, self[name]}; return self end
        end,
    },
}

local luax = new(default_options, "luax") : set "target" "luax"
local lua = luax:new "luax-lua" : set "target" "lua"
local pandoc = luax:new "luax-pandoc" : set "target" "pandoc"
local native = luax:new "luax-native" : set "target" "native" : set "exe_ext" (sys.exe)

local M = {
    luax = luax,
    lua = lua,
    pandoc = pandoc,
    native = native,
}
targets : foreach(function(target)
    M[target.name] = native:new("luax-"..target.name) : set "target" (target.name) : set "exe_ext" (target.exe)
end)

return setmetatable(M, {
    __call = function(_, ...) return luax(...) end,
    __index = {
        new = function(_, ...) return luax:new(...) end,
        set = function(_, ...) return luax:set(...) end,
        add = function(_, ...) return luax:add(...) end,
        insert = function(_, ...) return luax:insert(...) end,
        set_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:set(name)(value) end)
            end
        end,
        add_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:add(name)(value) end)
            end
        end,
        insert_global = function(name)
            check_opt(name)
            return function(value)
                F.foreacht(M, function(compiler) compiler:insert(name)(value) end)
            end
        end,
    }
})
]])
package.preload["ninja"] = lib("bang/ninja.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local fs = require "fs"
local package = require "luax-package"
local atexit = require "atexit"

local log = require "log"
local ident = require "ident"
local flatten = require "flatten"

local tostring = tostring
local type = type

local words = string.words

local clone = F.clone
local difference = F.difference
local filterk = F.filterk
local foreach = F.foreach
local foreachk = F.foreachk
local keys = F.keys
local map = F.map
local restrict_keys = F.restrict_keys
local unwords = F.unwords
local values = F.values
local without_keys = F.without_keys

local default_builddir = ".build"
local overridden_builddir = nil
local ninja_required_version_for_bang = F"1.11.1"

local help_token = {}
local install_token = {}
local command_line_token = {}

local tokens = F{
    "# Ninja file generated by bang (https://codeberg.org/cdsoft/luax)\n",
    command_line_token,
    "\n",
    help_token,
    install_token,
}

local nbnl = 1
local nb_tokens = #tokens

function emit(x)
    nb_tokens = nb_tokens + 1
    tokens[nb_tokens] = x
    nbnl = 0
end

local function comment_line(line)
    if #line == 0 then return "#" end
    return "# "..line
end

function comment(txt)
    emit(txt
        : lines()
        : map(comment_line)
        : unlines())
end

function nl()
    if nbnl < 1 then
        emit "\n"
    end
    nbnl = nbnl + 1
end

local token_separator = F"#":rep(70).."\n"

function section(txt)
    nl()
    emit(token_separator)
    comment(txt)
    emit(token_separator)
    nl()
end

local function stringify(value)
    return unwords(map(tostring, flatten{value}))
end

local builddir_token = { default_builddir }

nl()
emit { "builddir = ", builddir_token }
nl()

local nbvars = 0

local vars = {}

local function expand(s)
    if type(s) == "string" then
        -- worst case : one iteration per variable (in case of pathologically chained definitions)
        local max_iterations = nbvars
            + 1 -- implicit builddir definition
            + 1 -- to be able to detect true recursive definitions
        local s0 = s
        for _ = 1, max_iterations do
            local s1 = s0:gsub("%$([%w_%-]+)", vars)
            if s1 == s0 then return s0 end
            s0 = s1
        end
        log.error("vars%... can not expand ", string.format("%q", s), " (recursive definition?)")
    end
    if type(s) == "table" then
        return map(expand, s)
    end
    log.error("vars%... expects a string or a list of strings")
end

_G.vars = setmetatable(vars, {
    __mod = function(_, s) return expand(s) end,
    __index = function(_, k)
        if k == "builddir" then return overridden_builddir or builddir_token[1] end
    end,
})

local builddir_definitions = 0

function var(name)
    if name == "builddir" then builddir_definitions = builddir_definitions + 1 end
    if rawget(vars, name) or builddir_definitions > 1 then
        log.error("var "..name..": multiple definition")
    end
    return function(value)
        value = stringify(value)
        if name == "builddir" then
            builddir_token[1] = overridden_builddir or value
        else
            emit(name.." = "..value.."\n")
            vars[name] = value
            nbvars = nbvars + 1
        end
        return "$"..name
    end
end

local ninja_required_version_token = { ninja_required_version_for_bang }

nl()
emit { "ninja_required_version = ", ninja_required_version_token, "\n" }
nl()

function ninja_required_version(required_version)
    local current = ninja_required_version_token[1] : split "%." : map(tonumber)
    local new = required_version : split "%." : map(tonumber)
    for i = 1, #new do
        current[i] = current[i] or 0
        if new[i] > current[i] then ninja_required_version_token[1] = required_version; return end
        if new[i] < current[i] then return end
    end
end

local rule_variables = F{
    "description",
    "command",
    "in",
    "in_newline",
    "out",
    "depfile",
    "deps",
    "dyndep",
    "pool",
    "msvc_deps_prefix",
    "generator",
    "restat",
    "rspfile",
    "rspfile_content",
}

local build_special_bang_variables = F{
    "implicit_in",
    "implicit_out",
    "order_only_deps",
    "validations",
}

local is_build_special_bang_variable = build_special_bang_variables
    : map2t(function(name) return name, true end)

local rules = {
--  "rule_name" = {
--      inherited_variables = {implicit_in=..., implicit_out=...}
--  }
}

local function new_rule(name)
    rules[name] = { inherited_variables = {} }
end

new_rule "phony"

local nbrules = 0

function rule(name)
    return function(opt)
        if rules[name] then
            log.error("rule "..name..": multiple definition")
        end
        if opt.command == nil then
            log.error("rule "..name..": expected 'command' attribute")
        end

        new_rule(name)
        nbrules = nbrules + 1

        nl()

        emit("rule "..name.."\n")

        -- list of variables belonging to the rule definition
        rule_variables : foreach(function(varname)
            local value = opt[varname]
            if value ~= nil then emit("  "..varname.." = "..stringify(value).."\n") end
        end)

        -- list of variables belonging to the associated build statements
        build_special_bang_variables : foreach(function(varname)
            rules[name].inherited_variables[varname] = opt[varname]
        end)

        -- other variables are unknown
        local unknown_variables = F.keys(opt)
            : difference(rule_variables)
            : difference(build_special_bang_variables)
        if #unknown_variables > 0 then
            log.error("rule "..name..": unknown variables: "..unknown_variables:str", ")
        end

        nl()

        return name
    end
end

local function unique_rule_name(name)
    local rule_name = name
    local prefix = name.."-"
    local i = 0
    while rules[rule_name] do
        i = i + 1
        rule_name = prefix..i
    end
    return rule_name
end

local function defined(x)
    return x and #x>0
end

local builds = {}

local default_build_statements = {}
local custom_default_statement = false

local nbbuilds = 0

local build = {}
local build_mt = {}

function build.files(predicate)
    local p = F.case(type(predicate)) {
        ["string"]   = function(name, rule) return rule ~= "phony" and name:has_prefix(predicate) end,
        ["function"] = function(name, rule) return rule ~= "phony" and predicate(name, rule) end,
        ["nil"]      = function(_, rule)    return rule ~= "phony" end,
        [F.Nil]      = function() log.error("build.files expects a string or a function") end,
    }
    return F.filterk(p, builds) : keys()
end

function build.new(...)
    return build.builders:new(...)
end

local function attach(mod)
    build[mod] = require(mod)
end

local function inject(mod)
    attach(mod)
    foreachk(build[mod], function(name, func) build[name] = func end)
end

inject "builders"
attach "luax"
inject "C"
inject "archivers"

function build_mt.__call(_, outputs)
    outputs = stringify(outputs)
    return function(inputs)
        -- variables defined in the current build statement
        local build_opt = filterk(function(k, _) return type(k) == "string" and not k:has_prefix"$" end, inputs)
        local no_default = inputs["$no_default"]

        if build_opt.command then
            -- the build statement contains its own rule
            -- => create a new rule for this build statement only
            local rule_name = unique_rule_name(ident(outputs))
            local rule_opt = restrict_keys(build_opt, rule_variables)
            rule(rule_name)(rule_opt)
            build_opt = without_keys(build_opt, rule_variables)

            -- add the rule name to the actuel build statement
            inputs = {rule_name, inputs}
        end

        -- variables defined at the rule level and inherited by this statement
        local rule_name = flatten{inputs}:head():words():head()
        if not rules[rule_name] then
            log.error(rule_name..": unknown rule")
        end
        local rule_opt = rules[rule_name].inherited_variables

        -- merge both variable sets
        local opt = clone(rule_opt)
        foreachk(build_opt, function(varname, value)
            opt[varname] = opt[varname]~=nil and {opt[varname], value} or value
        end)

        emit("build "
            ..outputs
            ..(defined(opt.implicit_out) and " | "..stringify(opt.implicit_out) or "")
            ..": "
            ..stringify(inputs)
            ..(defined(opt.implicit_in) and " | "..stringify(opt.implicit_in) or "")
            ..(defined(opt.order_only_deps) and " || "..stringify(opt.order_only_deps) or "")
            ..(defined(opt.validations) and " |@ "..stringify(opt.validations) or "")
            .."\n"
        )

        foreachk(opt, function(varname, value)
            if not is_build_special_bang_variable[varname] then
                emit("  "..varname.." = "..stringify(value).."\n")
            end
        end)

        nbbuilds = nbbuilds + 1

        local output_list = words(outputs)
        foreach(output_list, function(output)
            if builds[output] then
                log.error("build "..output..": multiple definition")
            end
            builds[output] = rule_name
        end)
        if not no_default then
            default_build_statements[#default_build_statements+1] = output_list
        end
        return #output_list ~= 1 and output_list or output_list[1]
    end
end

_G.build = setmetatable(build, build_mt)

local pool_variables = F{
    "depth",
}

local pools = {}

function pool(name)
    return function(opt)
        if pools[name] then
            log.error("pool "..name..": multiple definition")
        end
        pools[name] = true
        emit("pool "..name.."\n")
        foreach(pool_variables, function(varname)
            local value = opt[varname]
            if value ~= nil then emit("  "..varname.." = "..stringify(value).."\n") end
        end)
        local unknown_variables = difference(keys(opt), pool_variables)
        if #unknown_variables > 0 then
            log.error("pool "..name..": unknown variables: "..unknown_variables:str", ")
        end
        return name
    end
end

function default(targets)
    local default_targets = stringify(targets)
    if default_targets ~= "" then
        custom_default_statement = true
        nl()
        emit("default "..default_targets.."\n")
        nl()
    end
end

local function generate_default()
    if custom_default_statement then return end
    if require"clean".default_target_needed()
    or require"help".default_target_needed()
    or require"install".default_target_needed()
    then
        section "Default targets"
        default(default_build_statements)
    end
end

function phony(outputs)
    return function(inputs)
        return build(outputs) {"phony", inputs,
            ["$no_default"] = inputs["$no_default"],
        }
    end
end

local generator_flag = {}
local generator_called = false

function generator(flag)
    if generator_called then
        log.error("generator: multiple call")
    end
    generator_called = true

    if flag == nil or flag == true then
        flag = {}
    end

    if type(flag) ~= "boolean" and type(flag) ~= "table" then
        log.error("generator: boolean or table expected")
    end

    generator_flag = flag
end

local function generator_rule(args)
    if not generator_flag then return end

    section(("Regenerate %s when %s changes"):format(args.output, args.input))

    local bang_cmd = args.gen_cmd or
        filterk(function(k)
            return math.type(k) == "integer" and k <= 0
        end, args.cli_args) : values() : unwords()

    local command_line = F{
        bang_cmd,
        "-g", string.format("%q", bang_cmd),
        args.quiet and "-q" or {},
        "$in -o $out",
        #_G.arg > 0 and {"--", _G.arg} or {},
    }

    local bang = rule(unique_rule_name "bang") {
        command = command_line,
        generator = true,
    }

    local deps = values(package.modpath)

    local gitdeps = (function()
        local files = F{}
        local dir = ".git"
        if fs.is_file(dir) then dir = (fs.read(dir) or "") : match "gitdir:%s*(.*)" end
        if dir and fs.is_dir(dir) then
            files = F.filter(fs.stat, { dir/"refs"/"tags" })
        end
        return files
    end)()

    if not deps:null() or not gitdeps:null() then
        generator_flag.implicit_in = flatten{ generator_flag.implicit_in or {}, deps, gitdeps }
            : nub()
            : difference { args.input }
    end

    acc(command_line_token) {
        "# "..flatten(command_line):unwords()
            : gsub("%$in", args.input)
            : gsub("%$out", args.output),
        "\n",
    }

    generator_flag.pool = generator_flag.pool or "console"

    build(args.output) (F.merge{
        { ["$no_default"] = true },
        { bang, args.input },
        generator_flag,
    })
end

local function size(x)
    local s = #x
    if s > 1024*1024 then return s//(1024*1024), " MB" end
    if s > 1024 then return s//1024, " kB" end
    return s, " bytes"
end

return function(args)
    if args.builddir then
        overridden_builddir = args.builddir
        builddir_token[1] = args.builddir
    end
    log.info("load ", args.input)
    if not fs.is_file(args.input) then
        log.error(args.input, ": file not found")
    end
    _G.bang = F.clone(args)
    assert(loadfile(args.input, "t"))()
    atexit.run()
    install:gen(unique_rule_name("install"), install_token)
    clean:gen()
    help:gen(help_token) -- help shall be generated after clean and install
    generator_rule(args)
    generate_default()
    local ninja = flatten(tokens) : str()
    log.info(nbvars, " variables")
    log.info(nbrules, " rules")
    log.info(nbbuilds, " build statements")
    log.info(size(ninja))
    return ninja
end
]])
package.preload["pipe"] = lib("bang/pipe.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

local tmp = require "tmp"

local function split_hybrid_table(t)
    local function is_numeric_key(k)
        return math.type(k) == "integer"
    end
    return F.table_partition_with_key(is_numeric_key, t)
end

local function pipe(rules)
    assert(#rules > 0, "pipe requires at least one rule")
    local builddir = rules.builddir or "$builddir/tmp"
    return F.curry(function(output, inputs)
        if type(inputs) == "string" then
            inputs = {inputs}
        end
        local input_list, input_vars = split_hybrid_table(inputs)
        local implicit_in = input_vars.implicit_in
        local implicit_out = input_vars.implicit_out
        input_vars.implicit_in = nil
        input_vars.implicit_out = nil
        local rule_names = F.map(function(r)
            return type(r)=="table" and r:rule() or r
        end, rules)
        local current_names = F.range(1, #rules):scan(function(name, _)
            local prefix, ext = name:splitext()
            return ext == ".in" and prefix or name
        end, input_list:head())
        local tmpfiles = F.range(1, #rules-1):map(function(i)
            local ext = rule_names[i]:ext()
            if ext == "" then ext = current_names[i+1]:ext() end
            return tmp(builddir, output, output:basename():splitext().."-"..tostring(i))..ext
        end)
        for i = 1, #rules do
            build(tmpfiles[i] or output) (F.merge{
                { rule_names[i], {tmpfiles[i-1] or input_list} },
                input_vars,
                {
                    implicit_in  = i==1      and implicit_in  or nil,
                    implicit_out = i==#rules and implicit_out or nil,
                },
            })
        end
        return output
    end)
end

return pipe
]])
package.preload["prepro"] = lib("bang/prepro.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"

local tmp = require "tmp"

local prepro = {}
local prepro_mt = { __index={} }

function prepro_mt.__index:new(t)
    local new_prepro = {}
    new_prepro.dir = t.dir or self.dir
    new_prepro.pp = t.pp or self.pp
    return setmetatable(new_prepro, prepro_mt)
end

function prepro_mt.__call(self, ...)
    local dir = self.dir or "$builddir"
    local pp = self.pp or build.ypp
    return F.flatten{...} : map(function(src)
        local out = tmp.clean(dir/src:gsub("%.in$", ""))
        return pp(out) { src }
    end)
end

return setmetatable(prepro, prepro_mt)
]])
package.preload["tmp"] = lib("bang/tmp.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local fs = require "fs"

local tmp = {}

local unique_index = setmetatable({_=0}, {
    __index = function(self, k)
        local idx = ("%x"):format(self._)
        self._ = self._ + 1
        self[k] = idx
        return idx
    end,
})

function tmp.clean(path)
    local n = 0
    return fs.join(fs.splitpath(path)
        : map(function(dir)
            if dir == "$builddir" then
                n = n + 1
                return n <= 1 and dir or nil
            end
            return dir
        end))
end

function tmp.index(root, ...)
    local ps = {...}
    return tmp.clean(root / unique_index[fs.join(F.init(ps))] / F.last(ps):splitext())
end

function tmp.hash(root, ...)
    local ps = {...}
    return tmp.clean(root / fs.join(F.init(ps)):hash() / F.last(ps):splitext())
end

function tmp.short(root, ...)
    local root_components = fs.splitpath(root)
    local path = fs.join(F.init{...})
        : splitpath()
        : reverse()
        : nub()
        : reverse()
        : filter(function(p) return F.not_elem(p, root_components) end)
    path[#path] = path[#path]..".tmp"
    local file = F.last{...} : splitext()
    return tmp.clean(fs.join(F.flatten { root, path, file }))
end

return setmetatable(tmp, {__call = function(self, ...) return self.short(...) end})
]])
package.preload["version"] = lib("bang/version.lua", [=[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

local F = require "F"
local sh = require "sh"
local term = require "term"
local fs = require "fs"

local red = term.color.white + term.color.onred + term.color.bright

local function git_warning(tag)
    if not fs.stat ".git" then return end
    if not fs.findpath "git" then return end
    local git_tag = sh "git describe --tags"
    if not git_tag then return end
    git_tag = git_tag : trim()
    if tag == git_tag then return end
    return F.I { tag=tag, git_tag=git_tag } [[
+----------------------------------------------------------------------+
| WARNING: version mismatch                                            |
|                                                                      |
| Version : $(tag:ljust(58)                                          ) |
| Git tag : $(git_tag:ljust(58)                                      ) |
|                                                                      |
| Please add a new git tag or fix the version before the next release. |
+----------------------------------------------------------------------+
]] : trim()
end

local function print_warning(warning_function, tag)
    local warning = warning_function(tag)
    if warning then
        comment(warning)
        print(warning:lines():map(red):unlines())
    end
end

local function version(tag)
    term.color.enable(term.isatty(io.stdout))
    print_warning(git_warning, tag)
    var "version" { tag }
    return function(date)
        var "date" { date }
    end
end

return version
]=])
package.preload["where"] = lib("bang/where.lua", [[-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

return function()
    -- get the current location in the first user script in the call stack

    local i = 2
    while true do
        local info = debug.getinfo(i)
        if not info then return "" end
        local file = info.source : match "^@(.*)"
        if file and not file:has_prefix "$" then
            return ("[%s:%d] "):format(file, info.currentline)
        end
        i = i + 1
    end

end
]])
require "F"
require "crypt"
require "fs"
require "luax-debug"
require "luax-package"
require "lz4"
require "lzip"
return lib("bang/bang.lua", [[--/usr/bin/env luax

-- This file is part of bang.
--
-- bang is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- bang is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with bang.  If not, see <https://www.gnu.org/licenses/>.
--
-- For further information about bang you can visit
-- https://codeberg.org/cdsoft/luax

--@MAIN

local F = require "F"
local fs = require "fs"

_G.acc = require "acc"
_G.case = F.case
_G.Nil = F.Nil
_G.file = require "file"
_G.ls = fs.ls
_G.flatten = require "flatten"

_G.help = require "help"
_G.clean = require "clean"
_G.install = require "install"
_G.pipe = require "pipe"
_G.prepro = require "prepro"
_G.version = require "version"

local ninja = require "ninja"
local log = require "log"
local version = require "luax-version".version
local package = require "luax-package"

local function parse_args()
    local parser = require "argparse"()
        : name "bang"
        : description(F.unlines {
            "BANG (Bang Automates Ninja Generation)",
            "",
            "Bang is a Ninja build file generator scriptable in LuaX.",
            "",
            "Arguments after \"--\" are given to the input script.",
        } : rtrim())
        : epilog "For more information, see https://codeberg.org/cdsoft/luax"

    parser : flag "-v"
        : description(('Print Bang version ("%s")'):format(version))
        : action(function() print(version); os.exit() end)

    parser : flag "-q"
        : description "Quiet mode (no output on stdout)"
        : target "quiet"

    parser : option "-g"
        : description "Set a custom command for the generator rule"
        : argname "cmd"
        : target "gen_cmd"

    parser : option "-b"
        : description "Build directory (builddir variable)"
        : argname "builddir"
        : target "builddir"

    parser : option "-o"
        : description "Output file (default: build.ninja)"
        : argname "output"
        : target "output"

    parser : argument "input"
        : description "Lua script (default: build.lua)"
        : args "0-1"

    local bang_arg, script_arg = F.break_(F.partial(F.op.eq, "--"), arg)
    local args = F.merge{
        { cli_args = arg },
        { input="build.lua", output="build.ninja" },
        parser:parse(bang_arg),
    }

    _G.arg = script_arg : drop(1)
    _G.arg[0] = args.input

    return args
end

local args = parse_args()
log.config(args)
package.path = package.path..";"..args.input:dirname().."/?.lua"
local ninja_file = ninja(args)
log.info("write ", args.output)
require "file" : flush()
fs.write(args.output, ninja_file)
]])()

