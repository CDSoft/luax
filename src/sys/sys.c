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

#include "sys.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const luaL_Reg blsyslib[] =
{
    {NULL, NULL}
};

LUAMOD_API int luaopen_sys (lua_State *L)
{
    luaL_newlib(L, blsyslib);
#define STRING(NAME, VAL) lua_pushliteral(L, VAL); lua_setfield(L, -2, NAME)
    STRING("arch", LUAX_ARCH);
    STRING("os", LUAX_OS);
    STRING("abi", LUAX_ABI);
#undef STRING
    return 1;
}
