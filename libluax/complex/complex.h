/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://github.com/cdsoft/luax
 */

#pragma once

/***************************************************************************@@@
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
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_complex(lua_State *L);
