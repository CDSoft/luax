# qmath: rational number library

``` lua
local qmath = require "qmath"
```

`qmath` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lqmath).

`qmath` is a rational number library for Lua based on
[imath](https://github.com/creachadair/imath).

## Standard qmath library

    __add(x,y)          abs(x)              neg(x)
    __div(x,y)          add(x,y)            new(x,[d])
    __eq(x,y)           compare(x,y)        numer(x)
    __le(x,y)           denom(x)            pow(x,y)
    __lt(x,y)           div(x,y)            sign(x)
    __mul(x,y)          int(x)              sub(x,y)
    __pow(x,y)          inv(x)              todecimal(x,[n])
    __sub(x,y)          isinteger(x)        tonumber(x)
    __tostring(x)       iszero(x)           tostring(x)
    __unm(x)            mul(x,y)            version

## qmath additional functions

``` lua
q = qmath.torat(x, [eps])
```

approximates a floating point number `x` with a rational value. The
rational number `q` is an approximation of `x` such that
$|q - x| < eps$. The default `eps` value is $10^{-6}$.
