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
# LuaX in Lua

The script `lib/luax.lua` is a standalone Lua package that reimplements some LuaX modules.
It can be used in Lua projects without any other LuaX dependency.

These modules may have slightly different and degraded behaviours compared to the LuaX modules.
Especially `fs` and `ps` may be incomplete and less accurate
than the same functions implemented in C in LuaX.

```lua
require "luax"
```
> changes the `package` module such that `require` can load `fun`, `fs`, `sh` and `sys`.

@@@]]

--{{{ fun module
local F = {}
local fun = F
do

--[[------------------------------------------------------------------------@@@
# Functional programming utilities

```lua
local F = require "fun"
```

`fun` provides some useful functions inspired by functional programming languages,
especially by these Haskell modules:

- [`Data.List`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-List.html)
- [`Data.Map`](https://hackage.haskell.org/package/containers-0.6.6/docs/Data-Map.html)
- [`Data.String`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Data-String.html)
- [`Prelude`](https://hackage.haskell.org/package/base-4.17.0.0/docs/Prelude.html)

@@@]]

local mt = {__index={}}

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

local has_mathx, mathx = pcall(require, "mathx")

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
    { t1, v1 },
    ...
    { tn, vn }
}
```
> returns the first `vi` such that `ti == x`.
If `ti` is a function, it is applied to `x` and the test becomes `ti(x) == x`.
If `vi` is a function, the value returned by `F.case` is `vi(x)`.
@@@]]

local otherwise = {}

function F.case(val)
    return function(cases)
        for i = 1, #cases do
            local test, res = table.unpack(cases[i])
            if type(test) == "function" then test = test(val) end
            if val == test or rawequal(test, otherwise) then
                if type(res) == "function" then res = res(val) end
                return res
            end
        end
    end
end

--[[@@@
```lua
F.when {
    { t1, v1 },
    ...
    { tn, vn }
}
```
> returns the first `vi` such that `ti` is true.
If `ti` is a function, the test becomes `ti()`.
If `vi` is a function, the value returned by `F.when` is `vi()`.
@@@]]

function F.when(cases)
    for i = 1, #cases do
        local test, res = table.unpack(cases[i])
        if type(test) == "function" then test = test() end
        if test then
            if type(res) == "function" then res = res() end
            return res
        end
    end
end

--[[@@@
```lua
F.otherwise
```
> `F.otherwise` is used with `F.case` and `F.when` to add a default branch.
@@@]]
F.otherwise = otherwise

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
function F.abs(a) if a < 0 then return -a else return a end end

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
    local q, r = F.quot_rem(a, b)
    return q
end

--[[@@@
```lua
F.rem(a, b)
```
> integer remainder satisfying quot(a, b)*b + rem(a, b) == a, 0 <= rem(a, b) < abs(b)
@@@]]
function F.rem(a, b)
    local q, r = F.quot_rem(a, b)
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
    local q, r = F.div_mod(a, b)
    return q
end

--[[@@@
```lua
F.mod(a, b)
```
> integer modulus satisfying div(a, b)*b + mod(a, b) == a, 0 <= mod(a, b) < abs(b)
@@@]]
function F.mod(a, b)
    local q, r = F.div_mod(a, b)
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
if has_mathx then
    F.sinh = mathx.sinh
    F.cosh = mathx.cosh
    F.tanh = mathx.tanh
    F.asinh = mathx.asinh
    F.acosh = mathx.acosh
    F.atanh = mathx.atanh
end

--[[@@@
```lua
F.proper_fraction(x)
```
> returns a pair (n,f) such that x = n+f, and:
>
> - n is an integral number with the same sign as x
> - f is a fraction with the same type and sign as x, and with absolute value less than 1.
@@@]]
function F.proper_fraction(x)
    return math.modf(x)
end

--[[@@@
```lua
F.truncate(x)
```
> returns the integer nearest x between zero and x.
@@@]]
function F.truncate(x)
    return (math.modf(x))
end

--[[@@@
```lua
F.round(x)
```
> returns the nearest integer to x; the even integer if x is equidistant between two integers
@@@]]

F.round = has_mathx
    and mathx.round
    or function(x)
        return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
    end

--[[@@@
```lua
F.ceiling(x)
```
> returns the least integer not less than x.
@@@]]
function F.ceiling(x)
    return math.ceil(x)
end

--[[@@@
```lua
F.floor(x)
```
> returns the greatest integer not greater than x.
@@@]]
function F.floor(x)
    return math.floor(x)
end

--[[@@@
```lua
F.is_nan(x)
```
> True if the argument is an IEEE "not-a-number" (NaN) value
@@@]]

if has_mathx then
    F.is_nan = mathx.isnan
end

--[[@@@
```lua
F.is_infinite(x)
```
> True if the argument is an IEEE infinity or negative infinity
@@@]]

if has_mathx then
    F.is_infinite = mathx.isinf
end

--[[@@@
```lua
F.is_normalized(x)
```
> True if the argument is represented in normalized format
@@@]]

if has_mathx then
    function F.is_normalized(x)
        return mathx.isnormal(x)
    end
end

--[[@@@
```lua
F.is_denormalized(x)
```
> True if the argument is too small to be represented in normalized format
@@@]]

if has_mathx then
    function F.is_denormalized(x)
        return not mathx.isnormal(x)
    end
end

--[[@@@
```lua
F.is_negative_zero(x)
```
> True if the argument is an IEEE negative zero
@@@]]

if has_mathx then
    function F.is_negative_zero(x)
        return mathx.copysign(1, x) < 0
    end
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
    return function(...)
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
@@@]]

function F.memo1(f)
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

function F.show(x, opt)

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
                        if type(k) == "string" and k:match "^[%w_]+$" then
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
    assert(step ~= 0, "range step can not be zero")
    if not b then a, b = 1, a end
    step = step or (a < b and 1) or (a > b and -1)
    local r = {}
    if a < b then
        assert(step > 0, "step shall be positive")
        while a <= b do
            table.insert(r, a)
            a = a + step
        end
    elseif a > b then
        assert(step < 0, "step shall be negative")
        while a >= b do
            table.insert(r, a)
            a = a + step
        end
    else
        table.insert(r, a)
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
F.flatten(xs)
xs:flatten()
```
> Returns a flat list with all elements recursively taken from xs
@@@]]

register1 "flatten" (function(xs)
    local ys = {}
    local function f(xs)
        for i = 1, #xs do
            local x = xs[i]
            if type(x) == "table" then
                f(x)
            else
                ys[#ys+1] = x
            end
        end
    end
    f(xs)
    return setmt(ys)
end)

--[[@@@
```lua
F.str({s1, s2, ... sn}, [separator])
ss:str([separator])
```
> concatenates strings (separated with an optional separator) and returns a string.
@@@]]

register1 "str" (table.concat)

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
        kvs[i] = {k, t[k]} end
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
            yss[#yss+1] = ys
            y = x
            ys = {y}
        end
    end
    yss[#yss+1] = ys
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
        yss[#yss+1] = ys
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
        yss[#yss+1] = ys
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
F.restrictKeys(t, ks)
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
F.elemIndex(x, xs)
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
> maps `f` to the elements of `xs` and returns `{f(1, xs[1]), f(2, xs[2]), ...}`
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
> maps `f` to the values of `t` and returns `{k1=f(k1, t[k1]), k2=f(k2, t[k2]), ...}`
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
        yss[j] = ys
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
    for _, kv in F(t):items():ipairs() do
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
    __call = F.const(nil),
    __tostring = F.const "Nil",
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
    local cs = {}
    i = i or 1
    j = j or #s
    for k = i, j do cs[k-i+1] = s:sub(k, k) end
    return F(cs)
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
string.dropWhile(s, p)
s:dropWhile(p)
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
## String interpolation
@@@]]

--[[@@@
```lua
string.I(s, t)
s:I(t)
```
> interpolates expressions in the string `s` by replacing `$(...)` with
  the value of `...` in the environment defined by the table `t`.
@@@]]

function string.I(s, t)
    return (s:gsub("%$(%b())", function(x)
        local y = ((assert(load("return "..x, nil, "t", t)))())
        if type(y) == "table" or type(y) == "userdata" then
            y = tostring(y)
        end
        return y
    end))
end

--[[@@@
```lua
F.I(t)
```
> returns a string interpolator that replaces `$(...)` with
  the value of `...` in the environment defined by the table `t`.
  An interpolator can be given another table
  to build a new interpolator with new values.
@@@]]

local function Interpolator(t)
    return function(x)
        if type(x) == "table" then return Interpolator(F.merge{t, x}) end
        if type(x) == "string" then return string.I(x, t) end
        error("An interpolator expects a table or a string")
    end
end

function F.I(t)
    return Interpolator(F.clone(t))
end

-------------------------------------------------------------------------------
-- module
-------------------------------------------------------------------------------

fun = setmetatable(F, {
    __call = function(_, t)
        if type(t) == "table" then return setmt(t) end
        return t
    end,
})
end
--}}}

--{{{ sh module

--[[------------------------------------------------------------------------@@@
# Shell
@@@]]

--[[@@@
```lua
local sh = require "sh"
```
@@@]]
local sh = {}

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
    local p = assert(io.popen(cmd, "r"))
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
When `sh.read` succeeds, it returns the content of stdout.
Otherwise it returns the error identified by `io.popen`.
@@@]]

function sh.write(...)
    local cmd = F.flatten{...}:unwords()
    return function(data)
        local p = assert(io.popen(cmd, "w"))
        p:write(data)
        return p:close()
    end
end

--}}}

