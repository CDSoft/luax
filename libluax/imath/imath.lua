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
https://codeberg.org/cdsoft/luax
--]]

--@LIB

-- Pure Lua implementation of imath.c

local imath = {}
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

return imath
