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
 * http://cdelord.fr/luax
 */

#pragma once

/***************************************************************************@@@
# qmath: rational number library

```lua
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
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_qmath(lua_State *L);
