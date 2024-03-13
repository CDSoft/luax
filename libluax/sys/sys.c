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

/***************************************************************************@@@
# sys: System module

```lua
local sys = require "sys"
```
@@@*/

#include "sys.h"

#include "lua.h"
#include "lauxlib.h"

static const luaL_Reg luax_syslib[] =
{
    {NULL, NULL}
};

static inline void set_string(lua_State *L, const char *name, const char *val)
{
    lua_pushstring(L, val);
    lua_setfield(L, -2, name);
}

/*@@@
```lua
sys.os
```
`"linux"`, `"macos"` or `"windows"`.

```lua
sys.arch
```
`"x86_64"` or `"aarch64"`.

```lua
sys.libc
```
`"musl"` or `"gnu"`. Note that `libc` is `"lua"` when using the pure Lua implementation of LuaX.

```lua
sys.exe
```
Extension of executable files on the platform.

```lua
sys.so
```
Extension of shared libraries on the platform (`".so"`, `".dylib"` or `".dll"`).

```lua
sys.name
```
Name of the platform.
@@@*/

LUAMOD_API int luaopen_sys (lua_State *L)
{
    luaL_newlib(L, luax_syslib);
    set_string(L, "arch", LUAX_ARCH);
    set_string(L, "os",   LUAX_OS);
    set_string(L, "libc", LUAX_LIBC);
    set_string(L, "exe",  LUAX_EXE);
    set_string(L, "so",   LUAX_SO);
    set_string(L, "name", LUAX_NAME);
    return 1;
}
