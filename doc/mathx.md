# mathx: complete math library for Lua

``` lua
local mathx = require "mathx"
```

`mathx` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lmathx).

This is a complete math library for Lua 5.3 with the functions available
in C99. It can replace the standard Lua math library, except that mathx
deals exclusively with floats.

There is no manual: see the summary below and a C99 reference manual,
e.g. <http://en.wikipedia.org/wiki/C_mathematical_functions>

mathx library:

    acos        cosh        fmax        lgamma      remainder
    acosh       deg         fmin        log         round
    asin        erf         fmod        log10       scalbn
    asinh       erfc        frexp       log1p       sin
    atan        exp         gamma       log2        sinh
    atan2       exp2        hypot       logb        sqrt
    atanh       expm1       isfinite    modf        tan
    cbrt        fabs        isinf       nearbyint   tanh
    ceil        fdim        isnan       nextafter   trunc
    copysign    floor       isnormal    pow         version
    cos         fma         ldexp       rad

# math

The standard Lua package `math` is enhanced with the `mathx` functions.