--{{{ fs module

--[[------------------------------------------------------------------------@@@
# File System

`fs` is a File System module. It provides functions to handle files and directory in a portable way.

```lua
local fs = require "fs"
```
@@@]]

local fs = {}

fs.sep = package.config:match("^([^\n]-)\n")
local pathsep = fs.sep == '\\' and ";" or ":"

--[[@@@
```lua
fs.getcwd()
```
returns the current working directory.
@@@]]

if pandoc then
fs.getcwd = pandoc.system.get_working_directory
else
function fs.getcwd()
    return sh.read "pwd" : trim()
end
end

function fs.chdir()
    error("fs.chdir is not implemented in luax.lua")
end

--[[@@@
```lua
fs.dir([path])
```
returns the list of files and directories in
`path` (the default path is the current directory).
@@@]]

if pandoc then
fs.dir = F.compose{F, pandoc.system.list_directory}
else
function fs.dir(path)
    return sh.read("ls", path) : lines() : sort()
end
end

--[[@@@
```lua
fs.remove(name)
```
deletes the file `name`.
@@@]]

function fs.remove(name)
    return os.remove(name)
end

--[[@@@
```lua
fs.rename(old_name, new_name)
```
renames the file `old_name` to `new_name`.
@@@]]

function fs.rename(old_name, new_name)
    return os.rename(old_name, new_name)
end

--[[@@@
```lua
fs.copy(source_name, target_name)
```
copies file `source_name` to `target_name`.
The attributes and times are preserved.
@@@]]

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

--[[@@@
```lua
fs.mkdir(path)
```
creates a new directory `path`.
@@@]]

if pandoc then
fs.mkdir = pandoc.system.make_directory
else
function fs.mkdir(path)
    return sh.run("mkdir", path)
end
end

--[[@@@
```lua
fs.stat(name)
```
reads attributes of the file `name`. Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions
@@@]]

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

function fs.stat(name)
    local st = sh.read("LANG=C", "stat", "-L", "-c '%s;%Y;%X;%W;%F;%f'", name, "2>/dev/null")
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

--[[@@@
```lua
fs.inode(name)
```
reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers
@@@]]

function fs.inode(name)
    local st = sh.read("LANG=C", "stat", "-L", "-c '%d;%i'", name, "2>/dev/null")
    if not st then return nil, "cannot stat "..name end
    local dev, ino = st:trim():split ";":unpack()
    return F{
        ino = tonumber(ino),
        dev = tonumber(dev),
    }
end

--[[@@@
```lua
fs.chmod(name, other_file_name)
```
sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

```lua
fs.chmod(name, bit1, ..., bitn)
```
sets file `name` permissions as
`bit1` or ... or `bitn` (integers).
@@@]]

function fs.chmod(name, ...)
    local mode = {...}
    if type(mode[1]) == "string" then
        return sh.run("chmod", "--reference="..mode[1], name, "2>/dev/null")
    else
        return sh.run("chmod", ("%o"):format(F(mode):fold(F.op.bor, 0)), name)
    end
end

--[[@@@
```lua
fs.touch(name)
```
sets the access time and the modification time of
file `name` with the current time.

```lua
fs.touch(name, number)
```
sets the access time and the modification
time of file `name` with `number`.

```lua
fs.touch(name, other_name)
```
sets the access time and the
modification time of file `name` with the times of file `other_name`.
@@@]]

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

--[[@@@
```lua
fs.basename(path)
```
return the last component of path.
@@@]]

if pandoc then
fs.basename = pandoc.path.filename
else
function fs.basename(path)
    return sh.read("basename", path) : trim()
end
end

--[[@@@
```lua
fs.dirname(path)
```
return all but the last component of path.
@@@]]

if pandoc then
fs.dirname = pandoc.path.directory
else
function fs.dirname(path)
    return sh.read("dirname", path) : trim()
end
end

--[[@@@
```lua
fs.splitext(path)
```
return the name without the extension and the extension.
@@@]]

if pandoc then
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

--[[@@@
```lua
fs.realpath(path)
```
return the resolved path name of path.
@@@]]

if pandoc then
fs.realpath = pandoc.path.normalize
else
function fs.realpath(path)
    return sh.read("realpath", path) : trim()
end
end

--[[@@@
```lua
fs.absname(path)
```
return the absolute path name of path.
@@@]]

function fs.absname(path)
    if path:match "^[/\\]" or path:match "^.:" then return path end
    return fs.getcwd()..fs.sep..path
end

--[[@@@
```lua
fs.join(...)
```
return a path name made of several path components
(separated by `fs.sep`).
If a component is absolute, the previous components are removed.
@@@]]

if pandoc then
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
        :split(pathsep)
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

if pandoc then
function fs.mkdirs(path)
    return pandoc.system.make_directory(path, true)
end
else
function fs.mkdirs(path)
    return sh.run("mkdir", "-p", path)
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

if pandoc then
function fs.rmdir(path)
    pandoc.system.remove_directory(path, true)
    return true
end
else
function fs.rmdir(path)
    fs.walk(path, {reverse=true}):map(fs.rm)
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

- `reverse`: the list is built in a reverse order
  (suitable for recursive directory removal)
- `links`: follow symbolic links
- `cross`: walk across several devices
- `func`: function applied to the current file or directory.
  `func` takes two parameters (path of the file or directory and the stat object returned by `fs.stat`)
  and returns a boolean (to continue or not walking recursively through the subdirectories)
  and a value (e.g. the name of the file) to be added to the listed returned by `walk`.
@@@]]

function fs.walk(path, options)
    options = options or {}
    local reverse = options.reverse
    local follow_links = options.links
    local cross_device = options.cross
    local func = options.func or function(name, _) return true, name end
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
                        if stat.type == "directory" or (follow_links and stat.type == "link") then
                            local continue, new_name = func(name, stat)
                            if continue then
                                dirs[#dirs+1] = name
                            end
                            if new_name then
                                if reverse then acc_dirs = {new_name, acc_dirs}
                                else acc_dirs[#acc_dirs+1] = new_name
                                end
                            end
                        else
                            local _, new_name = func(name, stat)
                            if new_name then
                                acc_files[#acc_files+1] = new_name
                            end
                        end
                    end
                end
            end
        end
    end
    return F.flatten(reverse and {acc_files, acc_dirs} or {acc_dirs, acc_files})
end

--[[@@@
```lua
fs.with_tmpfile(f)
```
calls `f(tmp)` where `tmp` is the name of a temporary file.
@@@]]

function fs.with_tmpfile(f)
    local tmp = os.tmpname()
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
    local tmp = os.tmpname()
    fs.rm(tmp)
    fs.mkdir(tmp)
    local ret = {f(tmp)}
    fs.rmdir(tmp)
    return table.unpack(ret)
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

--}}}

--{{{ sys module

--[[------------------------------------------------------------------------@@@
# sys: System module

```lua
local sys = require "sys"
```
@@@]]

local sys = {}

--[[@@@
```lua
sys.os
```
`"linux"`, `"macos"` or `"windows"`.

```lua
sys.arch
```
`"x86_64"`, `"i386"` or `"aarch64"`.

```lua
sys.abi
```
`"lua"`.

```lua
sys.type
```
`"lua"`
@@@]]

sys.abi = "lua"
sys.type = "lua"

setmetatable(sys, {
    __index = function(_, param)
        if param == "os" then
            local os = sh.read("uname"):trim():lower()
            sys.os = os
            return os
        elseif param == "arch" then
            local arch = sh.read("uname", "-m"):trim()
            sys.arch = arch
            return arch
        end
    end,
})

--}}}

--{{{ ps module

--[[------------------------------------------------------------------------@@@
# ps: Process management module

```lua
local ps = require "ps"
```
@@@]]

local ps = {}

--[[@@@
```lua
ps.sleep(n)
```
sleeps for `n` seconds.
@@@]]

function ps.sleep(n)
    return sh.run("sleep", n)
end

--[[@@@
```lua
ps.time()
```
returns the current time in seconds
@@@]]

function ps.time()
    return os.time()
end

--[[@@@
```lua
ps.profile(func)
```
executes `func` and returns its execution time in seconds.
@@@]]

function ps.profile(func)
    local t0 = os.time()
    func()
    local t1 = os.time()
    return t1 - t0
end

--}}}

--{{{ crypt module

local crypt = {}

--[[------------------------------------------------------------------------@@@
# crypt: cryptography module

```lua
local crypt = require "crypt"
```

`crypt` provides (weak but simple) cryptography functions.

> **Warning**: for serious cryptography applications, please do not use this module.

@@@]]

--[[------------------------------------------------------------------------@@@
## Random number generator

The LuaX pseudorandom number generator is a
[linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).
This generator is not a cryptographically secure pseudorandom number generator.
It can be used as a repeatable generator (e.g. for repeatable tests).

@@@]]

--[[@@@
``` lua
local rng = crypt.prng(seed)
```
returns a random number generator starting from the optional seed `seed`.
@@@]]

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

function crypt.prng(seed)
    seed = seed or random(RAND_MAX)
    return setmetatable({seed=seed}, prng_mt)
end

--[[@@@
``` lua
rng:int()
```
returns a random integral number between `0` and `crypt.RAND_MAX`.

``` lua
rng:int(a)
```
returns a random integral number between `0` and `a`.

``` lua
rng:int(a, b)
```
returns a random integral number between `a` and `b`.
@@@]]

function prng_mt.__index:int(a, b)
    self.seed = 6364136223846793005*self.seed + 1
    local r = self.seed >> 32
    if not a then return r end
    if not b then return r % (a+1) end
    return r % (b-a+1) + a
end

--[[@@@
``` lua
rng:float()
```
returns a random floating point number between `0` and `1`.

``` lua
rng:float(a)
```
returns a random floating point number between `0` and `a`.

``` lua
rng:float(a, b)
```
returns a random floating point number between `a` and `b`.
@@@]]

function prng_mt.__index:float(a, b)
    local r = self:int()
    if not a then return r / RAND_MAX end
    if not b then return r * a/RAND_MAX end
    return r * (b-a)/RAND_MAX + a
end


--[[@@@
```lua
rng:str(n)
```
returns a string with `n` random bytes.
@@@]]

function prng_mt.__index:str(n)
    local bs = {}
    for i = 1, n do
        bs[i] = char(self:int(0, 255))
    end
    return concat(bs)
end

--[[------------------------------------------------------------------------@@@
## Hexadecimal encoding

The hexadecimal encoder transforms a string into a string
where bytes are coded with hexadecimal digits.
@@@]]

--[[@@@
```lua
crypt.hex(data)
data:hex()
```
encodes `data` in hexa.
@@@]]

function crypt.hex(s)
    return (gsub(s, '.', function(c) return format("%02X", byte(c)) end))
end

string.hex = crypt.hex

--[[@@@
```lua
crypt.unhex(data)
data:unhex()
```
decodes the hexa `data`.
@@@]]

function crypt.unhex(s)
    return (gsub(s, '..', function(h) return char(tonumber(h, 16)) end))
end

string.unhex = crypt.unhex

--[[------------------------------------------------------------------------@@@
## Base64 encoding

The base64 encoder transforms a string with non printable characters
into a printable string (see <https://en.wikipedia.org/wiki/Base64>).

The implementation has been taken from
<https://lua-users.org/wiki/BaseSixtyFour>.
@@@]]

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

--[[@@@
```lua
crypt.base64(data)
data:base64()
```
encodes `data` in base64.
@@@]]

function crypt.base64(s)
    return ((s:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#s%3+1])
end

string.base64 = crypt.base64

--[[@@@
```lua
crypt.unbase64(data)
data:unbase64()
```
decodes the base64 `data`.
@@@]]

function crypt.unbase64(s)
    s = string.gsub(s, '[^'..b..'=]', '')
    return (s:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

string.unbase64 = crypt.unbase64

--[[------------------------------------------------------------------------@@@
## CRC32 hash

The CRC-32 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-32` algorithm.
@@@]]

--[[@@@
```lua
crypt.crc32(data)
data:crc32()
```
computes the CRC32 of `data`.
@@@]]

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

string.crc32 = crypt.crc32

--[[------------------------------------------------------------------------@@@
## CRC64 hash

The CRC-64 algorithm has been generated by [pycrc](https://pycrc.org/)
with the `crc-64-xz` algorithm.
@@@]]

--[[@@@
```lua
crypt.crc64(data)
data:crc64()
```
computes the CRC64 of `data`.
@@@]]

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

string.crc64 = crypt.crc64

--[[------------------------------------------------------------------------@@@
## SHA1 hash

The SHA1 hash is provided by the `pandoc` module.
`crypt.sha1` is just an alias for `pandoc.utils.sha1`.
@@@]]

--[[@@@
```lua
crypt.sha1(data)
data:sha1()
```
computes the SHA1 of `data`.
@@@]]


if pandoc then

    crypt.sha1 = pandoc.utils.sha1

    string.sha1 = crypt.sha1

end

--[[------------------------------------------------------------------------@@@
## RC4 encryption

RC4 is a stream cipher (see <https://en.wikipedia.org/wiki/RC4>).
It is design to be fast and simple.

See <https://en.wikipedia.org/wiki/RC4>.
@@@]]

--[[@@@
```lua
crypt.rc4(data, key, [drop])
data:rc4(key, [drop])
crypt.unrc4(data, key, [drop])      -- note that unrc4 == rc4
data:unrc4(key, [drop])
```
encrypts/decrypts `data` using the RC4Drop
algorithm and the encryption key `key` (drops the first `drop` encryption
steps, the default value of `drop` is 768).
@@@]]

function crypt.rc4(input, key, drop)
    drop = drop or 768
    local S = {}
    for i = 0, 255 do S[i] = i end
    local j = 0
    for i = 0, 255 do
        j = (j + S[i] + byte(key, i%#key+1)) % 256
        S[i], S[j] = S[j], S[i]
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

string.rc4 = crypt.rc4
string.unrc4 = crypt.unrc4

--}}}

--{{{ fake linenoise module

local linenoise = {}

function linenoise.read(prompt)
    io.stdout:write(prompt)
    io.stdout:flush()
    return io.stdin:read "l"
end

linenoise.read_mask = linenoise.read

linenoise.add = F.const()
linenoise.set_len = F.const()
linenoise.save = F.const()
linenoise.load = F.const()
linenoise.multi_line = F.const()
linenoise.mask = F.const()

function linenoise.clear()
    io.stdout:write "\x1b[1;1H\x1b[2J"
end

--}}}

--{{{ luax module
local libs = {
    luax = function() end,
    fun = function() return fun end,
    sh = function() return sh end,
    fs = function() return fs end,
    ps = function() return ps end,
    sys = function() return sys end,
    crypt = function() return crypt end,
    linenoise = function() return linenoise end,
}

table.insert(package.searchers, 1, function(name) return libs[name] end)
--}}}

-- vim: set ts=4 sw=4 foldmethod=marker :
