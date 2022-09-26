# complex: math library for complex numbers based on C99

```lua
local complex = require "complex"
```

`complex` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lcomplex).

`complex` is a math library for complex numbers based on C99.

complex library:

    I       __tostring(z)   asinh(z)    imag(z)     sinh(z)
    __add(z,w)  __unm(z)    atan(z)     log(z)      sqrt(z)
    __div(z,w)  abs(z)      atanh(z)    new(x,y)    tan(z)
    __eq(z,w)   acos(z)     conj(z)     pow(z,w)    tanh(z)
    __mul(z,w)  acosh(z)    cos(z)      proj(z)     tostring(z)
    __pow(z,w)  arg(z)      cosh(z)     real(z)     version
    __sub(z,w)  asin(z)     exp(z)      sin(z)
