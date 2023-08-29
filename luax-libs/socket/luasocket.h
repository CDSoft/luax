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
# luasocket: Network support for the Lua language

```lua
local socket = require "socket"
```

The socket package is based on
[Lua Socket](http://w3.impa.br/~diego/software/luasocket/) and adapted for `luax`.

The documentation of `Lua Socket` is available at the [Lua Socket documentation
web site](http://w3.impa.br/~diego/software/luasocket/reference.html).
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_luasocket(lua_State *L);
