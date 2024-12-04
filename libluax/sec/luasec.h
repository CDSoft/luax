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
# luasec: add secure connections to any Lua applications or scripts

```lua
local ssl = require "ssl"
```

The LuaSec package is based on
[LuaSec](https://github.com/lunarmodules/luasec) and adapted for `luax`.
[OpenSSL](https://www.openssl.org/) is statically linked to LuaX and is not required to be installed on the host.

The documentation of `LuaSec` is available at the [LuaSec
web site](https://github.com/lunarmodules/luasec/wiki).
@@@*/

#include "lua.h"

/* C module registration function */
LUAMOD_API int luaopen_luasec(lua_State *L);
