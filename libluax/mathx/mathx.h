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
 * https://codeberg.org/cdsoft/luax
 */

#pragma once

/***************************************************************************@@@
# mathx: complete math library for Lua

```lua
local mathx = require "mathx"
```

`mathx` is taken from [Libraries and tools for
Lua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#lmathx).

This is a complete math library for Lua 5.3 with the functions available in
C99. It can replace the standard Lua math library, except that mathx deals
exclusively with floats.

There is no manual: see the summary below and a C99 reference manual, e.g.
<http://en.wikipedia.org/wiki/C_mathematical_functions>

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
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_mathx(lua_State *L);
