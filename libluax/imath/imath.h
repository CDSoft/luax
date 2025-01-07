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
# imath: arbitrary precision integer and rational arithmetic library

```lua
local imath = require "imath"
```

`imath` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#limath).

`imath` is an [arbitrary-precision](http://en.wikipedia.org/wiki/Bignum)
integer library for Lua based on [imath](https://github.com/creachadair/imath).

imath library:

    __add(x,y)          add(x,y)            pow(x,y)
    __div(x,y)          bits(x)             powmod(x,y,m)
    __eq(x,y)           compare(x,y)        quotrem(x,y)
    __idiv(x,y)         div(x,y)            root(x,n)
    __le(x,y)           egcd(x,y)           shift(x,n)
    __lt(x,y)           gcd(x,y)            sqr(x)
    __mod(x,y)          invmod(x,m)         sqrt(x)
    __mul(x,y)          iseven(x)           sub(x,y)
    __pow(x,y)          isodd(x)            text(t)
    __shl(x,n)          iszero(x)           tonumber(x)
    __shr(x,n)          lcm(x,y)            tostring(x,[base])
    __sub(x,y)          mod(x,y)            totext(x)
    __tostring(x)       mul(x,y)            version
    __unm(x)            neg(x)
    abs(x)              new(x,[base])
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_imath(lua_State *L);
