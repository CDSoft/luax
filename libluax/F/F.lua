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
    __index = setmetatable({}, {
        __newindex = function(t, k, v)
            rawset(t, k, v)         -- set the method k
            rawset(t, "__"..k, v)   -- and its __k alias in case of conflict with table fields named k
        end,
    }),
}

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

local function register0(name)
    return function(f)
        F[name] = f
        return f
    end
end

local function register1(name)
    return function(f)
        F[name] = f
        mt.__index[name] = f
        return f
    end
end

local function register2(name)
    return function(f)
        F[name] = f
        mt.__index[name] = function(t, x1, ...) return f(x1, t, ...) end
        return f
    end
end

local function register3(name)
    return function(f)
        F[name] = f
        mt.__index[name] = function(t, x1, x2, ...) return f(x1, x2, t, ...) end
        return f
    end
end

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
function F.even(n) return n&1 == 0 end
function F.odd(n) return n&1 == 1 end

--[[@@@
```lua
F.gcd(a, b)
F.lcm(a, b)
```
> Greatest Common Divisor and Least Common Multiple of a and b.
@@@]]
local function gcd(a, b)
    a, b = abs(a), abs(b)
    while b > 0 do
        a, b = b, a%b
    end
    return a
end
local function lcm(a, b)
    return abs(a // gcd(a,b) * b)
end
F.gcd, F.lcm = gcd, lcm

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
local function err(msg, level, tb)
    level = (level or 1) + 2
    local info = debug.getinfo(level)
    local file = info.short_src
    local line = info.currentline
    msg = t_concat{arg[0], ": ", file, ":", line, ": ", msg}
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

local default_show_options = {
    int = "%s",
    flt = "%s",
    indent = nil,
    lt = F.op.klt,
}

register1 "show" (function(x, opt)

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
                local n = 0
                for i = 1, #val do
                    fmt(val[i])
                    emit ", "
                    n = n + 1
                end
                local first_field = true
                for k, v in F_pairs(val, opt_lt) do
                    if not (type(k) == "number" and math_type(k) == "integer" and 1 <= k and k <= #val) then
                        if first_field and opt_indent and n > 1 then drop() emit "," end
                        first_field = false
                        need_nl = opt_indent ~= nil
                        if opt_indent then emit "\n" emit(s_rep(" ", tabs)) end
                        if type(k) == "string" and s_match(k, "^[%a_][%w_]*$") then
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
                emit(s_format(opt_flt, val))
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

F_clone = register1 "clone" (function(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return setmetatable(t2, mt)
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
    return setmetatable(go(t), mt)
end)

--[[@@@
```lua
F.rep(n, x)
```
> Returns a list of length n with x the value of every element.
@@@]]

register0 "rep" (function(n, x)
    local xs = {}
    for i = 1, n do
        xs[i] = x
    end
    return setmetatable(xs, mt)
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
    return setmetatable(r, mt)
end)

--[[@@@
```lua
F.concat{xs1, xs2, ... xsn}
F{xs1, xs2, ... xsn}:concat()
xs1 .. xs2
```
> concatenates lists
@@@]]

F_concat = register1 "concat"(function(xss)
    local ys = {}
    for i = 1, #xss do
        local xs = xss[i]
        for j = 1, #xs do
            ys[#ys+1] = xs[j]
        end
    end
    return setmetatable(ys, mt)
end)

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

local function default_leaf(x)
    -- by default, a table is a leaf if it has a metatable and is not an F' list
    local xmt = getmetatable(x)
    return xmt and xmt ~= mt
end

F_flatten = register1 "flatten" (function(xs, leaf)
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
        if #ss <= 1 then return ss[1] or "" end
        return t_concat({t_concat(ss, sep, 1, #ss-1), ss[#ss]}, last_sep)
    else
        return t_concat(ss, sep)
    end
end)

--[[@@@
```lua
F.from_set(f, ks)
ks:from_set(f)
```
> Build a map from a set of keys and a function which for each key computes its value.
@@@]]

F_from_set = register2 "from_set" (function(f, ks)
    local t = {}
    for i = 1, #ks do
        local k = ks[i]
        t[k] = f(k)
    end
    return setmetatable(t, mt)
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
        local k, v = t_unpack(kvs[i])
        t[k] = v
    end
    return setmetatable(t, mt)
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
> `F.pairs` sorts keys using the function `comp_lt` or the default `<=` operator for keys (`F.op.klt`).
@@@]]

register1 "ipairs" (ipairs)

F_pairs = register1 "pairs" (function(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local i = 0
    return function()
        i = i+1
        if i <= #ks then
            local k = ks[i]
            return k, t[k]
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

F_keys = register1 "keys" (function(t, comp_lt)
    comp_lt = comp_lt or key_lt
    local ks = {}
    for k, _ in pairs(t) do ks[#ks+1] = k end
    t_sort(ks, comp_lt)
    return setmetatable(ks, mt)
end)

register1 "values" (function(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local vs = {}
    for i = 1, #ks do vs[i] = t[ks[i]] end
    return setmetatable(vs, mt)
end)

register1 "items" (function(t, comp_lt)
    local ks = F_keys(t, comp_lt)
    local kvs = {}
    for i = 1, #ks do
        local k = ks[i]
        kvs[i] = setmetatable({k, t[k]}, mt) end
    return setmetatable(kvs, mt)
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

F_head = register1 "head" (function(xs) return xs[1] end)
F_last = register1 "last" (function(xs) return xs[#xs] end)

--[[@@@
```lua
F.tail(xs)
xs:tail()
F.init(xs)
xs:init()
```
> returns the list after the head (tail) or before the last element (init).
@@@]]

F_tail = register1 "tail" (function(xs)
    if #xs == 0 then return nil end
    local tail = {}
    for i = 2, #xs do tail[#tail+1] = xs[i] end
    return setmetatable(tail, mt)
end)

F_init = register1 "init" (function(xs)
    if #xs == 0 then return nil end
    local init = {}
    for i = 1, #xs-1 do init[#init+1] = xs[i] end
    return setmetatable(init, mt)
end)

--[[@@@
```lua
F.uncons(xs)
xs:uncons()
```
> returns the head and the tail of a list.
@@@]]

register1 "uncons" (function(xs) return F_head(xs), F_tail(xs) end)

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

F_take = register2 "take" (function(n, xs)
    local ys = {}
    for i = 1, n do
        ys[i] = xs[i]
    end
    return setmetatable(ys, mt)
end)

--[[@@@
```lua
F.drop(n, xs)
xs:drop(n)
```
> Returns the suffix of xs after the first n elements.
@@@]]

F_drop = register2 "drop" (function(n, xs)
    local ys = {}
    for i = n+1, #xs do
        ys[#ys+1] = xs[i]
    end
    return setmetatable(ys, mt)
end)

--[[@@@
```lua
F.split_at(n, xs)
xs:split_at(n)
```
> Returns a tuple where first element is xs prefix of length n and second element is the remainder of the list.
@@@]]

register2 "split_at" (function(n, xs)
    return F_take(n, xs), F_drop(n, xs)
end)

--[[@@@
```lua
F.take_while(p, xs)
xs:take_while(p)
```
> Returns the longest prefix (possibly empty) of xs of elements that satisfy p.
@@@]]

F_take_while = register2 "take_while" (function(p, xs)
    local ys = {}
    local i = 1
    while i <= #xs and p(xs[i]) do
        ys[i] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt)
end)

--[[@@@
```lua
F.drop_while(p, xs)
xs:drop_while(p)
```
> Returns the suffix remaining after `take_while(p, xs)`{.lua}.
@@@]]

F_drop_while = register2 "drop_while" (function(p, xs)
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
end)

--[[@@@
```lua
F.drop_while_end(p, xs)
xs:drop_while_end(p)
```
> Drops the largest suffix of a list in which the given predicate holds for all elements.
@@@]]

F_drop_while_end = register2 "drop_while_end" (function(p, xs)
    local zs = {}
    local i = #xs
    while i > 0 and p(xs[i]) do
        i = i-1
    end
    for j = 1, i do
        zs[j] = xs[j]
    end
    return setmetatable(zs, mt)
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
        ys[i] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt), setmetatable(zs, mt)
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
        ys[i] = xs[i]
        i = i+1
    end
    while i <= #xs do
        zs[#zs+1] = xs[i]
        i = i+1
    end
    return setmetatable(ys, mt), setmetatable(zs, mt)
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
    return setmetatable(ys, mt)
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
    return setmetatable(ys, mt)
end)

--[[@@@
```lua
F.group(xs, [comp_eq])
xs:group([comp_eq])
```
> Returns a list of lists such that the concatenation of the result is equal to the argument. Moreover, each sublist in the result contains only equal elements.
@@@]]

register1 "group" (function(xs, comp_eq)
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
            ys[j] = xs[j]
        end
        yss[#yss+1] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
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
        yss[#yss+1] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
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

F_is_prefix_of = register1 "is_prefix_of" (function(prefix, xs)
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

F_is_suffix_of = register1 "is_suffix_of" (function(suffix, xs)
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

F_is_infix_of = register1 "is_infix_of" (function(infix, xs)
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

register1 "has_prefix" (function(xs, prefix) return F_is_prefix_of(prefix, xs) end)

--[[@@@
```lua
F.has_suffix(xs, suffix)
xs:has_suffix(suffix)
```
> Returns `true` iff `xs` ends with `suffix`
@@@]]

register1 "has_suffix" (function(xs, suffix) return F_is_suffix_of(suffix, xs) end)

--[[@@@
```lua
F.has_infix(xs, infix)
xs:has_infix(infix)
```
> Returns `true` iff `xs` caontains `infix`
@@@]]

register1 "has_infix" (function(xs, infix) return F_is_infix_of(infix, xs) end)

--[[@@@
```lua
F.is_subsequence_of(seq, xs)
seq:is_subsequence_of(xs)
```
> Returns `true` if all the elements of the first list occur, in order, in the second. The elements do not have to occur consecutively.
@@@]]

register1 "is_subsequence_of" (function(seq, xs, comp_eq)
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
F.map_contains(t1, t2)
t1:map_contains(t2)
```
> returns true if all keys in t2 are in t1.
@@@]]

register1 "map_contains" (function(t1, t2)
    for k, _ in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
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
F.map_strictly_contains(t1, t2)
t1:map_strictly_contains(t2)
```
> returns true if all keys in t2 are in t1.
@@@]]

register1 "map_strictly_contains" (function(t1, t2)
    for k, _ in pairs(t2) do
        if t1[k] == nil then return false end
    end
    for k, _ in pairs(t1) do
        if t2[k] == nil then return true end
    end
    return false
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
    comp_eq = comp_eq or F_op_eq
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
    comp_eq = comp_eq or F_op_eq
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
    comp_eq = comp_eq or F_op_eq
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
    return setmetatable(ys, mt)
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
    return setmetatable(ys, mt)
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
    return setmetatable(t2, mt)
end)

--[[@@@
```lua
F.filterk(p, t)
t:filterk(p)
```
> Returns the table of those values that satisfy the predicate p(k, v).
@@@]]

F_filterk = register2 "filterk" (function(p, t)
    local t2 = {}
    for k, v in pairs(t) do
        if p(k, v) then t2[k] = v end
    end
    return setmetatable(t2, mt)
end)

--[[@@@
```lua
F.restrict_keys(t, ks)
t:restrict_keys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

register1 "restrict_keys" (function(t, ks)
    local kset = F_from_set(F_const(true), ks)
    local function p(k, _) return kset[k] end
    return F_filterk(p, t)
end)

--[[@@@
```lua
F.without_keys(t, ks)
t:without_keys(ks)
```
> Restrict a map to only those keys found in a list.
@@@]]

register1 "without_keys" (function(t, ks)
    local kset = F_from_set(F_const(true), ks)
    local function p(k, _) return not kset[k] end
    return F_filterk(p, t)
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
    return setmetatable(ys, mt), setmetatable(zs, mt)
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
    return setmetatable(t1, mt), setmetatable(t2, mt)
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
    return setmetatable(t1, mt), setmetatable(t2, mt)
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
    return setmetatable(indices, mt)
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
    return setmetatable(indices, mt)
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

F_null = register1 "null" (function(t)
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

F_length = register1 "length" (function(xs)
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

F_map = register2 "map" (function(f, xs)
    local ys = {}
    for i = 1, #xs do ys[i] = f(xs[i]) end
    return setmetatable(ys, mt)
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
    return setmetatable(ys, mt)
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
    return setmetatable(t2, mt)
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
    return setmetatable(t2, mt)
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
    return setmetatable(ys, mt)
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
    local M = max(t_unpack(F_map(F_length, xss)))
    local yss = {}
    for j = 1, M do
        local ys = {}
        for i = 1, N do ys[i] = xss[i][j] end
        yss[j] = setmetatable(ys, mt)
    end
    return setmetatable(yss, mt)
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

F_foreach = register1 "foreach" (function(xs, f)
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
    for _, v in F_pairs(t) do f(v) end
end)

--[[@@@
```lua
F.foreachk(t, f)
t:foreachk(f)
```
> calls `f` with the keys and values of `t` (`f(k, v)` for (`k`, `v`) in `t` such that `v = t[k]`)
@@@]]

register1 "foreachk" (function(t, f)
    for k, v in F_pairs(t) do f(k, v) end
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
    for _, v in F_pairs(t) do
        z = fzx(z, v)
    end
    return z
end)

--[[@@@
```lua
F.foldk(f, x, t)
t:foldk(f, x)
```
> Left-associative fold of a table (in the order given by F.pairs).
@@@]]

register3 "foldk" (function(fzx, z, t)
    for k, v in F_pairs(t) do
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
    comp_lt = comp_lt or F_op_lt
    local xmax = xs[1]
    for i = 2, #xs do
        if not comp_lt(xs[i], xmax) then xmax = xs[i] end
    end
    return xmax
end)

--[[@@@
```lua
F.minimum(xs, [comp_lt])
xs:minimum([comp_lt])
```
> The least element of a non-empty structure, according to the optional comparison function.
@@@]]

F_minimum = register1 "minimum" (function(xs, comp_lt)
    if #xs == 0 then return nil end
    comp_lt = comp_lt or F_op_lt
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
    return setmetatable(zs, mt)
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
    return setmetatable(zs, mt)
end)

--[[@@@
```lua
F.concat_map(f, xs)
xs:concat_map(f)
```
> Map a function over all the elements of a container and concatenate the resulting lists.
@@@]]

register2 "concat_map" (function(fx, xs)
    return F_concat(F_map(fx, xs))
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

F_zip = register1 "zip" (function(xss, f)
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
end)

--[[@@@
```lua
F.unzip(xss)
xss:unzip()
```
> Transforms a list of n-tuples into n lists
@@@]]

register1 "unzip" (function(xss)
    return t_unpack(F_zip(xss))
end)

--[[@@@
```lua
F.zip_with(f, xss)
xss:zip_with(f)
```
> `zip_with` generalises `zip` by zipping with the function given as the first argument, instead of a tupling function.
@@@]]

register2 "zip_with" (function(f, xss) return F_zip(xss, f) end)

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
end)

--[[@@@
```lua
F.delete(x, xs, [comp_eq])
xs:delete(x, [comp_eq])
```
> Removes the first occurrence of x from its list argument, according to the optional comp_eq function.
@@@]]

register2 "delete" (function(x, xs, comp_eq)
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
end)

--[[@@@
```lua
F.difference(xs, ys, [comp_eq])
xs:difference(ys, [comp_eq])
```
> Returns the list difference. In `difference(xs, ys)`{.lua} the first occurrence of each element of ys in turn (if any) has been removed from xs, according to the optional comp_eq function.
@@@]]

register1 "difference" (function(xs, ys, comp_eq)
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
end)

--[[@@@
```lua
F.union(xs, ys, [comp_eq])
xs:union(ys, [comp_eq])
```
> Returns the list union of the two lists. Duplicates, and elements of the first list, are removed from the the second list, but if the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

register1 "union" (function(xs, ys, comp_eq)
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
end)

--[[@@@
```lua
F.intersection(xs, ys, [comp_eq])
xs:intersection(ys, [comp_eq])
```
> Returns the list intersection of two lists. If the first list contains duplicates, so will the result, according to the optional comp_eq function.
@@@]]

register1 "intersection" (function(xs, ys, comp_eq)
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

F_merge = register1 "merge" (function(ts)
    local u = {}
    for i = 1, #ts do
        for k, v in pairs(ts[i]) do u[k] = v end
    end
    return setmetatable(u, mt)
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
    return setmetatable(u, mt)
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
    return setmetatable(u, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
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
    return setmetatable(t, mt)
end)

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
    return setmetatable(t, mt)
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
    t_sort(ys, comp_lt)
    return setmetatable(ys, mt)
end)

--[[@@@
```lua
F.sort_on(f, xs, [comp_lt])
xs:sort_on(f, [comp_lt])
```
> Sorts a list by comparing the results of a key function applied to each element, according to the optional comp_lt function.
@@@]]

register2 "sort_on" (function(f, xs, comp_lt)
    comp_lt = comp_lt or F_op_lt
    local ys = {}
    for i = 1, #xs do ys[i] = {f(xs[i]), xs[i]} end
    t_sort(ys, function(a, b) return comp_lt(a[1], b[1]) end)
    local zs = {}
    for i = 1, #ys do zs[i] = ys[i][2] end
    return setmetatable(zs, mt)
end)

--[[@@@
```lua
F.insert(x, xs, [comp_lt])
xs:insert(x, [comp_lt])
```
> Inserts the element into the list at the first position where it is less than or equal to the next element, according to the optional comp_lt function.
@@@]]

register2 "insert" (function(x, xs, comp_lt)
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

local function F_subsequences(xs)
    if F_null(xs) then return setmetatable({{}}, mt) end
    local inits = F_subsequences(F_init(xs))
    local last = F_last(xs)
    return inits .. F_map(function(seq) return F_concat{seq, {last}} end, inits)
end

register1 "subsequences" (F_subsequences)

--[[@@@
```lua
F.permutations(xs)
xs:permutations()
```
> Returns the list of all permutations of the argument.
@@@]]

F_permutations = register1 "permutations" (function(xs)
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

register1 "unlines" (function(xs)
    local s = {}
    for i = 1, #xs do
        s[#s+1] = xs[i]
        s[#s+1] = "\n"
    end
    return t_concat(s)
end)

--[[@@@
```lua
string.unwords(xs)
xs:unwords()
```
> Joins words with separating spaces.
@@@]]

register1 "unwords" (function(xs)
    return t_concat(xs, " ")
end)

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
string.ljust(s, w)
s:ljust(w)
```
> Left-justify `s` by appending spaces. The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.ljust(s, w)
    return s .. s_rep(" ", w-#s)
end

--[[@@@
```lua
string.rjust(s, w)
s:rjust(w)
```
> Right-justify `s` by prepending spaces. The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.rjust(s, w)
    return s_rep(" ", w-#s) .. s
end

--[[@@@
```lua
string.center(s, w)
s:center(w)
```
> Center `s` by appending and prepending spaces. The result is at least `w` byte long. `s` is not truncated.
@@@]]

function string.center(s, w)
    local l = (w-#s)//2
    local r = (w-#s)-l
    return s_rep(" ", l) .. s .. s_rep(" ", r)
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
    return t_concat(F_map(s_lower, split_identifier(...)), "_")
end

function string.upper_snake_case(...)
    return t_concat(F_map(s_upper, split_identifier(...)), "_")
end

function string.lower_camel_case(...)
    return s_gsub(t_concat(F_map(s_cap, split_identifier(...))), "^%w", s_lower)
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
        pattern = s_gsub(pattern, "^(.+)(.)(.)$", "%1(%%b%2%3)"),
        env = self.env,
    }, interpolator_mt)
end

function interpolator_mt.__call(self, s)
    if type(s) == "string" then
        return (s_gsub(s, self.pattern, function(x)
            local y = ((assert(load("return "..s_sub(x, 2,-2), nil, "t", self.env)))())
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

local reg = debug.getregistry()
reg.luax_F_mt = mt

return setmetatable(F, {
    __call = function(_, t)
        if type(t) == "table" then return setmetatable(t, mt) end
        return t
    end,
})
